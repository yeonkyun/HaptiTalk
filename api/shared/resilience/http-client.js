/**
 * 회복성이 강화된 HTTP 클라이언트
 * 
 * Circuit Breaker, Retry, Timeout, Bulkhead 패턴이 통합된 HTTP 클라이언트
 */

const axios = require('axios');
const CircuitBreaker = require('./circuit-breaker');
const Retry = require('./retry');
const Timeout = require('./timeout');
const Bulkhead = require('./bulkhead');

class HttpClient {
  /**
   * HTTP 클라이언트 생성자
   * @param {string} baseURL - 기본 URL
   * @param {Object} options - 옵션
   */
  constructor(baseURL, options = {}) {
    this.baseURL = baseURL;
    
    // Axios 클라이언트 생성
    this.client = axios.create({
      baseURL,
      timeout: options.timeout || 5000,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers
      }
    });
    
    // 로거 설정
    this.logger = options.logger || console;
    
    // 회복성 패턴 인스턴스 생성
    this.circuitBreaker = new CircuitBreaker({
      timeout: options.timeout || 5000,
      errorThresholdPercentage: options.errorThresholdPercentage || 50,
      resetTimeout: options.resetTimeout || 10000,
      name: options.name || `HttpClient(${baseURL})`,
      logger: this.logger
    });
    
    this.retry = new Retry({
      maxRetries: options.maxRetries || 3,
      initialDelay: options.initialDelay || 1000,
      maxDelay: options.maxDelay || 10000,
      exponentialBackoff: options.exponentialBackoff !== false,
      logger: this.logger
    });
    
    this.timeout = new Timeout({
      defaultTimeout: options.timeout || 5000,
      logger: this.logger
    });
    
    this.bulkhead = new Bulkhead({
      concurrentLimit: options.concurrentLimit || 10,
      queueSize: options.queueSize || 100,
      queueTimeout: options.queueTimeout || 5000,
      logger: this.logger
    });
    
    // 요청 인터셉터 설정
    this.client.interceptors.request.use(
      (config) => {
        this.logger.debug(`API 요청: ${config.method.toUpperCase()} ${config.url}`, {
          component: 'http-client'
        });
        return config;
      },
      (error) => {
        this.logger.error(`API 요청 오류: ${error.message}`, {
          error: error.message,
          component: 'http-client'
        });
        return Promise.reject(error);
      }
    );
    
    // 응답 인터셉터 설정
    this.client.interceptors.response.use(
      (response) => {
        this.logger.debug(`API 응답: ${response.status} ${response.config.url}`, {
          component: 'http-client',
          status: response.status
        });
        return response;
      },
      (error) => {
        if (error.response) {
          this.logger.error(`API 응답 오류: ${error.response.status} ${error.response.config.url}`, {
            error: error.message,
            status: error.response.status,
            component: 'http-client'
          });
        } else if (error.request) {
          this.logger.error(`API 응답 없음: ${error.request._currentUrl}`, {
            error: error.message,
            component: 'http-client'
          });
        } else {
          this.logger.error(`API 요청 설정 오류: ${error.message}`, {
            error: error.message,
            component: 'http-client'
          });
        }
        return Promise.reject(error);
      }
    );
  }

  /**
   * 회복성 패턴을 적용하여 HTTP 요청 실행
   * @param {Function} requestFn - 요청 함수
   * @param {Object} options - 회복성 패턴 옵션
   * @returns {Promise<any>} 응답 데이터
   * @private
   */
  async _executeWithResilience(requestFn, options = {}) {
    const operationName = options.name || 'HTTP Request';
    
    // Bulkhead 패턴으로 최대 동시 실행 수 제한
    return this.bulkhead.execute(async () => {
      // Retry 패턴으로 일시적인 오류 재시도
      return this.retry.execute(async () => {
        // Circuit Breaker 패턴으로 연쇄 장애 방지
        return this.circuitBreaker.execute(async () => {
          // Timeout 패턴으로 최대 대기 시간 제한
          return this.timeout.execute(async () => {
            const response = await requestFn();
            return response.data;
          }, {
            timeout: options.timeout,
            name: `${operationName}-Timeout`
          });
        }, {
          name: `${operationName}-CircuitBreaker`
        });
      }, {
        name: `${operationName}-Retry`,
        maxRetries: options.maxRetries
      });
    }, {
      name: `${operationName}-Bulkhead`,
      concurrentLimit: options.concurrentLimit
    });
  }

  /**
   * GET 요청 수행
   * @param {string} url - 요청 URL
   * @param {Object} config - Axios 설정
   * @param {Object} resilienceOptions - 회복성 패턴 옵션
   * @returns {Promise<any>} 응답 데이터
   */
  async get(url, config = {}, resilienceOptions = {}) {
    return this._executeWithResilience(
      () => this.client.get(url, config),
      { ...resilienceOptions, name: `GET:${url}` }
    );
  }

  /**
   * POST 요청 수행
   * @param {string} url - 요청 URL
   * @param {Object} data - 요청 데이터
   * @param {Object} config - Axios 설정
   * @param {Object} resilienceOptions - 회복성 패턴 옵션
   * @returns {Promise<any>} 응답 데이터
   */
  async post(url, data = {}, config = {}, resilienceOptions = {}) {
    return this._executeWithResilience(
      () => this.client.post(url, data, config),
      { ...resilienceOptions, name: `POST:${url}` }
    );
  }

  /**
   * PUT 요청 수행
   * @param {string} url - 요청 URL
   * @param {Object} data - 요청 데이터
   * @param {Object} config - Axios 설정
   * @param {Object} resilienceOptions - 회복성 패턴 옵션
   * @returns {Promise<any>} 응답 데이터
   */
  async put(url, data = {}, config = {}, resilienceOptions = {}) {
    return this._executeWithResilience(
      () => this.client.put(url, data, config),
      { ...resilienceOptions, name: `PUT:${url}` }
    );
  }

  /**
   * DELETE 요청 수행
   * @param {string} url - 요청 URL
   * @param {Object} config - Axios 설정
   * @param {Object} resilienceOptions - 회복성 패턴 옵션
   * @returns {Promise<any>} 응답 데이터
   */
  async delete(url, config = {}, resilienceOptions = {}) {
    return this._executeWithResilience(
      () => this.client.delete(url, config),
      { ...resilienceOptions, name: `DELETE:${url}` }
    );
  }

  /**
   * PATCH 요청 수행
   * @param {string} url - 요청 URL
   * @param {Object} data - 요청 데이터
   * @param {Object} config - Axios 설정
   * @param {Object} resilienceOptions - 회복성 패턴 옵션
   * @returns {Promise<any>} 응답 데이터
   */
  async patch(url, data = {}, config = {}, resilienceOptions = {}) {
    return this._executeWithResilience(
      () => this.client.patch(url, data, config),
      { ...resilienceOptions, name: `PATCH:${url}` }
    );
  }

  /**
   * Authorization 헤더 설정
   * @param {string} token - JWT 토큰
   */
  setAuthToken(token) {
    this.client.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  }

  /**
   * 회복성 패턴 상태 조회
   * @returns {Object} 회복성 패턴 상태
   */
  getResilienceStatus() {
    return {
      circuitBreaker: this.circuitBreaker.getAllStatus(),
      bulkhead: this.bulkhead.getAllStatus()
    };
  }
}

module.exports = HttpClient;
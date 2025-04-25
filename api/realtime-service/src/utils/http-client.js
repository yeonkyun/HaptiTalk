const axios = require('axios');
const CircuitBreaker = require('opossum');
const logger = require('./logger');

/**
 * HTTP 클라이언트 유틸리티
 * Circuit Breaker 패턴을 적용한 안정적인 HTTP 클라이언트
 */
class HttpClient {
  constructor(baseURL, options = {}) {
    this.client = axios.create({
      baseURL,
      timeout: options.timeout || 5000,
      headers: {
        'Content-Type': 'application/json',
        ...options.headers
      }
    });

    // Circuit Breaker 기본 설정
    this.breakerOptions = {
      timeout: options.timeout || 5000, // 요청 타임아웃
      errorThresholdPercentage: options.errorThresholdPercentage || 50, // 차단 임계치 퍼센트
      resetTimeout: options.resetTimeout || 10000, // 차단 후 재시도 시간
      rollingCountWindow: options.rollingCountWindow || 10, // 상태 측정 윈도우
      rollingCountBuckets: options.rollingCountBuckets || 2, // 측정 윈도우 내 버킷
      name: options.name || 'HttpClient' // 서킷 이름
    };

    // 요청 인터셉터 설정
    this.client.interceptors.request.use(
      (config) => {
        logger.debug(`API 요청: ${config.method.toUpperCase()} ${config.url}`);
        return config;
      },
      (error) => {
        logger.error(`API 요청 오류: ${error.message}`);
        return Promise.reject(error);
      }
    );

    // 응답 인터셉터 설정
    this.client.interceptors.response.use(
      (response) => {
        logger.debug(`API 응답: ${response.status} ${response.config.url}`);
        return response;
      },
      (error) => {
        if (error.response) {
          logger.error(`API 응답 오류: ${error.response.status} ${error.response.config.url}`);
        } else if (error.request) {
          logger.error(`API 응답 없음: ${error.request._currentUrl}`);
        } else {
          logger.error(`API 요청 설정 오류: ${error.message}`);
        }
        return Promise.reject(error);
      }
    );
  }

  /**
   * CircuitBreaker로 래핑된 HTTP 요청 메서드
   * @param {Function} requestFn - 요청 함수
   * @param {Object} options - Circuit Breaker 옵션
   * @returns {Promise<any>} - 요청 결과
   */
  async _executeWithBreaker(requestFn, options = {}) {
    const breakerOptions = { ...this.breakerOptions, ...options };
    const breaker = new CircuitBreaker(requestFn, breakerOptions);
    
    // 이벤트 핸들러 등록
    breaker.on('open', () => {
      logger.warn(`Circuit Breaker '${breakerOptions.name}' 열림: 서비스 불안정 감지됨`);
    });
    
    breaker.on('halfOpen', () => {
      logger.info(`Circuit Breaker '${breakerOptions.name}' 절반 열림: 서비스 재시도 중`);
    });
    
    breaker.on('close', () => {
      logger.info(`Circuit Breaker '${breakerOptions.name}' 닫힘: 서비스 정상화됨`);
    });

    try {
      return await breaker.fire();
    } catch (error) {
      // 실패에 따른 대체 응답
      if (breaker.status === 'open') {
        throw new Error(`서비스 일시적 장애: ${error.message}`);
      }
      throw error;
    }
  }

  /**
   * GET 요청 수행
   * @param {string} url - 요청 URL
   * @param {Object} config - Axios 설정
   * @returns {Promise<any>} - 응답 데이터
   */
  async get(url, config = {}) {
    return this._executeWithBreaker(
      async () => {
        const response = await this.client.get(url, config);
        return response.data;
      },
      { name: `GET:${url}` }
    );
  }

  /**
   * POST 요청 수행
   * @param {string} url - 요청 URL
   * @param {Object} data - 요청 데이터
   * @param {Object} config - Axios 설정
   * @returns {Promise<any>} - 응답 데이터
   */
  async post(url, data = {}, config = {}) {
    return this._executeWithBreaker(
      async () => {
        const response = await this.client.post(url, data, config);
        return response.data;
      },
      { name: `POST:${url}` }
    );
  }

  /**
   * PUT 요청 수행
   * @param {string} url - 요청 URL
   * @param {Object} data - 요청 데이터
   * @param {Object} config - Axios 설정
   * @returns {Promise<any>} - 응답 데이터
   */
  async put(url, data = {}, config = {}) {
    return this._executeWithBreaker(
      async () => {
        const response = await this.client.put(url, data, config);
        return response.data;
      },
      { name: `PUT:${url}` }
    );
  }

  /**
   * DELETE 요청 수행
   * @param {string} url - 요청 URL
   * @param {Object} config - Axios 설정
   * @returns {Promise<any>} - 응답 데이터
   */
  async delete(url, config = {}) {
    return this._executeWithBreaker(
      async () => {
        const response = await this.client.delete(url, config);
        return response.data;
      },
      { name: `DELETE:${url}` }
    );
  }

  /**
   * Authorization 헤더 설정
   * @param {string} token - JWT 토큰
   */
  setAuthToken(token) {
    this.client.defaults.headers.common['Authorization'] = `Bearer ${token}`;
  }
}

module.exports = HttpClient; 
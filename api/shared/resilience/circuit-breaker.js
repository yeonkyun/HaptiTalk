/**
 * Circuit Breaker 패턴 구현
 * 
 * 외부 서비스 호출 실패 시 일시적으로 차단하여 연쇄 장애를 방지하는 패턴
 */

const Opossum = require('opossum');

class CircuitBreaker {
  /**
   * Circuit Breaker 생성자
   * @param {Object} options - Circuit Breaker 옵션
   * @param {number} options.timeout - 요청 타임아웃 (ms)
   * @param {number} options.errorThresholdPercentage - 차단 임계치 퍼센트
   * @param {number} options.resetTimeout - 차단 후 재시도 시간 (ms)
   * @param {number} options.rollingCountWindow - 상태 측정 윈도우
   * @param {number} options.rollingCountBuckets - 측정 윈도우 내 버킷
   * @param {string} options.name - 서킷 이름
   * @param {Function} options.fallback - 대체 함수
   * @param {Object} options.logger - 로거 인스턴스
   */
  constructor(options = {}) {
    this.options = {
      timeout: options.timeout || 5000, 
      errorThresholdPercentage: options.errorThresholdPercentage || 50, 
      resetTimeout: options.resetTimeout || 10000,
      rollingCountWindow: options.rollingCountWindow || 10,
      rollingCountBuckets: options.rollingCountBuckets || 2,
      name: options.name || 'CircuitBreaker'
    };

    this.fallback = options.fallback;
    this.logger = options.logger || console;
    this.breakers = new Map();
  }

  /**
   * 함수를 Circuit Breaker로 래핑
   * @param {Function} fn - 래핑할 함수
   * @param {Object} overrideOptions - 기본 옵션 재정의
   * @returns {Opossum} Circuit Breaker 인스턴스
   */
  wrap(fn, overrideOptions = {}) {
    const options = { ...this.options, ...overrideOptions };
    const breakerId = options.name;
    
    if (this.breakers.has(breakerId)) {
      return this.breakers.get(breakerId);
    }
    
    const breaker = new Opossum(fn, options);
    
    // 이벤트 핸들러 등록
    breaker.on('open', () => {
      this.logger.warn(`Circuit Breaker '${options.name}' 열림: 서비스 불안정 감지됨`, {
        component: 'circuit-breaker', 
        status: 'open'
      });
    });
    
    breaker.on('halfOpen', () => {
      this.logger.info(`Circuit Breaker '${options.name}' 절반 열림: 서비스 재시도 중`, {
        component: 'circuit-breaker', 
        status: 'half-open'
      });
    });
    
    breaker.on('close', () => {
      this.logger.info(`Circuit Breaker '${options.name}' 닫힘: 서비스 정상화됨`, {
        component: 'circuit-breaker', 
        status: 'closed'
      });
    });
    
    // 대체 함수 등록
    if (this.fallback) {
      breaker.fallback(this.fallback);
    }
    
    this.breakers.set(breakerId, breaker);
    return breaker;
  }

  /**
   * Circuit Breaker로 함수 실행
   * @param {Function} fn - 실행할 함수
   * @param {Object} options - 옵션
   * @returns {Promise<any>} 함수 실행 결과
   */
  async execute(fn, options = {}) {
    const breaker = this.wrap(fn, options);
    
    try {
      return await breaker.fire();
    } catch (error) {
      // 서킷이 열려있는 경우 특수 처리
      if (breaker.status === 'open') {
        this.logger.error(`서비스 불안정으로 요청 차단됨: ${options.name || this.options.name}`, {
          error: error.message,
          component: 'circuit-breaker'
        });
        
        throw new Error(`서비스 일시적 장애: ${error.message}`);
      }
      
      // 다른 오류는 그대로 전파
      throw error;
    }
  }

  /**
   * Circuit Breaker 상태 조회
   * @param {string} breakerId - 조회할 Circuit Breaker ID
   * @returns {Object} 상태 정보
   */
  getStatus(breakerId) {
    if (!this.breakers.has(breakerId)) {
      return { exists: false };
    }
    
    const breaker = this.breakers.get(breakerId);
    return {
      exists: true,
      status: breaker.status,
      stats: {
        successes: breaker.stats.successes,
        failures: breaker.stats.failures,
        rejects: breaker.stats.rejects,
        timeouts: breaker.stats.timeouts
      }
    };
  }

  /**
   * 모든 Circuit Breaker 상태 조회
   * @returns {Object} 모든 Circuit Breaker 상태
   */
  getAllStatus() {
    const result = {};
    
    for (const [id, breaker] of this.breakers.entries()) {
      result[id] = {
        status: breaker.status,
        stats: {
          successes: breaker.stats.successes,
          failures: breaker.stats.failures,
          rejects: breaker.stats.rejects,
          timeouts: breaker.stats.timeouts
        }
      };
    }
    
    return result;
  }

  /**
   * Circuit Breaker 리셋
   * @param {string} breakerId - 리셋할 Circuit Breaker ID
   */
  reset(breakerId) {
    if (this.breakers.has(breakerId)) {
      const breaker = this.breakers.get(breakerId);
      breaker.close();
      this.logger.info(`Circuit Breaker '${breakerId}' 수동 리셋됨`, {
        component: 'circuit-breaker'
      });
    }
  }

  /**
   * 모든 Circuit Breaker 리셋
   */
  resetAll() {
    for (const [id, breaker] of this.breakers.entries()) {
      breaker.close();
      this.logger.info(`Circuit Breaker '${id}' 수동 리셋됨`, {
        component: 'circuit-breaker'
      });
    }
  }
}

module.exports = CircuitBreaker;
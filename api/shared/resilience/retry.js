/**
 * 재시도(Retry) 패턴 구현
 * 
 * 일시적인 실패 시 자동으로 재시도하는 메커니즘을 제공합니다.
 */

class Retry {
  /**
   * Retry 패턴 생성자
   * @param {Object} options - 옵션
   * @param {number} options.maxRetries - 최대 재시도 횟수
   * @param {number} options.initialDelay - 첫 재시도 지연 시간 (ms)
   * @param {number} options.maxDelay - 최대 지연 시간 (ms)
   * @param {boolean} options.exponentialBackoff - 지수 백오프 사용 여부
   * @param {Function} options.shouldRetry - 재시도 조건 함수
   * @param {Object} options.logger - 로거 인스턴스
   */
  constructor(options = {}) {
    this.maxRetries = options.maxRetries || 3;
    this.initialDelay = options.initialDelay || 1000;
    this.maxDelay = options.maxDelay || 10000;
    this.exponentialBackoff = options.exponentialBackoff !== false;
    this.shouldRetry = options.shouldRetry || this.defaultShouldRetry;
    this.logger = options.logger || console;
  }

  /**
   * 기본 재시도 조건 함수
   * 네트워크 오류나 5xx 오류는 재시도, 4xx 오류는 재시도하지 않음
   * @param {Error} error - 발생한 오류
   * @returns {boolean} 재시도 여부
   */
  defaultShouldRetry(error) {
    // 네트워크 오류 (ECONNRESET, ETIMEDOUT 등)는 재시도
    if (!error.response) {
      return true;
    }
    
    // 5xx 서버 오류는 재시도
    if (error.response && error.response.status >= 500) {
      return true;
    }
    
    // 429 (Too Many Requests)는 재시도
    if (error.response && error.response.status === 429) {
      return true;
    }
    
    // 그 외 4xx 클라이언트 오류는 재시도하지 않음
    return false;
  }

  /**
   * 지연 시간 계산 (지수 백오프 적용)
   * @param {number} attempt - 현재 시도 횟수
   * @returns {number} 지연 시간 (ms)
   */
  calculateDelay(attempt) {
    if (!this.exponentialBackoff) {
      return this.initialDelay;
    }
    
    // 지수 백오프: delay = initialDelay * 2^(attempt-1) + random jitter
    const delay = this.initialDelay * Math.pow(2, attempt - 1);
    
    // 무작위 지터(jitter) 추가 (±20%)
    const jitter = delay * 0.2 * (Math.random() * 2 - 1);
    
    // 최대 지연 시간 제한
    return Math.min(delay + jitter, this.maxDelay);
  }

  /**
   * 함수 실행 (재시도 포함)
   * @param {Function} fn - 실행할 함수
   * @param {Object} options - 옵션 (생성자 옵션 재정의)
   * @returns {Promise<any>} 함수 실행 결과
   */
  async execute(fn, options = {}) {
    const maxRetries = options.maxRetries || this.maxRetries;
    const shouldRetry = options.shouldRetry || this.shouldRetry;
    const operationName = options.name || 'operation';
    
    let lastError;
    
    for (let attempt = 1; attempt <= maxRetries + 1; attempt++) {
      try {
        // 함수 실행
        return await fn();
      } catch (error) {
        lastError = error;
        
        // 마지막 시도였거나 재시도 조건에 맞지 않으면 오류 발생
        if (attempt > maxRetries || !shouldRetry(error)) {
          if (attempt > 1) {
            this.logger.error(`${operationName} 최대 재시도 횟수(${maxRetries}) 초과로 실패`, {
              error: error.message,
              component: 'retry',
              attempts: attempt
            });
          }
          throw error;
        }
        
        // 재시도 지연 시간 계산
        const delay = this.calculateDelay(attempt);
        
        this.logger.warn(`${operationName} 실패, ${attempt}번째 시도 실패, ${delay}ms 후 재시도`, {
          error: error.message,
          component: 'retry',
          attempt,
          delay
        });
        
        // 지연 후 재시도
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
    
    // 여기까지 도달하면 모든 재시도가 실패한 것이므로 마지막 오류 발생
    throw lastError;
  }
}

module.exports = Retry;
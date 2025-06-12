/**
 * 타임아웃(Timeout) 패턴 구현
 * 
 * 특정 시간이 지나면 실행을 취소하는 패턴
 */

class Timeout {
  /**
   * Timeout 패턴 생성자
   * @param {Object} options - 옵션
   * @param {number} options.defaultTimeout - 기본 타임아웃 시간 (ms)
   * @param {Object} options.logger - 로거 인스턴스
   */
  constructor(options = {}) {
    this.defaultTimeout = options.defaultTimeout || 5000;
    this.logger = options.logger || console;
  }

  /**
   * 함수 실행 (타임아웃 적용)
   * @param {Function} fn - 실행할 함수
   * @param {Object} options - 옵션 (생성자 옵션 재정의)
   * @returns {Promise<any>} 함수 실행 결과
   */
  async execute(fn, options = {}) {
    const timeout = options.timeout || this.defaultTimeout;
    const operationName = options.name || 'operation';
    
    return new Promise(async (resolve, reject) => {
      // 타임아웃 타이머 설정
      const timeoutId = setTimeout(() => {
        const error = new Error(`${operationName} 타임아웃: ${timeout}ms 초과`);
        error.isTimeout = true;
        error.operationName = operationName;
        error.timeout = timeout;
        
        this.logger.warn(`${operationName} 타임아웃 발생 (${timeout}ms)`, {
          component: 'timeout',
          timeout
        });
        
        reject(error);
      }, timeout);
      
      try {
        // 함수 실행
        const result = await fn();
        
        // 함수가 성공적으로 완료되면 타임아웃 취소
        clearTimeout(timeoutId);
        resolve(result);
      } catch (error) {
        // 함수 실행 중 오류 발생 시 타임아웃 취소 후 오류 전파
        clearTimeout(timeoutId);
        
        this.logger.error(`${operationName} 실행 중 오류 발생`, {
          error: error.message,
          component: 'timeout'
        });
        
        reject(error);
      }
    });
  }

  /**
   * 지정된 시간 내에 함수가 완료되지 않으면 기본값 반환
   * @param {Function} fn - 실행할 함수
   * @param {any} defaultValue - 타임아웃 시 반환할 기본값
   * @param {Object} options - 옵션 (생성자 옵션 재정의)
   * @returns {Promise<any>} 함수 실행 결과 또는 기본값
   */
  async executeWithFallback(fn, defaultValue, options = {}) {
    try {
      return await this.execute(fn, options);
    } catch (error) {
      if (error.isTimeout) {
        this.logger.info(`${options.name || 'operation'} 타임아웃으로 기본값 반환`, {
          component: 'timeout',
          defaultValue
        });
        return defaultValue;
      }
      
      // 타임아웃이 아닌 다른 오류는 전파
      throw error;
    }
  }
}

module.exports = Timeout;
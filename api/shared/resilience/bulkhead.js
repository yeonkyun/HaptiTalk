/**
 * Bulkhead 패턴 구현
 * 
 * 동시 실행 수를 제한하여 과부하를 방지하는 패턴
 */

class Bulkhead {
  /**
   * Bulkhead 패턴 생성자
   * @param {Object} options - 옵션
   * @param {number} options.concurrentLimit - 최대 동시 실행 수
   * @param {number} options.queueSize - 대기열 크기
   * @param {number} options.queueTimeout - 대기열 타임아웃 (ms)
   * @param {Object} options.logger - 로거 인스턴스
   */
  constructor(options = {}) {
    this.concurrentLimit = options.concurrentLimit || 10;
    this.queueSize = options.queueSize || 100;
    this.queueTimeout = options.queueTimeout || 5000;
    this.logger = options.logger || console;
    
    this.activeCount = 0;
    this.queue = [];
    this.bulkheads = new Map();
  }

  /**
   * 함수 실행 (동시 실행 제한 적용)
   * @param {Function} fn - 실행할 함수
   * @param {Object} options - 옵션 (생성자 옵션 재정의)
   * @returns {Promise<any>} 함수 실행 결과
   */
  async execute(fn, options = {}) {
    const bulkheadName = options.name || 'default';
    const concurrentLimit = options.concurrentLimit || this.concurrentLimit;
    const queueSize = options.queueSize || this.queueSize;
    const queueTimeout = options.queueTimeout || this.queueTimeout;
    
    // 각 이름별로 별도의 Bulkhead 상태 관리
    if (!this.bulkheads.has(bulkheadName)) {
      this.bulkheads.set(bulkheadName, {
        activeCount: 0,
        queue: []
      });
    }
    
    const bulkhead = this.bulkheads.get(bulkheadName);
    
    // 실행 중인 작업이 최대 동시 실행 수보다 적으면 바로 실행
    if (bulkhead.activeCount < concurrentLimit) {
      return this._executeWithBulkhead(fn, bulkheadName);
    }
    
    // 대기열이 가득 찼으면 거부
    if (bulkhead.queue.length >= queueSize) {
      this.logger.warn(`Bulkhead '${bulkheadName}' 대기열 가득참, 요청 거부됨`, {
        component: 'bulkhead',
        activeCount: bulkhead.activeCount,
        queueSize: bulkhead.queue.length
      });
      
      throw new Error(`요청이 대기열 한도(${queueSize})를 초과하여 거부되었습니다`);
    }
    
    // 대기열에 추가하고 차례를 기다림
    return new Promise((resolve, reject) => {
      const queuedFn = {
        fn,
        resolve,
        reject,
        timestamp: Date.now()
      };
      
      bulkhead.queue.push(queuedFn);
      this.logger.debug(`Bulkhead '${bulkheadName}' 대기열에 요청 추가됨`, {
        component: 'bulkhead',
        activeCount: bulkhead.activeCount,
        queueSize: bulkhead.queue.length
      });
      
      // 타임아웃 설정
      const timeoutId = setTimeout(() => {
        // 대기열에서 제거
        const index = bulkhead.queue.indexOf(queuedFn);
        if (index !== -1) {
          bulkhead.queue.splice(index, 1);
        }
        
        this.logger.warn(`Bulkhead '${bulkheadName}' 대기열 타임아웃`, {
          component: 'bulkhead',
          queueTimeout
        });
        
        reject(new Error(`요청이 ${queueTimeout}ms 동안 대기열에서 기다려 타임아웃되었습니다`));
      }, queueTimeout);
      
      // 타임아웃 취소를 위해 queuedFn에 timeoutId 추가
      queuedFn.timeoutId = timeoutId;
    });
  }

  /**
   * Bulkhead 상태 관리하며 함수 실행
   * @param {Function} fn - 실행할 함수
   * @param {string} bulkheadName - Bulkhead 이름
   * @returns {Promise<any>} 함수 실행 결과
   * @private
   */
  async _executeWithBulkhead(fn, bulkheadName) {
    const bulkhead = this.bulkheads.get(bulkheadName);
    
    // 활성 카운트 증가
    bulkhead.activeCount++;
    
    try {
      // 함수 실행
      const result = await fn();
      return result;
    } catch (error) {
      // 오류 발생 시 전파
      throw error;
    } finally {
      // 활성 카운트 감소
      bulkhead.activeCount--;
      
      // 대기열에 있는 다음 항목 처리
      this._processNextQueueItem(bulkheadName);
    }
  }

  /**
   * 대기열의 다음 항목 처리
   * @param {string} bulkheadName - Bulkhead 이름
   * @private
   */
  _processNextQueueItem(bulkheadName) {
    const bulkhead = this.bulkheads.get(bulkheadName);
    
    if (bulkhead.queue.length > 0 && bulkhead.activeCount < this.concurrentLimit) {
      const queuedFn = bulkhead.queue.shift();
      
      // 타임아웃 취소
      clearTimeout(queuedFn.timeoutId);
      
      this.logger.debug(`Bulkhead '${bulkheadName}' 대기열에서 요청 처리 시작`, {
        component: 'bulkhead',
        waitTime: Date.now() - queuedFn.timestamp,
        remainingQueue: bulkhead.queue.length
      });
      
      // 함수 실행 및 결과 처리
      this._executeWithBulkhead(queuedFn.fn, bulkheadName)
        .then(result => queuedFn.resolve(result))
        .catch(error => queuedFn.reject(error));
    }
  }

  /**
   * Bulkhead 상태 조회
   * @param {string} bulkheadName - 조회할 Bulkhead 이름
   * @returns {Object} 상태 정보
   */
  getStatus(bulkheadName = 'default') {
    if (!this.bulkheads.has(bulkheadName)) {
      return { exists: false };
    }
    
    const bulkhead = this.bulkheads.get(bulkheadName);
    return {
      exists: true,
      activeCount: bulkhead.activeCount,
      queueSize: bulkhead.queue.length,
      concurrentLimit: this.concurrentLimit
    };
  }

  /**
   * 모든 Bulkhead 상태 조회
   * @returns {Object} 모든 Bulkhead 상태
   */
  getAllStatus() {
    const result = {};
    
    for (const [name, bulkhead] of this.bulkheads.entries()) {
      result[name] = {
        activeCount: bulkhead.activeCount,
        queueSize: bulkhead.queue.length,
        concurrentLimit: this.concurrentLimit
      };
    }
    
    return result;
  }
}

module.exports = Bulkhead;
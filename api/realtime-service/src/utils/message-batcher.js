/**
 * 메시지 배치 처리 유틸리티
 * 대량의 메시지를 효율적으로 처리하기 위한 배치 처리 기능 제공
 */

const logger = require('./logger');

class MessageBatcher {
  constructor(options = {}) {
    this.batchSize = options.batchSize || 10; // 기본 배치 크기
    this.flushInterval = options.flushInterval || 100; // 배치 처리 주기 (ms)
    this.batches = new Map(); // 메시지 배치 저장소
    this.intervalId = null; // 배치 처리 타이머 ID
  }

  /**
   * 배치 처리 시작
   */
  start() {
    if (this.intervalId) {
      this.stop();
    }

    this.intervalId = setInterval(() => {
      this.flushAll();
    }, this.flushInterval);
    
    logger.debug(`메시지 배치 처리 시작: 배치 크기=${this.batchSize}, 주기=${this.flushInterval}ms`);
  }

  /**
   * 배치 처리 중지
   */
  stop() {
    if (this.intervalId) {
      clearInterval(this.intervalId);
      this.intervalId = null;
    }

    // 남은 모든 배치 처리
    this.flushAll();
    
    logger.debug('메시지 배치 처리 중지됨');
  }

  /**
   * 메시지 추가
   * @param {string} channel 메시지 채널
   * @param {any} message 메시지 데이터
   * @param {Function} processor 메시지 처리 함수
   */
  add(channel, message, processor) {
    if (!this.batches.has(channel)) {
      this.batches.set(channel, {
        messages: [],
        processor,
        lastAdded: Date.now()
      });
    }

    const batch = this.batches.get(channel);
    batch.messages.push(message);
    batch.lastAdded = Date.now();

    // 배치 크기에 도달하면 즉시 처리
    if (batch.messages.length >= this.batchSize) {
      this.flush(channel);
    }
  }

  /**
   * 특정 채널의 배치 처리
   * @param {string} channel 메시지 채널
   */
  flush(channel) {
    const batch = this.batches.get(channel);
    if (!batch || batch.messages.length === 0) {
      return;
    }

    try {
      const messagesToProcess = [...batch.messages];
      batch.messages = [];

      // 배치 처리 시간 측정
      const startTime = process.hrtime();
      
      // 메시지 처리
      batch.processor(messagesToProcess);
      
      const [seconds, nanoseconds] = process.hrtime(startTime);
      const duration = seconds * 1000 + nanoseconds / 1000000;
      
      logger.debug(`배치 처리 완료: 채널=${channel}, 메시지 수=${messagesToProcess.length}, 처리 시간=${duration.toFixed(2)}ms`);
    } catch (error) {
      logger.error(`배치 처리 오류: 채널=${channel}, 오류=${error.message}`);
    }
  }

  /**
   * 모든 채널의 배치 처리
   */
  flushAll() {
    for (const channel of this.batches.keys()) {
      this.flush(channel);
    }
  }

  /**
   * 특정 시간 이상 처리되지 않은 배치 강제 처리
   * @param {number} maxAge 최대 대기 시간 (ms)
   */
  flushStale(maxAge = 1000) {
    const now = Date.now();
    
    for (const [channel, batch] of this.batches.entries()) {
      if (batch.messages.length > 0 && now - batch.lastAdded > maxAge) {
        logger.debug(`오래된 배치 강제 처리: 채널=${channel}, 대기 시간=${now - batch.lastAdded}ms`);
        this.flush(channel);
      }
    }
  }
}

module.exports = MessageBatcher; 
/**
 * Redis Pub/Sub 처리 유틸리티
 * 메시지 구독 및 발행, 처리 실패 시 재시도 로직 제공
 */

const logger = require('./logger');
const MessageBatcher = require('./message-batcher');

class RedisPubSub {
  constructor(redisClient, io, options = {}) {
    this.redisClient = redisClient;
    this.io = io;
    this.subscriber = redisClient.duplicate();
    this.publisher = redisClient.duplicate();
    this.retryAttempts = options.retryAttempts || 3;
    this.retryDelay = options.retryDelay || 1000;
    this.handlers = new Map();
    this.failedMessages = new Map();
    
    // 메시지 배치 처리기
    this.batcher = new MessageBatcher({
      batchSize: options.batchSize || 20,
      flushInterval: options.flushInterval || 50
    });
    
    // 재시도 처리용 타이머
    this.retryInterval = null;
  }

  /**
   * 초기화 및 시작
   */
  async start() {
    try {
      // Redis 연결 확인
      await this.subscriber.ping();
      await this.publisher.ping();
      
      // 메시지 배치 처리 시작
      this.batcher.start();
      
      // 재시도 처리 타이머 시작
      this.retryInterval = setInterval(() => {
        this.processFailedMessages();
      }, 5000); // 5초마다 실패 메시지 재처리
      
      logger.info('Redis Pub/Sub 처리기가 시작되었습니다');
    } catch (error) {
      logger.error(`Redis Pub/Sub 시작 오류: ${error.message}`);
      throw error;
    }
  }

  /**
   * 채널 구독
   * @param {string} channel 구독할 채널 패턴
   * @param {Function} handler 메시지 처리 핸들러
   */
  subscribe(channel, handler) {
    this.handlers.set(channel, handler);
    
    if (channel.includes('*')) {
      this.subscriber.psubscribe(channel);
      
      // 패턴 구독 메시지 처리
      if (!this.subscriber.listenerCount('pmessage')) {
        this.subscriber.on('pmessage', (pattern, channel, message) => {
          this.handleMessage(pattern, channel, message);
        });
      }
    } else {
      this.subscriber.subscribe(channel);
      
      // 일반 구독 메시지 처리
      if (!this.subscriber.listenerCount('message')) {
        this.subscriber.on('message', (channel, message) => {
          this.handleMessage(channel, channel, message);
        });
      }
    }
    
    logger.debug(`채널 구독 시작: ${channel}`);
  }

  /**
   * 채널 구독 해제
   * @param {string} channel 구독 해제할 채널
   */
  unsubscribe(channel) {
    if (channel.includes('*')) {
      this.subscriber.punsubscribe(channel);
    } else {
      this.subscriber.unsubscribe(channel);
    }
    
    this.handlers.delete(channel);
    logger.debug(`채널 구독 해제: ${channel}`);
  }

  /**
   * 메시지 발행
   * @param {string} channel 발행할 채널
   * @param {any} message 발행할 메시지
   * @returns {Promise<number>} 메시지를 받은 구독자 수
   */
  async publish(channel, message) {
    try {
      const payload = typeof message === 'string' ? message : JSON.stringify(message);
      const subscribers = await this.publisher.publish(channel, payload);
      
      logger.debug(`메시지 발행: 채널=${channel}, 구독자=${subscribers}`);
      return subscribers;
    } catch (error) {
      logger.error(`메시지 발행 오류: 채널=${channel}, 오류=${error.message}`);
      throw error;
    }
  }

  /**
   * 메시지 처리
   * @param {string} pattern 구독한 패턴
   * @param {string} channel 실제 채널
   * @param {string} message 메시지 내용
   */
  handleMessage(pattern, channel, message) {
    try {
      // 주고받는 메시지 많으면 JSON 파싱도 부담됨
      // 배치 처리를 위해 메시지 추가
      this.batcher.add(
        channel,
        { pattern, channel, message },
        (messages) => this.processBatch(messages)
      );
    } catch (error) {
      logger.error(`메시지 처리 오류: 채널=${channel}, 오류=${error.message}`);
      this.addFailedMessage(pattern, channel, message);
    }
  }

  /**
   * 메시지 배치 처리
   * @param {Array} messages 처리할 메시지 배열
   */
  processBatch(messages) {
    if (!messages || messages.length === 0) return;
    
    // 채널별로 메시지 그룹화
    const groupedMessages = new Map();
    
    for (const msg of messages) {
      if (!groupedMessages.has(msg.channel)) {
        groupedMessages.set(msg.channel, []);
      }
      
      let payload;
      try {
        payload = JSON.parse(msg.message);
      } catch {
        payload = msg.message; // JSON이 아닌 경우 그대로 사용
      }
      
      groupedMessages.get(msg.channel).push(payload);
    }
    
    // 채널별로 처리
    for (const [channel, payloads] of groupedMessages.entries()) {
      // 패턴 매칭인 경우
      for (const [pattern, handler] of this.handlers.entries()) {
        if (
          pattern === channel ||
          (pattern.includes('*') && this.matchPattern(pattern, channel))
        ) {
          try {
            handler(channel, payloads.length === 1 ? payloads[0] : payloads);
          } catch (error) {
            logger.error(`배치 처리 오류: 채널=${channel}, 패턴=${pattern}, 오류=${error.message}`);
            
            // 개별 메시지에 대해 실패 처리
            for (const msg of messages.filter(m => m.channel === channel)) {
              this.addFailedMessage(msg.pattern, msg.channel, msg.message);
            }
          }
        }
      }
    }
  }

  /**
   * 패턴 일치 여부 확인
   * @param {string} pattern 패턴
   * @param {string} channel 채널
   * @returns {boolean} 일치 여부
   */
  matchPattern(pattern, channel) {
    const regexPattern = pattern
      .replace(/\*/g, '.*')
      .replace(/\?/g, '.')
      .replace(/\[/g, '[')
      .replace(/\]/g, ']');
    
    const regex = new RegExp(`^${regexPattern}$`);
    return regex.test(channel);
  }

  /**
   * 실패한 메시지 추가
   * @param {string} pattern 구독한 패턴
   * @param {string} channel 실제 채널
   * @param {string} message 메시지 내용
   */
  addFailedMessage(pattern, channel, message) {
    const id = `${channel}:${Date.now()}:${Math.random().toString(36).substring(2, 15)}`;
    
    this.failedMessages.set(id, {
      pattern,
      channel,
      message,
      attempts: 0,
      lastAttempt: Date.now(),
      nextAttempt: Date.now() + this.retryDelay
    });
  }

  /**
   * 실패한 메시지 재처리
   */
  processFailedMessages() {
    const now = Date.now();
    const toDelete = [];
    
    for (const [id, msg] of this.failedMessages.entries()) {
      if (now >= msg.nextAttempt) {
        if (msg.attempts < this.retryAttempts) {
          try {
            let payload = msg.message;
            try {
              payload = JSON.parse(msg.message);
            } catch {
              // 이미 문자열인 경우 그대로 사용
            }
            
            for (const [pattern, handler] of this.handlers.entries()) {
              if (
                pattern === msg.channel ||
                (pattern.includes('*') && this.matchPattern(pattern, msg.channel))
              ) {
                handler(msg.channel, payload);
                
                logger.debug(`실패 메시지 재처리 성공: ID=${id}, 채널=${msg.channel}`);
                toDelete.push(id);
                break;
              }
            }
          } catch (error) {
            logger.error(`실패 메시지 재처리 오류: ID=${id}, 채널=${msg.channel}, 오류=${error.message}`);
            
            // 재시도 정보 업데이트
            msg.attempts++;
            msg.lastAttempt = now;
            msg.nextAttempt = now + (this.retryDelay * Math.pow(2, msg.attempts)); // 지수 백오프
          }
        } else {
          logger.warn(`최대 재시도 횟수 초과로 메시지 폐기: ID=${id}, 채널=${msg.channel}`);
          toDelete.push(id);
        }
      }
    }
    
    // 처리 완료된 메시지 제거
    for (const id of toDelete) {
      this.failedMessages.delete(id);
    }
    
    logger.debug(`실패 메시지 재처리 완료: 남은 메시지=${this.failedMessages.size}`);
  }

  /**
   * 리소스 정리
   */
  async stop() {
    try {
      // 배치 처리 중지
      this.batcher.stop();
      
      // 재시도 타이머 중지
      if (this.retryInterval) {
        clearInterval(this.retryInterval);
      }
      
      // 남은 실패 메시지 강제 처리
      this.processFailedMessages();
      
      // 구독 해제
      for (const pattern of this.handlers.keys()) {
        if (pattern.includes('*')) {
          await this.subscriber.punsubscribe(pattern);
        } else {
          await this.subscriber.unsubscribe(pattern);
        }
      }
      
      logger.info('Redis Pub/Sub 처리기가 중지되었습니다');
    } catch (error) {
      logger.error(`Redis Pub/Sub 중지 오류: ${error.message}`);
    }
  }
}

module.exports = RedisPubSub; 
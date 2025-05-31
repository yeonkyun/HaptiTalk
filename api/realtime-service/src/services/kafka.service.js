/**
 * 실시간 서비스의 Kafka 관리 모듈
 */
const { createKafkaClient } = require('../../shared/kafka-client');
const logger = require('../utils/logger');

// Kafka 클라이언트 생성
const kafkaClient = createKafkaClient({
  clientId: process.env.SERVICE_NAME || 'realtime-service',
  logger
});

// 구독할 토픽 정의
const TOPICS = {
  SESSION_EVENTS: process.env.KAFKA_TOPIC_SESSION_EVENTS || 'haptitalk-session-events',
  FEEDBACK_EVENTS: process.env.KAFKA_TOPIC_FEEDBACK_EVENTS || 'haptitalk-feedback-events',
  USER_ACTIVITY: process.env.KAFKA_TOPIC_USER_ACTIVITY || 'haptitalk-user-activity'
};

/**
 * 세션 이벤트 구독 및 처리
 * @param {Function} onSessionEvent 세션 이벤트 처리 콜백
 */
const subscribeToSessionEvents = async (onSessionEvent) => {
  try {
    await kafkaClient.initConsumer({
      groupId: 'realtime-service-session-events',
      topics: [TOPICS.SESSION_EVENTS]
    }, async (message) => {
      try {
        const { value } = message;
        
        if (!value || !value.action || !value.sessionId) {
          logger.warn('유효하지 않은 세션 이벤트 메시지', { component: 'kafka' });
          return;
        }
        
        logger.debug(`세션 이벤트 수신: ${value.action} - ${value.sessionId}`, { component: 'kafka' });
        
        if (onSessionEvent) {
          await onSessionEvent(value);
        }
      } catch (error) {
        logger.error('세션 이벤트 처리 오류', {
          error: error.message,
          stack: error.stack,
          component: 'kafka'
        });
      }
    });
    
    logger.info('세션 이벤트 구독 시작됨', { component: 'kafka' });
    return true;
  } catch (error) {
    logger.error('세션 이벤트 구독 실패', {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

/**
 * 피드백 이벤트 구독 및 처리
 * @param {Function} onFeedbackEvent 피드백 이벤트 처리 콜백
 */
const subscribeToFeedbackEvents = async (onFeedbackEvent) => {
  try {
    await kafkaClient.initConsumer({
      groupId: 'realtime-service-feedback-events',
      topics: [TOPICS.FEEDBACK_EVENTS]
    }, async (message) => {
      try {
        const { value } = message;
        
        if (!value || !value.action || !value.feedbackId) {
          logger.warn('유효하지 않은 피드백 이벤트 메시지', { component: 'kafka' });
          return;
        }
        
        logger.debug(`피드백 이벤트 수신: ${value.action} - ${value.feedbackId}`, { component: 'kafka' });
        
        if (onFeedbackEvent) {
          await onFeedbackEvent(value);
        }
      } catch (error) {
        logger.error('피드백 이벤트 처리 오류', {
          error: error.message,
          stack: error.stack,
          component: 'kafka'
        });
      }
    });
    
    logger.info('피드백 이벤트 구독 시작됨', { component: 'kafka' });
    return true;
  } catch (error) {
    logger.error('피드백 이벤트 구독 실패', {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

/**
 * 실시간 이벤트 발행
 * @param {string} sessionId 세션 ID
 * @param {string} eventType 이벤트 유형
 * @param {Object} data 이벤트 데이터
 */
const publishRealtimeEvent = async (sessionId, eventType, data = {}) => {
  try {
    await initProducerIfNeeded();
    
    const message = {
      sessionId,
      eventType,
      timestamp: new Date().toISOString(),
      data
    };
    
    // 이벤트 종류에 따라 다른 토픽에 발행
    let topic;
    switch (eventType) {
      case 'SESSION_UPDATE':
        topic = TOPICS.SESSION_EVENTS;
        break;
      case 'FEEDBACK_UPDATE':
        topic = TOPICS.FEEDBACK_EVENTS;
        break;
      default:
        topic = TOPICS.USER_ACTIVITY;
    }
    
    await kafkaClient.sendMessage(topic, message, sessionId);
    logger.debug(`실시간 이벤트 발행 성공: ${eventType} - ${sessionId}`, { component: 'kafka' });
    
    return true;
  } catch (error) {
    logger.error(`실시간 이벤트 발행 실패: ${eventType} - ${sessionId}`, {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

/**
 * 프로듀서 초기화 (필요한 경우에만)
 */
const initProducerIfNeeded = async () => {
  try {
    await kafkaClient.initProducer();
    return true;
  } catch (error) {
    logger.error('Kafka 프로듀서 초기화 실패', {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    throw error;
  }
};

/**
 * Kafka 연결 종료
 */
const disconnect = async () => {
  try {
    await kafkaClient.disconnect();
    logger.info('Kafka 연결 종료 완료', { component: 'kafka' });
    return true;
  } catch (error) {
    logger.error('Kafka 연결 종료 실패', {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

module.exports = {
  subscribeToSessionEvents,
  subscribeToFeedbackEvents,
  publishRealtimeEvent,
  initProducerIfNeeded,
  disconnect,
  TOPICS
}; 
/**
 * 세션 서비스의 Kafka 관리 모듈
 */
const { createKafkaClient } = require('../../api/shared/kafka-client');
const logger = require('../utils/logger');

// Kafka 클라이언트 생성
const kafkaClient = createKafkaClient({
  clientId: process.env.SERVICE_NAME || 'session-service',
  logger
});

// 구독할 토픽 정의
const TOPICS = {
  SESSION_EVENTS: process.env.KAFKA_TOPIC_SESSION_EVENTS || 'haptitalk-session-events',
  USER_ACTIVITY: process.env.KAFKA_TOPIC_USER_ACTIVITY || 'haptitalk-user-activity',
  FEEDBACK_COMMANDS: process.env.KAFKA_TOPIC_FEEDBACK_COMMANDS || 'haptitalk-feedback-commands'
};

/**
 * 세션 생성 이벤트 발행
 * @param {string} sessionId 세션 ID
 * @param {object} sessionData 세션 데이터
 */
const publishSessionCreated = async (sessionId, sessionData) => {
  try {
    await initProducerIfNeeded();
    
    const message = {
      sessionId,
      userId: sessionData.user_id,
      type: sessionData.type,
      action: 'CREATED',
      timestamp: new Date().toISOString(),
      data: {
        title: sessionData.title,
        settings: sessionData.settings
      }
    };
    
    await kafkaClient.sendMessage(TOPICS.SESSION_EVENTS, message, sessionId);
    logger.debug(`세션 생성 이벤트 발행 성공: ${sessionId}`, { component: 'kafka' });
    
    return true;
  } catch (error) {
    logger.error(`세션 생성 이벤트 발행 실패: ${sessionId}`, {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

/**
 * 세션 업데이트 이벤트 발행
 * @param {string} sessionId 세션 ID
 * @param {object} sessionData 세션 데이터
 */
const publishSessionUpdated = async (sessionId, sessionData) => {
  try {
    await initProducerIfNeeded();
    
    const message = {
      sessionId,
      userId: sessionData.user_id,
      type: sessionData.type,
      action: 'UPDATED',
      timestamp: new Date().toISOString(),
      data: {
        status: sessionData.status,
        participants: sessionData.participants || []
      }
    };
    
    await kafkaClient.sendMessage(TOPICS.SESSION_EVENTS, message, sessionId);
    logger.debug(`세션 업데이트 이벤트 발행 성공: ${sessionId}`, { component: 'kafka' });
    
    return true;
  } catch (error) {
    logger.error(`세션 업데이트 이벤트 발행 실패: ${sessionId}`, {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

/**
 * 세션 종료 이벤트 발행
 * @param {string} sessionId 세션 ID
 * @param {object} sessionData 세션 데이터
 */
const publishSessionEnded = async (sessionId, sessionData) => {
  try {
    await initProducerIfNeeded();
    
    const message = {
      sessionId,
      userId: sessionData.user_id,
      type: sessionData.type,
      action: 'ENDED',
      timestamp: new Date().toISOString(),
      data: {
        duration: sessionData.duration,
        summary: sessionData.summary || {}
      }
    };
    
    await kafkaClient.sendMessage(TOPICS.SESSION_EVENTS, message, sessionId);
    logger.debug(`세션 종료 이벤트 발행 성공: ${sessionId}`, { component: 'kafka' });
    
    return true;
  } catch (error) {
    logger.error(`세션 종료 이벤트 발행 실패: ${sessionId}`, {
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
  publishSessionCreated,
  publishSessionUpdated,
  publishSessionEnded,
  disconnect,
  TOPICS
};
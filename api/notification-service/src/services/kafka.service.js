/**
 * 알림 서비스의 Kafka 관리 모듈
 */
const { createKafkaClient } = require('../../api/shared/kafka-client');
const logger = require('../utils/logger');
const notificationService = require('./notification.service');

// Kafka 클라이언트 생성
const kafkaClient = createKafkaClient({
  clientId: process.env.SERVICE_NAME || 'notification-service',
  logger
});

// 구독할 토픽 정의
const TOPICS = {
  USER_ACTIVITY: process.env.KAFKA_TOPIC_USER_ACTIVITY || 'haptitalk-user-activity',
  MESSAGE_EVENTS: process.env.KAFKA_TOPIC_MESSAGE_EVENTS || 'haptitalk-message-events',
  FEEDBACK_EVENTS: process.env.KAFKA_TOPIC_FEEDBACK_EVENTS || 'haptitalk-feedback-events'
};

/**
 * 사용자 활동 이벤트 처리 함수
 * @param {Object} message Kafka 메시지
 */
async function handleUserActivity({ value, key }) {
  try {
    const { userId, action, data, timestamp } = value;
    
    logger.info(`사용자 활동 이벤트 수신: ${action}`, { userId, action });
    
    // 활동 유형에 따른 알림 처리
    switch(action) {
      case 'SIGNUP':
        await notificationService.sendWelcomeNotification(userId);
        break;
        
      case 'PASSWORD_RESET':
        await notificationService.sendPasswordResetNotification(userId, data.email);
        break;
        
      case 'LOGIN_FAILED':
        if (data.attempts >= 3) {
          await notificationService.sendLoginAttemptWarning(userId, data.email, data.ip);
        }
        break;
        
      // 추가 이벤트 처리...
    }
  } catch (error) {
    logger.error('사용자 활동 이벤트 처리 실패', {
      error: error.message,
      stack: error.stack,
      component: 'kafka-service'
    });
  }
}

/**
 * 메시지 이벤트 처리 함수
 * @param {Object} message Kafka 메시지
 */
async function handleMessageEvent({ value, key }) {
  try {
    const { senderId, receiverId, messageType, messageId } = value;
    
    logger.info(`메시지 이벤트 수신: ${messageType}`, { messageId });
    
    // 메시지 유형에 따른 알림 처리
    switch(messageType) {
      case 'NEW_MESSAGE':
        await notificationService.sendNewMessageNotification(receiverId, senderId, value.content);
        break;
        
      case 'MESSAGE_READ':
        // 읽음 확인 시 별도 처리 필요 없음
        break;
        
      // 추가 이벤트 처리...
    }
  } catch (error) {
    logger.error('메시지 이벤트 처리 실패', {
      error: error.message,
      stack: error.stack,
      component: 'kafka-service'
    });
  }
}

/**
 * 피드백 이벤트 처리 함수
 * @param {Object} message Kafka 메시지
 */
async function handleFeedbackEvent({ value, key }) {
  try {
    const { userId, feedbackType, sessionId } = value;
    
    logger.info(`피드백 이벤트 수신: ${feedbackType}`, { sessionId });
    
    // 피드백 유형에 따른 알림 처리
    switch(feedbackType) {
      case 'SESSION_ENDED':
        await notificationService.sendFeedbackRequestNotification(userId, sessionId);
        break;
        
      case 'FEEDBACK_SUBMITTED':
        await notificationService.sendFeedbackReceivedConfirmation(userId);
        break;
        
      // 추가 이벤트 처리...
    }
  } catch (error) {
    logger.error('피드백 이벤트 처리 실패', {
      error: error.message,
      stack: error.stack,
      component: 'kafka-service'
    });
  }
}

/**
 * 컨슈머 초기화 및 시작
 */
async function startConsumers() {
  try {
    logger.info('Kafka 컨슈머 초기화 중...', { component: 'kafka-service' });
    
    // 사용자 활동 컨슈머
    await kafkaClient.initConsumer({
      groupId: 'notification-service-user-activity',
      topics: [TOPICS.USER_ACTIVITY]
    }, handleUserActivity);
    
    // 메시지 이벤트 컨슈머
    await kafkaClient.initConsumer({
      groupId: 'notification-service-messages',
      topics: [TOPICS.MESSAGE_EVENTS]
    }, handleMessageEvent);
    
    // 피드백 이벤트 컨슈머
    await kafkaClient.initConsumer({
      groupId: 'notification-service-feedback',
      topics: [TOPICS.FEEDBACK_EVENTS]
    }, handleFeedbackEvent);
    
    logger.info('모든 Kafka 컨슈머가 시작되었습니다', { component: 'kafka-service' });
    return true;
  } catch (error) {
    logger.error('Kafka 컨슈머 시작 실패', {
      error: error.message,
      stack: error.stack,
      component: 'kafka-service'
    });
    throw error;
  }
}

/**
 * 모든 연결 종료
 */
async function shutdown() {
  try {
    logger.info('Kafka 연결 종료 중...', { component: 'kafka-service' });
    await kafkaClient.disconnect();
    logger.info('Kafka 연결 종료 완료', { component: 'kafka-service' });
    return true;
  } catch (error) {
    logger.error('Kafka 연결 종료 실패', {
      error: error.message,
      stack: error.stack,
      component: 'kafka-service'
    });
    return false;
  }
}

module.exports = {
  startConsumers,
  shutdown,
  TOPICS
}; 
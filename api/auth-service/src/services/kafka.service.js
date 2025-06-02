/**
 * 인증 서비스의 Kafka 관리 모듈
 */
const { createKafkaClient } = require('../../api/shared/kafka-client');
const logger = require('../utils/logger');

// Kafka 클라이언트 생성
const kafkaClient = createKafkaClient({
  clientId: process.env.SERVICE_NAME || 'auth-service',
  logger
});

// 구독할 토픽 정의
const TOPICS = {
  AUTH_EVENTS: process.env.KAFKA_TOPIC_AUTH_EVENTS || 'haptitalk-auth-events',
  USER_ACTIVITY: process.env.KAFKA_TOPIC_USER_ACTIVITY || 'haptitalk-user-activity'
};

/**
 * 사용자 로그인 이벤트 발행
 * @param {Object} user 사용자 정보
 * @param {Object} deviceInfo 기기 정보
 */
const publishUserLoggedIn = async (user, deviceInfo) => {
  try {
    await initProducerIfNeeded();
    
    const message = {
      userId: user.id,
      action: 'USER_LOGGED_IN',
      timestamp: new Date().toISOString(),
      data: {
        userId: user.id,
        username: user.username,
        email: user.email,
        deviceId: deviceInfo.deviceId,
        deviceType: deviceInfo.deviceType,
        ipAddress: deviceInfo.ipAddress,
        userAgent: deviceInfo.userAgent
      }
    };
    
    await kafkaClient.sendMessage(TOPICS.AUTH_EVENTS, message, user.id);
    logger.debug(`사용자 로그인 이벤트 발행 성공: ${user.id}`, { component: 'kafka' });
    
    return true;
  } catch (error) {
    logger.error(`사용자 로그인 이벤트 발행 실패: ${user.id}`, {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

/**
 * 사용자 로그아웃 이벤트 발행
 * @param {string} userId 사용자 ID
 * @param {string} deviceId 기기 ID
 */
const publishUserLoggedOut = async (userId, deviceId) => {
  try {
    await initProducerIfNeeded();
    
    const message = {
      userId,
      action: 'USER_LOGGED_OUT',
      timestamp: new Date().toISOString(),
      data: {
        userId,
        deviceId,
        logoutTime: new Date().toISOString()
      }
    };
    
    await kafkaClient.sendMessage(TOPICS.AUTH_EVENTS, message, userId);
    logger.debug(`사용자 로그아웃 이벤트 발행 성공: ${userId}`, { component: 'kafka' });
    
    return true;
  } catch (error) {
    logger.error(`사용자 로그아웃 이벤트 발행 실패: ${userId}`, {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

/**
 * 사용자 가입 이벤트 발행
 * @param {Object} user 사용자 정보
 */
const publishUserRegistered = async (user) => {
  try {
    await initProducerIfNeeded();
    
    const message = {
      userId: user.id,
      action: 'USER_REGISTERED',
      timestamp: new Date().toISOString(),
      data: {
        userId: user.id,
        username: user.username,
        email: user.email,
        createdAt: user.createdAt || new Date().toISOString()
      }
    };
    
    await kafkaClient.sendMessage(TOPICS.AUTH_EVENTS, message, user.id);
    logger.debug(`사용자 가입 이벤트 발행 성공: ${user.id}`, { component: 'kafka' });
    
    return true;
  } catch (error) {
    logger.error(`사용자 가입 이벤트 발행 실패: ${user.id}`, {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

/**
 * 비밀번호 재설정 이벤트 발행
 * @param {string} userId 사용자 ID
 */
const publishPasswordReset = async (userId) => {
  try {
    await initProducerIfNeeded();
    
    const message = {
      userId,
      action: 'PASSWORD_RESET',
      timestamp: new Date().toISOString(),
      data: {
        userId,
        resetTime: new Date().toISOString()
      }
    };
    
    await kafkaClient.sendMessage(TOPICS.AUTH_EVENTS, message, userId);
    logger.debug(`비밀번호 재설정 이벤트 발행 성공: ${userId}`, { component: 'kafka' });
    
    return true;
  } catch (error) {
    logger.error(`비밀번호 재설정 이벤트 발행 실패: ${userId}`, {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

/**
 * 사용자 활동 이벤트 발행
 * @param {string} userId 사용자 ID
 * @param {string} action 활동 유형 
 * @param {Object} data 추가 데이터
 */
const publishUserActivity = async (userId, action, data = {}) => {
  try {
    await initProducerIfNeeded();
    
    const message = {
      userId,
      action,
      timestamp: new Date().toISOString(),
      data: {
        userId,
        ...data
      }
    };
    
    await kafkaClient.sendMessage(TOPICS.USER_ACTIVITY, message, userId);
    logger.debug(`사용자 활동 이벤트 발행 성공: ${userId} - ${action}`, { component: 'kafka' });
    
    return true;
  } catch (error) {
    logger.error(`사용자 활동 이벤트 발행 실패: ${userId} - ${action}`, {
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
  publishUserLoggedIn,
  publishUserLoggedOut,
  publishUserRegistered,
  publishPasswordReset,
  publishUserActivity,
  initProducerIfNeeded,
  disconnect,
  TOPICS
}; 
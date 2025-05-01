/**
 * 리포트 서비스의 Kafka 관리 모듈
 */
const { createKafkaClient } = require('../../../shared/kafka-client');
const logger = require('../utils/logger');

// Kafka 클라이언트 생성
const kafkaClient = createKafkaClient({
  clientId: process.env.SERVICE_NAME || 'report-service',
  logger
});

// 구독할 토픽 정의
const TOPICS = {
  REPORT_EVENTS: process.env.KAFKA_TOPIC_REPORT_EVENTS || 'haptitalk-report-events',
  SESSION_EVENTS: process.env.KAFKA_TOPIC_SESSION_EVENTS || 'haptitalk-session-events',
  FEEDBACK_ANALYTICS: process.env.KAFKA_TOPIC_FEEDBACK_ANALYTICS || 'haptitalk-feedback-analytics'
};

/**
 * 리포트 생성 이벤트 발행
 * @param {string} reportId 리포트 ID
 * @param {Object} reportData 리포트 데이터
 */
const publishReportGenerated = async (reportId, reportData) => {
  try {
    await initProducerIfNeeded();
    
    const message = {
      reportId,
      userId: reportData.userId,
      sessionId: reportData.sessionId,
      action: 'GENERATED',
      timestamp: new Date().toISOString(),
      data: {
        type: reportData.type,
        format: reportData.format,
        title: reportData.title,
        createdAt: reportData.createdAt || new Date().toISOString()
      }
    };
    
    await kafkaClient.sendMessage(TOPICS.REPORT_EVENTS, message, reportData.userId);
    logger.debug(`리포트 생성 이벤트 발행 성공: ${reportId}`, {
      userId: reportData.userId,
      component: 'kafka'
    });
    
    return true;
  } catch (error) {
    logger.error(`리포트 생성 이벤트 발행 실패: ${reportId}`, {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

/**
 * 리포트 다운로드 이벤트 발행
 * @param {string} reportId 리포트 ID
 * @param {string} userId 사용자 ID
 * @param {string} format 다운로드 형식
 */
const publishReportDownloaded = async (reportId, userId, format) => {
  try {
    await initProducerIfNeeded();
    
    const message = {
      reportId,
      userId,
      action: 'DOWNLOADED',
      timestamp: new Date().toISOString(),
      data: {
        format,
        downloadedAt: new Date().toISOString()
      }
    };
    
    await kafkaClient.sendMessage(TOPICS.REPORT_EVENTS, message, userId);
    logger.debug(`리포트 다운로드 이벤트 발행 성공: ${reportId}`, {
      userId,
      format,
      component: 'kafka'
    });
    
    return true;
  } catch (error) {
    logger.error(`리포트 다운로드 이벤트 발행 실패: ${reportId}`, {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    return false;
  }
};

/**
 * 세션 이벤트 구독 및 처리
 * @param {Function} handleSessionEnded 세션 종료 처리 함수
 */
const subscribeToSessionEvents = async (handleSessionEnded) => {
  try {
    await kafkaClient.initConsumer({
      groupId: 'report-service-session-events',
      topics: [TOPICS.SESSION_EVENTS]
    }, async (message) => {
      try {
        const { value } = message;
        
        if (!value || !value.action || !value.sessionId) {
          logger.warn('유효하지 않은 세션 이벤트 메시지', { component: 'kafka' });
          return;
        }
        
        logger.debug(`세션 이벤트 수신: ${value.action} - ${value.sessionId}`, { component: 'kafka' });
        
        // 세션 종료 시 자동 리포트 생성
        if (value.action === 'ENDED' && handleSessionEnded) {
          await handleSessionEnded(value.sessionId, value.userId, value);
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
 * 피드백 분석 이벤트 구독 및 처리
 * @param {Function} handleFeedbackAnalytics 피드백 분석 처리 함수
 */
const subscribeToFeedbackAnalytics = async (handleFeedbackAnalytics) => {
  try {
    await kafkaClient.initConsumer({
      groupId: 'report-service-feedback-analytics',
      topics: [TOPICS.FEEDBACK_ANALYTICS]
    }, async (message) => {
      try {
        const { value } = message;
        
        if (!value || !value.action || !value.sessionId) {
          logger.warn('유효하지 않은 피드백 분석 이벤트 메시지', { component: 'kafka' });
          return;
        }
        
        logger.debug(`피드백 분석 이벤트 수신: ${value.sessionId}`, { component: 'kafka' });
        
        if (value.action === 'ANALYTICS' && handleFeedbackAnalytics) {
          await handleFeedbackAnalytics(value.sessionId, value.userId, value.data);
        }
      } catch (error) {
        logger.error('피드백 분석 이벤트 처리 오류', {
          error: error.message,
          stack: error.stack,
          component: 'kafka'
        });
      }
    });
    
    logger.info('피드백 분석 이벤트 구독 시작됨', { component: 'kafka' });
    return true;
  } catch (error) {
    logger.error('피드백 분석 이벤트 구독 실패', {
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
  publishReportGenerated,
  publishReportDownloaded,
  subscribeToSessionEvents,
  subscribeToFeedbackAnalytics,
  disconnect,
  TOPICS
}; 
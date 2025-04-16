const HttpClient = require('../utils/http-client');
const logger = require('../utils/logger');

/**
 * 세션 서비스 API 클라이언트
 */
const createSessionServiceClient = () => {
  const baseURL = process.env.SESSION_SERVICE_URL || 'http://session-service:3002';
  
  logger.info(`세션 서비스 API 클라이언트 생성: ${baseURL}`);
  
  return new HttpClient(baseURL, {
    timeout: 3000, // 3초 타임아웃
    errorThresholdPercentage: 30, // 30% 에러 임계치
    resetTimeout: 5000, // 5초 후 재시도
    name: 'SessionService'
  });
};

/**
 * 피드백 서비스 API 클라이언트
 */
const createFeedbackServiceClient = () => {
  const baseURL = process.env.FEEDBACK_SERVICE_URL || 'http://feedback-service:3003';
  
  logger.info(`피드백 서비스 API 클라이언트 생성: ${baseURL}`);
  
  return new HttpClient(baseURL, {
    timeout: 3000, // 3초 타임아웃
    errorThresholdPercentage: 30, // 30% 에러 임계치
    resetTimeout: 5000, // 5초 후 재시도
    name: 'FeedbackService'
  });
};

/**
 * 서비스 API 클라이언트 인스턴스 생성
 */
const sessionServiceClient = createSessionServiceClient();
const feedbackServiceClient = createFeedbackServiceClient();

// 토큰 설정 메서드
const setServiceAuthToken = (token) => {
  sessionServiceClient.setAuthToken(token);
  feedbackServiceClient.setAuthToken(token);
  logger.debug('서비스 API 클라이언트 인증 토큰 설정 완료');
};

module.exports = {
  sessionServiceClient,
  feedbackServiceClient,
  setServiceAuthToken
}; 
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const {redisHelpers} = require('../config/redis');
const logger = require('../utils/logger');

// 서비스 간 통신을 위한 비밀키 (실제로는 환경 변수로 관리)
const SERVICE_AUTH_SECRET = process.env.SERVICE_AUTH_SECRET || 'inter_service_secret';
const SERVICE_TOKEN_EXPIRY = process.env.SERVICE_TOKEN_EXPIRY || '1h';

// 등록된 서비스 목록 (실제로는 데이터베이스에서 관리)
const registeredServices = {
  'auth-service': { id: 'auth-service-id', secret: process.env.AUTH_SERVICE_SECRET || 'auth-service-secret' },
  'user-service': { id: 'user-service-id', secret: process.env.USER_SERVICE_SECRET || 'user-service-secret' },
  'session-service': { id: 'session-service-id', secret: process.env.SESSION_SERVICE_SECRET || 'session-service-secret' },
  'realtime-service': { id: 'realtime-service-id', secret: process.env.REALTIME_SERVICE_SECRET || 'realtime-service-secret' },
  'feedback-service': { id: 'feedback-service-id', secret: process.env.FEEDBACK_SERVICE_SECRET || 'feedback-service-secret' },
  'report-service': { id: 'report-service-id', secret: process.env.REPORT_SERVICE_SECRET || 'report-service-secret' }
};

const serviceAuthService = {
  /**
   * 서비스 인증 토큰 생성
   * @param {string} serviceId - 서비스 ID
   * @param {string} serviceSecret - 서비스 비밀키
   * @returns {Object} - 생성된 서비스 토큰 정보
   */
  generateServiceToken: async (serviceId, serviceSecret) => {
    try {
      // 등록된 서비스인지 확인
      const service = Object.values(registeredServices).find(s => s.id === serviceId);
      if (!service) {
        throw new Error(`미등록 서비스: ${serviceId}`);
      }

      // 서비스 비밀키 검증
      if (service.secret !== serviceSecret) {
        throw new Error('유효하지 않은 서비스 비밀키');
      }

      // 토큰 ID 생성
      const tokenId = crypto.randomBytes(16).toString('hex');

      // 페이로드 생성
      const payload = {
        sub: serviceId,
        jti: tokenId,
        type: 'service'
      };

      // 토큰 생성
      const token = jwt.sign(payload, SERVICE_AUTH_SECRET, {
        expiresIn: SERVICE_TOKEN_EXPIRY
      });

      // 디코딩하여 만료 시간 확인
      const decoded = jwt.decode(token);
      const expiryTime = new Date(decoded.exp * 1000);

      // Redis에 토큰 저장
      const ttl = Math.floor(decoded.exp - decoded.iat);
      await redisHelpers.storeServiceToken(tokenId, serviceId, ttl);

      logger.info(`서비스 토큰 생성 완료: ${serviceId}`);

      return {
        token,
        expires: expiryTime
      };
    } catch (error) {
      logger.error(`서비스 토큰 생성 오류: ${error.message}`);
      throw error;
    }
  },

  /**
   * 서비스 인증 토큰 검증
   * @param {string} token - 서비스 인증 토큰
   * @returns {Object} - 검증된 토큰 페이로드
   */
  verifyServiceToken: async (token) => {
    try {
      // JWT 검증
      const decoded = jwt.verify(token, SERVICE_AUTH_SECRET);

      // 토큰 타입 확인
      if (decoded.type !== 'service') {
        throw new Error('유효하지 않은 토큰 타입');
      }

      // Redis에서 토큰 확인
      const storedServiceId = await redisHelpers.getServiceIdFromToken(decoded.jti);
      if (!storedServiceId) {
        throw new Error('토큰을 찾을 수 없음');
      }

      // 토큰의 서비스 ID 일치 여부 확인
      if (storedServiceId !== decoded.sub) {
        throw new Error('서비스 ID 불일치');
      }

      logger.debug(`서비스 토큰 검증 성공: ${decoded.sub}`);
      return decoded;
    } catch (error) {
      if (error.name === 'JsonWebTokenError') {
        throw new Error('유효하지 않은 토큰');
      } else if (error.name === 'TokenExpiredError') {
        throw new Error('만료된 토큰');
      }
      throw error;
    }
  },

  /**
   * 서비스 인증 토큰 폐기
   * @param {string} token - 서비스 인증 토큰
   */
  revokeServiceToken: async (token) => {
    try {
      const decoded = jwt.decode(token);
      if (!decoded || !decoded.jti) {
        throw new Error('유효하지 않은 토큰');
      }

      // Redis에서 토큰 삭제
      await redisHelpers.removeServiceToken(decoded.jti);
      logger.debug(`서비스 토큰 폐기 완료: ${decoded.sub}`);
    } catch (error) {
      logger.error(`서비스 토큰 폐기 오류: ${error.message}`);
      throw error;
    }
  },
  
  /**
   * 서비스 등록 여부 확인
   * @param {string} serviceName - 서비스 이름
   * @returns {boolean} - 등록 여부
   */
  isRegisteredService: (serviceName) => {
    return Object.keys(registeredServices).includes(serviceName);
  },
  
  /**
   * 서비스 정보 조회
   * @param {string} serviceName - 서비스 이름
   * @returns {Object|null} - 서비스 정보
   */
  getServiceInfo: (serviceName) => {
    return registeredServices[serviceName] || null;
  }
};

module.exports = serviceAuthService; 
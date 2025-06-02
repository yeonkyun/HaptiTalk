const httpStatus = require('http-status');
const serviceAuthService = require('../services/service-auth.service');
const logger = require('../utils/logger');

const serviceAuthController = {
  /**
   * 서비스 토큰 발급
   * POST /api/v1/auth/service-token
   */
  generateServiceToken: async (req, res, next) => {
    try {
      const { serviceId, serviceSecret } = req.body;

      if (!serviceId || !serviceSecret) {
        return res.status(httpStatus.BAD_REQUEST).json({
          success: false,
          message: '서비스 ID와 비밀키가 필요합니다.'
        });
      }

      const tokenData = await serviceAuthService.generateServiceToken(serviceId, serviceSecret);
      
      res.status(httpStatus.OK).json({
        success: true,
        data: {
          token: tokenData.token,
          expires: tokenData.expires
        },
        message: '서비스 토큰이 성공적으로 발급되었습니다.'
      });
    } catch (error) {
      logger.error('서비스 토큰 발급 오류:', error);
      
      // 에러 메시지에 따른 상태 코드 맵핑
      let statusCode = httpStatus.INTERNAL_SERVER_ERROR;
      if (error.message.includes('미등록 서비스') || error.message.includes('유효하지 않은 서비스 비밀키')) {
        statusCode = httpStatus.UNAUTHORIZED;
      }
      
      return res.status(statusCode).json({
        success: false,
        message: error.message
      });
    }
  },

  /**
   * 서비스 토큰 검증
   * POST /api/v1/auth/service-token/verify
   */
  verifyServiceToken: async (req, res, next) => {
    try {
      const { token } = req.body;

      if (!token) {
        return res.status(httpStatus.BAD_REQUEST).json({
          success: false,
          message: '토큰이 필요합니다.'
        });
      }

      const decoded = await serviceAuthService.verifyServiceToken(token);
      
      res.status(httpStatus.OK).json({
        success: true,
        data: {
          serviceId: decoded.sub,
          valid: true
        },
        message: '유효한 서비스 토큰입니다.'
      });
    } catch (error) {
      logger.error('서비스 토큰 검증 오류:', error);
      
      return res.status(httpStatus.UNAUTHORIZED).json({
        success: false,
        data: {
          valid: false
        },
        message: error.message
      });
    }
  },

  /**
   * 서비스 토큰 폐기
   * POST /api/v1/auth/service-token/revoke
   */
  revokeServiceToken: async (req, res, next) => {
    try {
      const { token } = req.body;

      if (!token) {
        return res.status(httpStatus.BAD_REQUEST).json({
          success: false,
          message: '토큰이 필요합니다.'
        });
      }

      await serviceAuthService.revokeServiceToken(token);
      
      res.status(httpStatus.OK).json({
        success: true,
        message: '서비스 토큰이 성공적으로 폐기되었습니다.'
      });
    } catch (error) {
      logger.error('서비스 토큰 폐기 오류:', error);
      
      return res.status(httpStatus.INTERNAL_SERVER_ERROR).json({
        success: false,
        message: error.message
      });
    }
  }
};

module.exports = serviceAuthController; 
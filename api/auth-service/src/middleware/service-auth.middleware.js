/**
 * 서비스 인증 미들웨어
 * 마이크로서비스 간 통신에서 서비스 토큰 인증을 처리
 */

const httpStatus = require('http-status');
const serviceAuthService = require('../services/service-auth.service');
const logger = require('../utils/logger');

// 서비스 인증 미들웨어
const verifyServiceToken = async (req, res, next) => {
  try {
    // 헤더에서 서비스 토큰 추출
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(httpStatus.UNAUTHORIZED).json({
        success: false,
        message: '서비스 인증 토큰이 필요합니다'
      });
    }

    const token = authHeader.split(' ')[1];
    
    // 토큰 검증
    const decoded = await serviceAuthService.verifyServiceToken(token);
    
    // 요청 객체에 서비스 정보 추가
    req.service = {
      id: decoded.sub,
      tokenId: decoded.jti
    };
    
    next();
  } catch (error) {
    logger.error('서비스 인증 오류:', error);
    
    return res.status(httpStatus.UNAUTHORIZED).json({
      success: false,
      message: error.message || '서비스 인증 실패'
    });
  }
};

// 특정 서비스만 접근 가능하도록 제한하는 미들웨어
const restrictToServices = (allowedServices) => {
  return (req, res, next) => {
    if (!req.service || !req.service.id) {
      return res.status(httpStatus.UNAUTHORIZED).json({
        success: false,
        message: '서비스 인증이 필요합니다'
      });
    }

    // 서비스 ID를 서비스 이름으로 변환 (실제로는 더 복잡한 매핑 필요)
    const serviceIds = Object.values(allowedServices);
    
    if (!serviceIds.includes(req.service.id)) {
      return res.status(httpStatus.FORBIDDEN).json({
        success: false,
        message: '이 엔드포인트에 접근 권한이 없습니다'
      });
    }

    next();
  };
};

module.exports = {
  verifyServiceToken,
  restrictToServices
}; 
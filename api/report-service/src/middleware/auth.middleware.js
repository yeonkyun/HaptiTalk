const jwt = require('jsonwebtoken');
const { formatErrorResponse } = require('../utils/responseFormatter');
const logger = require('../utils/logger');

/**
 * JWT 토큰 기반 인증 미들웨어
 */
const authenticate = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return formatErrorResponse(res, 401, '인증 토큰이 필요합니다');
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);

        req.user = {
            id: decoded.sub,
            email: decoded.email
        };

        next();
    } catch (error) {
        logger.error(`Authentication error: ${error.message}`);

        if (error.name === 'TokenExpiredError') {
            return formatErrorResponse(res, 401, '인증 토큰이 만료되었습니다');
        }

        if (error.name === 'JsonWebTokenError') {
            return formatErrorResponse(res, 401, '유효하지 않은 인증 토큰입니다');
        }

        return formatErrorResponse(res, 500, '인증 처리 중 오류가 발생했습니다');
    }
};

module.exports = {
    authenticate
};
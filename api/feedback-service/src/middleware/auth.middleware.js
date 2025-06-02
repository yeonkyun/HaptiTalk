const jwt = require('jsonwebtoken');
const httpStatus = require('http-status');
const { formatResponse } = require('../utils/responseFormatter');

/**
 * JWT 인증 미들웨어
 */
const authenticateJWT = (req, res, next) => {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(httpStatus.UNAUTHORIZED).json(formatResponse(
            false,
            null,
            '인증 토큰이 필요합니다.'
        ));
    }

    const token = authHeader.split(' ')[1];

    try {
        const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
        req.user = {
            id: decoded.sub,
            email: decoded.email,
            type: decoded.type
        };
        next();
    } catch (error) {
        return res.status(httpStatus.UNAUTHORIZED).json(formatResponse(
            false,
            null,
            '유효하지 않거나 만료된 토큰입니다.'
        ));
    }
};

/**
 * 관리자 권한 확인 미들웨어
 */
const isAdmin = (req, res, next) => {
    if (!req.user || req.user.role !== 'admin') {
        return res.status(httpStatus.FORBIDDEN).json(formatResponse(
            false,
            null,
            '관리자 권한이 필요합니다.'
        ));
    }
    next();
};

module.exports = {
    authenticateJWT,
    isAdmin
};
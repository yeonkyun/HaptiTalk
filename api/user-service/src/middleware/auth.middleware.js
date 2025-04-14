const jwt = require('jsonwebtoken');
const {redisClient} = require('../config/redis');
const logger = require('../utils/logger');

const verifyToken = async (req, res, next) => {
    try {
        // Authorization 헤더에서 토큰 추출
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: '인증 토큰이 제공되지 않았습니다.',
                errors: [{code: 'auth.missing_token'}]
            });
        }

        const token = authHeader.split(' ')[1];

        // 토큰 검증
        const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);

        // Redis에서 무효화된 토큰인지 확인
        const isBlacklisted = await redisClient.exists(`auth:blocklist:${token}`);
        if (isBlacklisted) {
            return res.status(401).json({
                success: false,
                message: '만료된 토큰입니다.',
                errors: [{code: 'auth.expired_token'}]
            });
        }

        // 요청 객체에 사용자 정보 추가
        req.user = decoded;
        // JWT sub 필드를 id로 매핑
        if (decoded.sub && !decoded.id) {
            req.user.id = decoded.sub;
        }
        next();
    } catch (error) {
        logger.error('Token verification error:', error);

        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({
                success: false,
                message: '만료된 토큰입니다.',
                errors: [{code: 'auth.expired_token'}]
            });
        }

        return res.status(401).json({
            success: false,
            message: '유효하지 않은 토큰입니다.',
            errors: [{code: 'auth.invalid_token'}]
        });
    }
};

module.exports = {
    verifyToken
};
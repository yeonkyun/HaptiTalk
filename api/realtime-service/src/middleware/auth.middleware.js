const jwt = require('jsonwebtoken');
const logger = require('../utils/logger');

/**
 * Socket.io 연결에서 JWT 액세스 토큰 검증
 * @param {string} token - 검증할 JWT 토큰
 * @param {Redis} redisClient - Redis 클라이언트 인스턴스
 * @returns {Promise<Object>} - 토큰에서 추출한 사용자 정보
 */
const verifySocketToken = async (token, redisClient) => {
    try {
        // JWT 토큰 검증
        const decoded = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
        const { sub: userId, email } = decoded;

        // Redis에서 사용자 정보 확인 (선택적)
        const userKey = `user:${userId}`;
        const userExists = await redisClient.exists(userKey);

        if (!userExists) {
            // 사용자 정보가 없으면 Redis에 저장
            await redisClient.hset(userKey, {
                email,
                lastSeen: new Date().toISOString()
            });
        } else {
            // 마지막 접속 시간 업데이트
            await redisClient.hset(userKey, 'lastSeen', new Date().toISOString());
        }

        return { id: userId, email };
    } catch (error) {
        logger.error(`토큰 검증 오류: ${error.message}`);
        throw error;
    }
};

/**
 * 서비스 간 통신을 위한 토큰 검증 미들웨어
 * @param {Object} req - Express 요청 객체 
 * @param {Object} res - Express 응답 객체
 * @param {Function} next - Express 다음 미들웨어 함수
 */
const validateServiceToken = (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                success: false,
                message: '인증 토큰이 필요합니다'
            });
        }
        
        const token = authHeader.split(' ')[1];
        
        // 환경 변수에서 서비스 토큰 가져오기
        const serviceToken = process.env.INTER_SERVICE_TOKEN || 'default-service-token';
        
        // 간단한 토큰 비교 (실제 환경에서는 더 안전한 방식 사용 권장)
        if (token !== serviceToken) {
            return res.status(403).json({
                success: false,
                message: '유효하지 않은 서비스 토큰입니다'
            });
        }
        
        next();
    } catch (error) {
        logger.error(`서비스 토큰 검증 오류: ${error.message}`);
        return res.status(500).json({
            success: false,
            message: '인증 처리 중 오류가 발생했습니다'
        });
    }
};

module.exports = { verifySocketToken, validateServiceToken };
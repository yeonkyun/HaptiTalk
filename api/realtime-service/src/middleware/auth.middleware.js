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

module.exports = { verifySocketToken };
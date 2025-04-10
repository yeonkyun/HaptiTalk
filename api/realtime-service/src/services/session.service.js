const logger = require('../utils/logger');

/**
 * 세션 유효성 검증
 * @param {string} sessionId - 세션 ID
 * @param {string} userId - 사용자 ID
 * @param {Redis} redisClient - Redis 클라이언트
 * @returns {Promise<boolean>} - 세션 유효성 여부
 */
const validateSession = async (sessionId, userId, redisClient) => {
    try {
        // Redis에서 세션 정보 조회
        const sessionKey = `session:${sessionId}`;
        const sessionData = await redisClient.get(sessionKey);

        if (!sessionData) {
            logger.warn(`존재하지 않는 세션: ${sessionId}`);
            return false;
        }

        const session = JSON.parse(sessionData);

        // 세션 상태 확인
        if (session.status !== 'active') {
            logger.warn(`활성 상태가 아닌 세션: ${sessionId}, 현재 상태: ${session.status}`);
            return false;
        }

        // 사용자가 세션 소유자인 경우
        if (session.user_id === userId) {
            return true;
        }

        // 초대된 참가자 확인
        const participantKey = `session:${sessionId}:participant:${userId}`;
        const participantData = await redisClient.get(participantKey);
        
        if (!participantData) {
            logger.warn(`권한이 없는 사용자의 세션 접근: ${userId}, 세션: ${sessionId}`);
            return false;
        }

        return true;
    } catch (error) {
        logger.error(`세션 검증 오류: ${error.message}`);
        return false;
    }
};

/**
 * 세션 현재 상태 조회
 * @param {string} sessionId - 세션 ID
 * @param {Redis} redisClient - Redis 클라이언트
 * @returns {Promise<Object>} - 세션 상태 정보
 */
const getSessionStatus = async (sessionId, redisClient) => {
    try {
        // Redis에서 세션 정보 조회
        const sessionKey = `session:${sessionId}`;
        const sessionData = await redisClient.get(sessionKey);

        if (!sessionData) {
            throw new Error('세션을 찾을 수 없습니다');
        }

        const session = JSON.parse(sessionData);

        // 현재 참가자 목록 조회
        const participantPattern = `session:${sessionId}:participant:*`;
        const participantKeys = await redisClient.keys(participantPattern);
        const participants = [];

        for (const key of participantKeys) {
            const participantData = await redisClient.get(key);
            if (participantData) {
                participants.push(JSON.parse(participantData));
            }
        }

        // 실시간 분석 결과 조회
        const analysisKey = `analysis:latest:${sessionId}`;
        const analysisData = await redisClient.get(analysisKey);
        const analysis = analysisData ? JSON.parse(analysisData) : null;

        return {
            sessionId,
            status: session.status,
            startTime: session.start_time,
            sessionType: session.session_type,
            participants,
            participantsCount: participants.length,
            latestAnalysis: analysis
        };
    } catch (error) {
        logger.error(`세션 상태 조회 오류: ${error.message}`);
        throw error;
    }
};

module.exports = {validateSession, getSessionStatus};
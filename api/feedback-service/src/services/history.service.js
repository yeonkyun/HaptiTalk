const { getFeedbackHistory: getHistoryFromMongo } = require('./mongodb.service');
const { getDB } = require('../config/mongodb');
const logger = require('../utils/logger');

/**
 * 피드백 이력 조회
 */
const getFeedbackHistory = async (query, options) => {
    try {
        return await getHistoryFromMongo(query, options);
    } catch (error) {
        logger.error('Error in getFeedbackHistory:', error);
        throw error;
    }
};

/**
 * 세션 접근 권한 확인
 */
const canAccessSession = async (userId, sessionId) => {
    try {
        // PostgreSQL의 세션 테이블에서 세션 소유자 확인
        // 또는 Redis 캐시에서 확인
        // 여기서는 간단한 구현을 위해 MongoDB를 사용
        const db = getDB();
        const session = await db.collection('sessionAnalytics').findOne(
            { sessionId, userId },
            { projection: { _id: 1 } }
        );

        return !!session; // 세션이 있으면 접근 가능
    } catch (error) {
        logger.error(`Error in canAccessSession for userId ${userId}, sessionId ${sessionId}:`, error);
        return false;
    }
};

module.exports = {
    getFeedbackHistory,
    canAccessSession
};
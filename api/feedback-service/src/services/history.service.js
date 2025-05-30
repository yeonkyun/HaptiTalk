const { getFeedbackHistory: getHistoryFromMongo } = require('./mongodb.service');
const { getDB } = require('../config/mongodb');
const logger = require('../utils/logger');

/**
 * 피드백 이력 조회
 */
const getFeedbackHistory = async (query, options) => {
    try {
        const result = await getHistoryFromMongo(query, options);
        
        logger.info(`피드백 이력 조회 요청 처리 성공`, {
            queryConditions: Object.keys(query),
            resultCount: result.data.length,
            totalCount: result.meta.total,
            page: result.meta.page,
            limit: result.meta.limit
        });
        
        return result;
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

        const hasAccess = !!session;
        
        logger.info(`세션 접근 권한 확인 완료: ${sessionId}`, {
            userId,
            sessionId,
            hasAccess,
            checkResult: hasAccess ? 'GRANTED' : 'DENIED'
        });

        return hasAccess;
    } catch (error) {
        logger.error(`Error in canAccessSession for userId ${userId}, sessionId ${sessionId}:`, error);
        return false;
    }
};

module.exports = {
    getFeedbackHistory,
    canAccessSession
};
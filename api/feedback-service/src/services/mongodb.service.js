const { getCollection } = require('../config/mongodb');
const logger = require('../utils/logger');

/**
 * 피드백 이력 저장
 */
const saveFeedbackHistory = async (feedbackData) => {
    try {
        const collection = getCollection('hapticFeedbacks');
        const result = await collection.insertOne({
            ...feedbackData,
            timestamp: new Date()
        });

        logger.info(`피드백 이력 저장 성공: ${result.insertedId}`, {
            feedbackId: result.insertedId,
            userId: feedbackData.userId,
            sessionId: feedbackData.sessionId,
            patternId: feedbackData.patternId
        });

        return result.insertedId;
    } catch (error) {
        logger.error('Error in saveFeedbackHistory:', error);
        throw error;
    }
};

/**
 * 피드백 이력 조회
 */
const getFeedbackHistory = async (query, options = {}) => {
    try {
        const collection = getCollection('hapticFeedbacks');
        const { limit = 10, page = 1, sort = { timestamp: -1 } } = options;

        const skip = (page - 1) * limit;

        const [feedbacks, total] = await Promise.all([
            collection.find(query)
                .sort(sort)
                .skip(skip)
                .limit(limit)
                .toArray(),
            collection.countDocuments(query)
        ]);

        logger.info(`피드백 이력 조회 성공`, {
            query,
            resultCount: feedbacks.length,
            totalCount: total,
            page,
            limit
        });

        return {
            data: feedbacks,
            meta: {
                total,
                page,
                limit,
                pages: Math.ceil(total / limit)
            }
        };
    } catch (error) {
        logger.error('Error in getFeedbackHistory:', error);
        throw error;
    }
};

/**
 * 세션 분석 데이터 조회
 */
const getSessionAnalytics = async (sessionId) => {
    try {
        const collection = getCollection('sessionAnalytics');
        const analytics = await collection.findOne({ sessionId });
        
        if (analytics) {
            logger.info(`세션 분석 데이터 조회 성공: ${sessionId}`, {
                sessionId,
                hasData: true,
                analyticsId: analytics._id
            });
        } else {
            logger.debug(`세션 분석 데이터 없음: ${sessionId}`, {
                sessionId,
                hasData: false
            });
        }
        
        return analytics;
    } catch (error) {
        logger.error(`Error in getSessionAnalytics for sessionId ${sessionId}:`, error);
        throw error;
    }
};

module.exports = {
    saveFeedbackHistory,
    getFeedbackHistory,
    getSessionAnalytics
};
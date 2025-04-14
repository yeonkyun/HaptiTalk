const { formatResponse } = require('../utils/responseFormatter');
const statsService = require('../services/stats.service');
const logger = require('../utils/logger');

const statsController = {
    /**
     * 세션 유형별 통계 조회
     */
    async getStatsBySessionType(req, res, next) {
        try {
            const userId = req.user.id;

            logger.info(`Getting stats by session type for user ${userId}`);

            const stats = await statsService.getStatsBySessionType(userId);

            return formatResponse(res, 200, true, stats, 'Session type statistics retrieved successfully');
        } catch (error) {
            next(error);
        }
    },

    /**
     * 시간별 통계 조회
     */
    async getStatsByTimeframe(req, res, next) {
        try {
            const userId = req.user.id;
            const { timeframe = 'daily', startDate, endDate } = req.query;

            logger.info(`Getting ${timeframe} stats for user ${userId}`);

            const stats = await statsService.getStatsByTimeframe(
                userId,
                timeframe,
                startDate,
                endDate
            );

            return formatResponse(res, 200, true, stats, `${timeframe} statistics retrieved successfully`);
        } catch (error) {
            next(error);
        }
    },

    /**
     * 피드백 통계 조회
     */
    async getFeedbackStats(req, res, next) {
        try {
            const userId = req.user.id;

            logger.info(`Getting feedback stats for user ${userId}`);

            const stats = await statsService.getFeedbackStats(userId);

            return formatResponse(res, 200, true, stats, 'Feedback statistics retrieved successfully');
        } catch (error) {
            next(error);
        }
    }
};

module.exports = statsController;
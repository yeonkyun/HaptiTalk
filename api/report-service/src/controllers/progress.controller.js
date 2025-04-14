const { formatResponse } = require('../utils/responseFormatter');
const progressService = require('../services/progress.service');
const logger = require('../utils/logger');

const progressController = {
    /**
     * 사용자 발전 추이 조회
     */
    async getProgressTrend(req, res, next) {
        try {
            const userId = req.user.id;
            const { metrics, period } = req.query;

            logger.info(`Getting progress trend for user ${userId}`);

            // 쿼리 파라미터 파싱
            const metricsList = metrics ? metrics.split(',') : undefined;
            const periodNum = period ? parseInt(period) : undefined;

            const trend = await progressService.getProgressTrend(
                userId,
                metricsList,
                periodNum
            );

            return formatResponse(res, 200, true, trend, 'Progress trend retrieved successfully');
        } catch (error) {
            next(error);
        }
    },

    /**
     * 상황별 발전 추이 조회
     */
    async getContextProgressTrend(req, res, next) {
        try {
            const userId = req.user.id;
            const { contextType } = req.params;

            logger.info(`Getting ${contextType} progress trend for user ${userId}`);

            // 유효한 컨텍스트 유형 검증
            const validContextTypes = ['dating', 'interview', 'business', 'coaching'];
            if (!validContextTypes.includes(contextType)) {
                return formatResponse(res, 400, false, null, `Invalid context type. Must be one of: ${validContextTypes.join(', ')}`);
            }

            const contextTrend = await progressService.getContextProgressTrend(
                userId,
                contextType
            );

            return formatResponse(res, 200, true, contextTrend, `${contextType} progress trend retrieved successfully`);
        } catch (error) {
            next(error);
        }
    },

    /**
     * 발전 추이 요약 조회
     */
    async getProgressSummary(req, res, next) {
        try {
            const userId = req.user.id;

            logger.info(`Getting progress summary for user ${userId}`);

            const summary = await progressService.getProgressSummary(userId);

            return formatResponse(res, 200, true, summary, 'Progress summary retrieved successfully');
        } catch (error) {
            next(error);
        }
    }
};

module.exports = progressController;
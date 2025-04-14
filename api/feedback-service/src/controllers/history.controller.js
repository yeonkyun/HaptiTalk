const httpStatus = require('http-status');
const historyService = require('../services/history.service');
const { formatResponse } = require('../utils/responseFormatter');

/**
 * 사용자 피드백 이력 조회
 */
const getFeedbackHistory = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const { session_id, pattern_id, limit, page } = req.query;

        const query = { userId };
        if (session_id) query.sessionId = session_id;
        if (pattern_id) query.pattern_id = pattern_id;

        const options = {
            limit: limit ? parseInt(limit, 10) : 10,
            page: page ? parseInt(page, 10) : 1
        };

        const history = await historyService.getFeedbackHistory(query, options);

        return res.status(httpStatus.OK).json(formatResponse(
            true,
            history.data,
            '피드백 이력을 성공적으로 조회했습니다.',
            history.meta
        ));
    } catch (error) {
        next(error);
    }
};

/**
 * 세션별 피드백 이력 조회
 */
const getSessionFeedbacks = async (req, res, next) => {
    try {
        const { session_id } = req.params;
        const { limit, page } = req.query;

        // 세션 접근 권한 확인 (세션 소유자 또는 관리자)
        const canAccess = await historyService.canAccessSession(req.user.id, session_id);
        if (!canAccess) {
            return res.status(httpStatus.FORBIDDEN).json(formatResponse(
                false,
                null,
                '이 세션에 접근할 권한이 없습니다.'
            ));
        }

        const options = {
            limit: limit ? parseInt(limit, 10) : 10,
            page: page ? parseInt(page, 10) : 1
        };

        const history = await historyService.getFeedbackHistory({ sessionId: session_id }, options);

        return res.status(httpStatus.OK).json(formatResponse(
            true,
            history.data,
            '세션 피드백 이력을 성공적으로 조회했습니다.',
            history.meta
        ));
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getFeedbackHistory,
    getSessionFeedbacks
};
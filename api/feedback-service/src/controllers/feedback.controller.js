const httpStatus = require('http-status');
const feedbackService = require('../services/feedback.service');
const { formatResponse } = require('../utils/responseFormatter');

/**
 * 실시간 피드백 생성
 * 분석 결과에 기반하여 적절한 햅틱 피드백을 결정
 */
const generateFeedback = async (req, res, next) => {
    try {
        const { session_id, context, device_id } = req.body;
        const userId = req.user.id;

        const feedback = await feedbackService.generateFeedback({
            userId,
            sessionId: session_id,
            context,
            deviceId: device_id,
            timestamp: new Date()
        });

        return res.status(httpStatus.OK).json(formatResponse(
            true,
            { feedback },
            '피드백이 생성되었습니다.'
        ));
    } catch (error) {
        next(error);
    }
};

/**
 * 피드백 수신 확인
 */
const acknowledgeFeedback = async (req, res, next) => {
    try {
        const { feedback_id } = req.params;

        await feedbackService.acknowledgeFeedback(feedback_id, {
            receivedAt: new Date()
        });

        return res.status(httpStatus.OK).json(formatResponse(
            true,
            null,
            '피드백 수신이 확인되었습니다.'
        ));
    } catch (error) {
        next(error);
    }
};

module.exports = {
    generateFeedback,
    acknowledgeFeedback
};
const { validationResult } = require('express-validator');
const settingsService = require('../services/settings.service');
const logger = require('../utils/logger');

/**
 * 설정 조회
 * @param {Object} req - 요청 객체
 * @param {Object} res - 응답 객체
 * @param {Function} next - 다음 미들웨어 함수
 */
const getSettings = async (req, res, next) => {
    try {
        const userId = req.user.id;

        const settings = await settingsService.getSettings(userId);

        return res.status(200).json({
            success: true,
            data: settings
        });
    } catch (error) {
        logger.error('Error in getSettings controller:', error);
        next(error);
    }
};

/**
 * 설정 업데이트
 * @param {Object} req - 요청 객체
 * @param {Object} res - 응답 객체
 * @param {Function} next - 다음 미들웨어 함수
 */
const updateSettings = async (req, res, next) => {
    try {
        // 유효성 검사 결과 확인
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(422).json({
                success: false,
                message: '유효성 검사 오류가 발생했습니다.',
                errors: errors.array().map(error => ({
                    code: 'validation_error',
                    field: error.param,
                    message: error.msg
                }))
            });
        }

        const userId = req.user.id;
        const settingsData = req.body;

        const updatedSettings = await settingsService.updateSettings(userId, settingsData);

        return res.status(200).json({
            success: true,
            data: updatedSettings,
            message: '설정이 업데이트되었습니다.'
        });
    } catch (error) {
        logger.error('Error in updateSettings controller:', error);
        next(error);
    }
};

module.exports = {
    getSettings,
    updateSettings
};
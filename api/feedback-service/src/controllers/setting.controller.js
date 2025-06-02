const httpStatus = require('http-status');
const settingService = require('../services/setting.service');
const { formatResponse } = require('../utils/responseFormatter');

/**
 * 사용자 피드백 설정 조회
 */
const getUserSettings = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const settings = await settingService.getUserSettings(userId);

        return res.status(httpStatus.OK).json(formatResponse(
            true,
            settings,
            '피드백 설정을 성공적으로 조회했습니다.'
        ));
    } catch (error) {
        next(error);
    }
};

/**
 * 사용자 피드백 설정 업데이트
 */
const updateUserSettings = async (req, res, next) => {
    try {
        const userId = req.user.id;
        const updatedSettings = await settingService.updateUserSettings(userId, req.body);

        return res.status(httpStatus.OK).json(formatResponse(
            true,
            updatedSettings,
            '피드백 설정이 성공적으로 업데이트되었습니다.'
        ));
    } catch (error) {
        next(error);
    }
};

module.exports = {
    getUserSettings,
    updateUserSettings
};
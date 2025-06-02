const UserFeedbackSetting = require('../models/userSetting.model');
const logger = require('../utils/logger');

/**
 * 사용자 피드백 설정 조회
 * 설정이 없으면 기본값으로 생성
 */
const getUserSettings = async (userId) => {
    try {
        let settings = await UserFeedbackSetting.findByPk(userId);

        // 설정이 없으면 기본값으로 생성
        if (!settings) {
            settings = await UserFeedbackSetting.create({
                user_id: userId,
                haptic_strength: 5,
                active_patterns: ['S1', 'L1', 'F1', 'R1', 'S2', 'R2', 'L3', 'F2'],
                priority_threshold: 'medium',
                minimum_interval_seconds: 10,
                feedback_frequency: 'medium',
                mode_settings: {
                    dating: {
                        active_patterns: ['S1', 'L1', 'F1', 'R1'],
                        priority_threshold: 'low'
                    },
                    interview: {
                        active_patterns: ['S1', 'S2', 'F4', 'L3'],
                        priority_threshold: 'medium'
                    }
                },
                updated_at: new Date()
            });

            logger.info(`사용자 피드백 설정 기본값 생성 성공: ${userId}`, {
                userId,
                hapticStrength: settings.haptic_strength,
                activePatterns: settings.active_patterns,
                priorityThreshold: settings.priority_threshold,
                minimumInterval: settings.minimum_interval_seconds
            });
        } else {
            logger.debug(`사용자 피드백 설정 조회 성공: ${userId}`, {
                userId,
                hapticStrength: settings.haptic_strength,
                feedbackFrequency: settings.feedback_frequency
            });
        }

        return settings;
    } catch (error) {
        logger.error(`Error in getUserSettings for userId ${userId}:`, error);
        throw error;
    }
};

/**
 * 사용자 피드백 설정 업데이트
 */
const updateUserSettings = async (userId, updateData) => {
    try {
        // 먼저 사용자 설정 조회 (없으면 생성)
        let settings = await getUserSettings(userId);

        // 설정 업데이트
        settings = await settings.update({
            ...updateData,
            updated_at: new Date()
        });

        logger.info(`사용자 피드백 설정 업데이트 성공: ${userId}`, {
            userId,
            updatedFields: Object.keys(updateData),
            newHapticStrength: settings.haptic_strength,
            newFeedbackFrequency: settings.feedback_frequency
        });

        return settings;
    } catch (error) {
        logger.error(`Error in updateUserSettings for userId ${userId}:`, error);
        throw error;
    }
};

module.exports = {
    getUserSettings,
    updateUserSettings
};
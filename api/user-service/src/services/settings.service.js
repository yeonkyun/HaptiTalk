const Settings = require('../models/settings.model');
const { redisClient } = require('../config/redis');
const logger = require('../utils/logger');

class SettingsService {
    /**
     * 사용자 설정 조회
     * @param {string} userId - 사용자 ID
     * @returns {Promise<Object>} - 설정 정보
     */
    async getSettings(userId) {
        try {
            // Redis 캐시 확인
            const cachedSettings = await redisClient.get(`user:settings:${userId}`);
            if (cachedSettings) {
                return JSON.parse(cachedSettings);
            }

            // 데이터베이스에서 조회
            const settings = await Settings.findByPk(userId);
            if (!settings) {
                // 설정이 없는 경우 기본 설정 생성
                return this.createDefaultSettings(userId);
            }

            // Redis에 캐싱 (1시간)
            await redisClient.set(
                `user:settings:${userId}`,
                JSON.stringify(settings.toJSON()),
                'EX', 3600
            );

            return settings.toJSON();
        } catch (error) {
            logger.error('Error fetching settings:', error);
            throw error;
        }
    }

    /**
     * 기본 설정 생성
     * @param {string} userId - 사용자 ID
     * @returns {Promise<Object>} - 생성된 설정
     */
    async createDefaultSettings(userId) {
        try {
            const settings = await Settings.create({
                id: userId
            });
            return settings.toJSON();
        } catch (error) {
            logger.error('Error creating default settings:', error);
            throw error;
        }
    }

    /**
     * 설정 업데이트
     * @param {string} userId - 사용자 ID
     * @param {Object} settingsData - 업데이트할 설정 데이터
     * @returns {Promise<Object>} - 업데이트된 설정
     */
    async updateSettings(userId, settingsData) {
        try {
            // 설정 존재 확인
            let settings = await Settings.findByPk(userId);

            if (!settings) {
                // 설정이 없으면 생성
                settings = await this.createDefaultSettings(userId);
            }

            // 설정 업데이트
            await settings.update(settingsData);

            // Redis 캐시 업데이트
            await redisClient.set(
                `user:settings:${userId}`,
                JSON.stringify(settings.toJSON()),
                'EX', 3600
            );

            // 피드백 서비스와 공유하는 설정 업데이트
            if (settingsData.haptic_strength !== undefined) {
                await redisClient.hset(
                    `feedback:user:${userId}`,
                    'haptic_strength',
                    settingsData.haptic_strength
                );
            }

            return settings.toJSON();
        } catch (error) {
            logger.error('Error updating settings:', error);
            throw error;
        }
    }
}

module.exports = new SettingsService();
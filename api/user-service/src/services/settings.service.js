const Settings = require('../models/settings.model');
const { redisClient } = require('../config/redis');
const logger = require('../utils/logger');
const kafkaService = require('./kafka.service');

class SettingsService {
    /**
     * 사용자 설정 조회
     * @param {string} userId - 사용자 ID
     * @returns {Promise<Object>} - 사용자 설정
     */
    async getSettings(userId) {
        try {
            // Redis에서 캐시된 설정 확인
            const cachedSettings = await redisClient.get(`user:settings:${userId}`);
            if (cachedSettings) {
                logger.debug(`설정 캐시 조회 성공: ${userId}`);
                return JSON.parse(cachedSettings);
            }

            // 데이터베이스에서 설정 조회
            const settings = await Settings.findByPk(userId);
            if (!settings) {
                logger.warn(`설정 조회 실패 - 존재하지 않는 사용자: ${userId}`);
                throw new Error('Settings not found');
            }

            logger.info(`설정 조회 성공: ${userId}`);

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

            logger.info(`기본 설정 생성 성공: ${userId}`);

            // Kafka 이벤트 발행
            await kafkaService.publishUserActivity(userId, 'SETTINGS_CREATED', {
                type: 'default'
            });

            // Redis에 캐싱 (1시간)
            await redisClient.set(
                `user:settings:${userId}`,
                JSON.stringify(settings.toJSON()),
                'EX', 3600
            );

            return settings.toJSON();
        } catch (error) {
            logger.error('Error creating default settings:', error);
            throw error;
        }
    }

    /**
     * 사용자 설정 업데이트
     * @param {string} userId - 사용자 ID
     * @param {Object} settingsData - 업데이트할 설정 데이터
     * @returns {Promise<Object>} - 업데이트된 설정
     */
    async updateSettings(userId, settingsData) {
        try {
            const settings = await Settings.findByPk(userId);
            if (!settings) {
                logger.warn(`설정 업데이트 실패 - 존재하지 않는 사용자: ${userId}`);
                throw new Error('Settings not found');
            }

            const updatedSettings = await settings.update(settingsData);

            logger.info(`설정 업데이트 성공: ${userId}`, {
                updatedFields: Object.keys(settingsData),
                userId
            });

            // Kafka 이벤트 발행
            await kafkaService.publishUserActivity(userId, 'SETTINGS_UPDATED', {
                updatedFields: Object.keys(settingsData)
            });

            // Redis 캐시 업데이트
            await redisClient.set(
                `user:settings:${userId}`,
                JSON.stringify(updatedSettings.toJSON()),
                'EX', 3600
            );

            return updatedSettings.toJSON();
        } catch (error) {
            logger.error('Error updating settings:', error);
            throw error;
        }
    }

    /**
     * 설정 삭제
     * @param {string} userId - 사용자 ID
     * @returns {Promise<boolean>} - 삭제 성공 여부
     */
    async deleteSettings(userId) {
        try {
            const settings = await Settings.findByPk(userId);
            if (!settings) {
                logger.warn(`설정 삭제 실패 - 존재하지 않는 사용자: ${userId}`);
                return false;
            }

            await settings.destroy();

            logger.info(`설정 삭제 성공: ${userId}`);

            // Kafka 이벤트 발행
            await kafkaService.publishUserActivity(userId, 'SETTINGS_DELETED', {});

            // Redis에서 캐시 제거
            await redisClient.del(`user:settings:${userId}`);

            return true;
        } catch (error) {
            logger.error('Error deleting settings:', error);
            throw error;
        }
    }
}

module.exports = new SettingsService();
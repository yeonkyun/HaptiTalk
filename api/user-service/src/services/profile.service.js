const Profile = require('../models/profile.model');
const {redisClient} = require('../config/redis');
const logger = require('../utils/logger');
const kafkaService = require('./kafka.service');

class ProfileService {
    /**
     * 사용자 프로필 조회
     * @param {string} userId - 사용자 ID
     * @returns {Promise<Object>} - 프로필 정보
     */
    async getProfile(userId) {
        try {
            // Redis 캐시 확인
            const cachedProfile = await redisClient.get(`user:profile:${userId}`);
            if (cachedProfile) {
                return JSON.parse(cachedProfile);
            }

            // 데이터베이스에서 조회
            const profile = await Profile.findByPk(userId);
            if (!profile) {
                logger.warn(`프로필 조회 실패 - 존재하지 않는 사용자: ${userId}`);
                throw new Error('Profile not found');
            }

            logger.info(`프로필 조회 성공: ${userId}`);

            // Redis에 캐싱 (1시간)
            await redisClient.set(
                `user:profile:${userId}`,
                JSON.stringify(profile.toJSON()),
                'EX', 3600
            );

            return profile.toJSON();
        } catch (error) {
            logger.error('Error fetching profile:', error);
            throw error;
        }
    }

    /**
     * 프로필 업데이트
     * @param {string} userId - 사용자 ID
     * @param {Object} updateData - 업데이트할 데이터
     * @returns {Promise<Object>} - 업데이트된 프로필
     */
    async updateProfile(userId, updateData) {
        try {
            const profile = await Profile.findByPk(userId);
            if (!profile) {
                logger.warn(`프로필 업데이트 실패 - 존재하지 않는 사용자: ${userId}`);
                throw new Error('Profile not found');
            }

            const updatedProfile = await profile.update(updateData);

            logger.info(`프로필 업데이트 성공: ${userId}`, {
                updatedFields: Object.keys(updateData),
                userId
            });

            // Kafka 이벤트 발행
            await kafkaService.publishUserActivity(userId, 'PROFILE_UPDATED', {
                updatedFields: Object.keys(updateData)
            });

            // Redis 캐시 업데이트
            await redisClient.set(
                `user:profile:${userId}`,
                JSON.stringify(updatedProfile.toJSON()),
                'EX', 3600
            );

            return updatedProfile.toJSON();
        } catch (error) {
            logger.error('Error updating profile:', error);
            throw error;
        }
    }

    /**
     * 기본 프로필 생성
     * @param {string} userId - 사용자 ID
     * @returns {Promise<Object>} - 생성된 프로필
     */
    async createDefaultProfile(userId) {
        try {
            const profile = await Profile.create({
                id: userId
            });

            logger.info(`기본 프로필 생성 성공: ${userId}`);

            // Kafka 이벤트 발행
            await kafkaService.publishUserActivity(userId, 'PROFILE_CREATED', {
                type: 'default'
            });

            // Redis에 캐싱 (1시간)
            await redisClient.set(
                `user:profile:${userId}`,
                JSON.stringify(profile.toJSON()),
                'EX', 3600
            );

            return profile.toJSON();
        } catch (error) {
            logger.error('Error creating default profile:', error);
            throw error;
        }
    }

    /**
     * 프로필 삭제
     * @param {string} userId - 사용자 ID
     * @returns {Promise<boolean>} - 삭제 성공 여부
     */
    async deleteProfile(userId) {
        try {
            const profile = await Profile.findByPk(userId);
            if (!profile) {
                logger.warn(`프로필 삭제 실패 - 존재하지 않는 사용자: ${userId}`);
                return false;
            }

            await profile.destroy();

            logger.info(`프로필 삭제 성공: ${userId}`);

            // Kafka 이벤트 발행
            await kafkaService.publishUserActivity(userId, 'PROFILE_DELETED', {});

            // Redis에서 캐시 제거
            await redisClient.del(`user:profile:${userId}`);

            return true;
        } catch (error) {
            logger.error('Error deleting profile:', error);
            throw error;
        }
    }
}

module.exports = new ProfileService();
const Profile = require('../models/profile.model');
const {redisClient} = require('../config/redis');
const logger = require('../utils/logger');

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
                // 프로필이 없는 경우 기본 프로필 생성
                return this.createDefaultProfile(userId);
            }

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
     * 기본 프로필 생성
     * @param {string} userId - 사용자 ID
     * @returns {Promise<Object>} - 생성된 프로필
     */
    async createDefaultProfile(userId) {
        try {
            const profile = await Profile.create({
                id: userId
            });
            return profile.toJSON();
        } catch (error) {
            logger.error('Error creating default profile:', error);
            throw error;
        }
    }

    /**
     * 프로필 업데이트
     * @param {string} userId - 사용자 ID
     * @param {Object} profileData - 업데이트할 프로필 데이터
     * @returns {Promise<Object>} - 업데이트된 프로필
     */
    async updateProfile(userId, profileData) {
        try {
            // 프로필 존재 확인
            let profile = await Profile.findByPk(userId);

            if (!profile) {
                // 프로필이 없으면 생성
                profile = await this.createDefaultProfile(userId);
            }

            // 프로필 업데이트
            await profile.update(profileData);

            // Redis 캐시 업데이트
            await redisClient.set(
                `user:profile:${userId}`,
                JSON.stringify(profile.toJSON()),
                'EX', 3600
            );

            return profile.toJSON();
        } catch (error) {
            logger.error('Error updating profile:', error);
            throw error;
        }
    }
}

module.exports = new ProfileService();
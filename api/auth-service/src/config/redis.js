const {createClient} = require('redis');
const logger = require('../utils/logger');

const redisClient = createClient({
    url: `redis://${process.env.REDIS_HOST || 'redis'}:${process.env.REDIS_PORT || 6379}`,
    password: process.env.REDIS_PASSWORD
});

redisClient.on('error', (err) => {
    logger.error('Redis Client Error:', err);
});

// Define Redis key prefixes
const REDIS_KEYS = {
    ACCESS_TOKEN_BLACKLIST: 'auth:blacklist:access:',
    REFRESH_TOKEN: 'auth:refresh:',
    SERVICE_TOKEN: 'auth:service:',
    VERIFICATION_TOKEN: 'auth:verification:',
    RESET_TOKEN: 'auth:reset:',
    ACTIVE_SESSIONS: 'auth:sessions:user:',
    RATE_LIMIT: 'auth:rate-limit:',
    TOKEN_METADATA: 'auth:token:metadata:'
};

// Redis helper functions
const redisHelpers = {
    /**
     * Add access token to blacklist
     * @param {string} token - JWT token
     * @param {number} exp - Token expiration time in seconds
     */
    blacklistToken: async (token, exp) => {
        const now = Math.floor(Date.now() / 1000);
        const ttl = exp - now;
        if (ttl > 0) {
            await redisClient.set(`${REDIS_KEYS.ACCESS_TOKEN_BLACKLIST}${token}`, '1', {
                EX: ttl
            });
        }
    },

    /**
     * Check if token is blacklisted
     * @param {string} token - JWT token
     * @returns {Promise<boolean>} - True if token is blacklisted
     */
    isTokenBlacklisted: async (token) => {
        const result = await redisClient.get(`${REDIS_KEYS.ACCESS_TOKEN_BLACKLIST}${token}`);
        return result !== null;
    },

    /**
     * Store refresh token
     * @param {string} tokenId - Unique token ID
     * @param {string} userId - User ID
     * @param {number} ttl - Time to live in seconds
     */
    storeRefreshToken: async (tokenId, userId, ttl) => {
        await redisClient.set(`${REDIS_KEYS.REFRESH_TOKEN}${tokenId}`, userId, {
            EX: ttl
        });
    },

    /**
     * Get user ID from refresh token
     * @param {string} tokenId - Unique token ID
     * @returns {Promise<string|null>} - User ID or null
     */
    getUserIdFromRefreshToken: async (tokenId) => {
        return await redisClient.get(`${REDIS_KEYS.REFRESH_TOKEN}${tokenId}`);
    },

    /**
     * Remove refresh token
     * @param {string} tokenId - Unique token ID
     */
    removeRefreshToken: async (tokenId) => {
        await redisClient.del(`${REDIS_KEYS.REFRESH_TOKEN}${tokenId}`);
    },

    /**
     * 서비스 토큰 저장
     * @param {string} tokenId - 토큰 ID
     * @param {string} serviceId - 서비스 ID
     * @param {number} ttl - 만료 시간(초)
     */
    storeServiceToken: async (tokenId, serviceId, ttl) => {
        await redisClient.set(`${REDIS_KEYS.SERVICE_TOKEN}${tokenId}`, serviceId, {
            EX: ttl
        });
    },

    /**
     * 서비스 ID 조회
     * @param {string} tokenId - 토큰 ID
     * @returns {Promise<string|null>} - 서비스 ID 또는 null
     */
    getServiceIdFromToken: async (tokenId) => {
        return await redisClient.get(`${REDIS_KEYS.SERVICE_TOKEN}${tokenId}`);
    },

    /**
     * 서비스 토큰 삭제
     * @param {string} tokenId - 토큰 ID
     */
    removeServiceToken: async (tokenId) => {
        await redisClient.del(`${REDIS_KEYS.SERVICE_TOKEN}${tokenId}`);
    },

    /**
     * Store token metadata for refresh optimization
     * @param {string} token - The access token
     * @param {Object} metadata - Token metadata including userId and refreshTokenId
     */
    storeTokenMetadata: async (token, metadata) => {
        try {
            // Store with TTL based on token expiry
            const ttl = metadata.expiresAt - Math.floor(Date.now() / 1000);
            if (ttl > 0) {
                await redisClient.set(
                    `${REDIS_KEYS.TOKEN_METADATA}${token}`, 
                    JSON.stringify(metadata), 
                    { EX: ttl + 60 } // Add a small buffer to ensure metadata outlives token
                );
            }
        } catch (error) {
            logger.error('Error storing token metadata:', error);
        }
    },

    /**
     * Get token metadata
     * @param {string} token - The access token
     * @returns {Promise<Object|null>} - Token metadata or null
     */
    getTokenMetadata: async (token) => {
        try {
            const metadata = await redisClient.get(`${REDIS_KEYS.TOKEN_METADATA}${token}`);
            return metadata ? JSON.parse(metadata) : null;
        } catch (error) {
            logger.error('Error getting token metadata:', error);
            return null;
        }
    },

    /**
     * Remove token metadata
     * @param {string} token - The access token
     */
    removeTokenMetadata: async (token) => {
        try {
            await redisClient.del(`${REDIS_KEYS.TOKEN_METADATA}${token}`);
        } catch (error) {
            logger.error('Error removing token metadata:', error);
        }
    }
};

module.exports = {
    redisClient,
    REDIS_KEYS,
    redisHelpers
};
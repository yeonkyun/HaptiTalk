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
    VERIFICATION_TOKEN: 'auth:verification:',
    RESET_TOKEN: 'auth:reset:',
    ACTIVE_SESSIONS: 'auth:sessions:user:',
    RATE_LIMIT: 'auth:rate-limit:'
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
    }
};

module.exports = {
    redisClient,
    REDIS_KEYS,
    redisHelpers
};
const Redis = require('ioredis');
const logger = require('../utils/logger');

const redisClient = new Redis({
    host: process.env.REDIS_HOST || 'redis',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD,
    db: 0,
    retryStrategy: (times) => {
        const delay = Math.min(times * 50, 2000);
        logger.info(`Redis reconnecting... attempt ${times}, delay ${delay}ms`);
        return delay;
    }
});

redisClient.on('connect', () => {
    logger.info('Redis client connected');
});

redisClient.on('error', (err) => {
    logger.error(`Redis client error: ${err.message}`);
});

/**
 * 캐시에서 데이터 조회
 */
const getCache = async (key) => {
    try {
        const data = await redisClient.get(key);
        return data ? JSON.parse(data) : null;
    } catch (error) {
        logger.error(`Error getting cache for key ${key}: ${error.message}`);
        return null;
    }
};

/**
 * 캐시에 데이터 저장
 */
const setCache = async (key, data, ttl = 3600) => {
    try {
        const serialized = JSON.stringify(data);
        if (ttl) {
            await redisClient.setex(key, ttl, serialized);
        } else {
            await redisClient.set(key, serialized);
        }
        return true;
    } catch (error) {
        logger.error(`Error setting cache for key ${key}: ${error.message}`);
        return false;
    }
};

/**
 * 캐시 삭제
 */
const deleteCache = async (key) => {
    try {
        await redisClient.del(key);
        return true;
    } catch (error) {
        logger.error(`Error deleting cache for key ${key}: ${error.message}`);
        return false;
    }
};

/**
 * 패턴으로 캐시 키 삭제
 */
const deleteCachePattern = async (pattern) => {
    try {
        const keys = await redisClient.keys(pattern);
        if (keys.length > 0) {
            await redisClient.del(keys);
        }
        return true;
    } catch (error) {
        logger.error(`Error deleting cache pattern ${pattern}: ${error.message}`);
        return false;
    }
};

module.exports = {
    redisClient,
    getCache,
    setCache,
    deleteCache,
    deleteCachePattern
};
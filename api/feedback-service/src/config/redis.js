const Redis = require('ioredis');
const logger = require('../utils/logger');

// Redis 클라이언트 설정
const redisClient = new Redis({
    host: process.env.REDIS_HOST || 'redis',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD,
    retryStrategy: (times) => {
        const delay = Math.min(times * 50, 2000);
        return delay;
    },
    maxRetriesPerRequest: 3
});

// 연결 이벤트 핸들러
redisClient.on('connect', () => {
    logger.info('Redis connection established');
});

redisClient.on('error', (err) => {
    logger.error('Redis connection error:', err);
});

redisClient.on('ready', () => {
    logger.info('Redis client ready');
});

// Redis Pub/Sub 클라이언트 (별도 인스턴스 사용)
const redisPubSub = new Redis({
    host: process.env.REDIS_HOST || 'redis',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD,
    retryStrategy: (times) => {
        const delay = Math.min(times * 50, 2000);
        return delay;
    }
});

// 헬퍼 함수
// 키-값 설정 (선택적 만료 시간)
const setKey = async (key, value, expirySeconds) => {
    try {
        if (expirySeconds) {
            await redisClient.set(key, typeof value === 'object' ? JSON.stringify(value) : value, 'EX', expirySeconds);
        } else {
            await redisClient.set(key, typeof value === 'object' ? JSON.stringify(value) : value);
        }
        return true;
    } catch (error) {
        logger.error(`Error setting Redis key ${key}:`, error);
        throw error;
    }
};

// 키 값 조회 (JSON 파싱 포함)
const getKey = async (key, parseJson = false) => {
    try {
        const value = await redisClient.get(key);
        if (!value) return null;
        return parseJson ? JSON.parse(value) : value;
    } catch (error) {
        logger.error(`Error getting Redis key ${key}:`, error);
        throw error;
    }
};

// 키 삭제
const deleteKey = async (key) => {
    try {
        await redisClient.del(key);
        return true;
    } catch (error) {
        logger.error(`Error deleting Redis key ${key}:`, error);
        throw error;
    }
};

// 키 존재 여부 확인
const exists = async (key) => {
    try {
        return await redisClient.exists(key);
    } catch (error) {
        logger.error(`Error checking Redis key existence ${key}:`, error);
        throw error;
    }
};

// Pub/Sub 메시지 발행
const publish = async (channel, message) => {
    try {
        await redisPubSub.publish(channel, typeof message === 'object' ? JSON.stringify(message) : message);
        return true;
    } catch (error) {
        logger.error(`Error publishing to Redis channel ${channel}:`, error);
        throw error;
    }
};

// Pub/Sub 채널 구독
const subscribe = (channel, callback) => {
    redisPubSub.subscribe(channel, (err) => {
        if (err) {
            logger.error(`Error subscribing to Redis channel ${channel}:`, err);
            throw err;
        }
        logger.info(`Subscribed to Redis channel: ${channel}`);
    });

    redisPubSub.on('message', (subscribedChannel, message) => {
        if (subscribedChannel === channel) {
            try {
                const parsedMessage = JSON.parse(message);
                callback(parsedMessage);
            } catch (e) {
                callback(message);
            }
        }
    });
};

module.exports = {
    redisClient,
    redisPubSub,
    setKey,
    getKey,
    deleteKey,
    exists,
    publish,
    subscribe
};
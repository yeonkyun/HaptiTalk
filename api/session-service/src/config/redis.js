const Redis = require('ioredis');
const logger = require('../utils/logger');

// Redis 연결 설정
const redisClient = new Redis({
    host: process.env.REDIS_HOST || 'redis',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD || '',
    db: parseInt(process.env.REDIS_SESSION_DB || '1', 10), // 세션 서비스 전용 DB 인덱스
    retryStrategy: (times) => {
        const delay = Math.min(times * 100, 3000);
        return delay;
    },
    maxRetriesPerRequest: 3
});

// Redis Pub/Sub 채널용 별도 인스턴스 생성 (연결 분리)
const redisPubSub = new Redis({
    host: process.env.REDIS_HOST || 'redis',
    port: parseInt(process.env.REDIS_PORT || '6379', 10),
    password: process.env.REDIS_PASSWORD || '',
    db: parseInt(process.env.REDIS_SESSION_DB || '1', 10)
});

// Redis 이벤트 리스너 설정
redisClient.on('connect', () => {
    logger.info('Redis client connected');
});

redisClient.on('error', (err) => {
    logger.error('Redis client error:', err);
});

// Redis 채널 정의
const CHANNELS = {
    SESSION_CREATED: 'session:created',
    SESSION_UPDATED: 'session:updated',
    SESSION_ENDED: 'session:ended',
    FEEDBACK_CREATED: 'feedback:created'
};

// Redis 유틸리티 함수
const redisUtils = {
    // 세션 관련 키 생성 함수
    keys: {
        sessionConfig: (sessionId) => `session:${sessionId}:config`,
        sessionStatus: (sessionId) => `session:${sessionId}:status`,
        sessionTimer: (sessionId) => `session:${sessionId}:timer`,
        userSessions: (userId) => `user:${userId}:sessions`
    },

    // 키-값 저장 함수 (TTL 옵션 포함)
    async set(key, value, ttlSeconds = null) {
        try {
            if (ttlSeconds) {
                await redisClient.set(key, JSON.stringify(value), 'EX', ttlSeconds);
            } else {
                await redisClient.set(key, JSON.stringify(value));
            }
            return true;
        } catch (error) {
            logger.error(`Redis SET error for key ${key}:`, error);
            return false;
        }
    },

    // 값 조회 함수
    async get(key) {
        try {
            const value = await redisClient.get(key);
            return value ? JSON.parse(value) : null;
        } catch (error) {
            logger.error(`Redis GET error for key ${key}:`, error);
            return null;
        }
    },

    // 키 존재 여부 확인 함수
    async exists(key) {
        try {
            return await redisClient.exists(key) === 1;
        } catch (error) {
            logger.error(`Redis EXISTS error for key ${key}:`, error);
            return false;
        }
    },

    // 키 삭제 함수
    async delete(key) {
        try {
            await redisClient.del(key);
            return true;
        } catch (error) {
            logger.error(`Redis DELETE error for key ${key}:`, error);
            return false;
        }
    },

    // 리스트에 항목 추가 함수
    async addToList(key, value) {
        try {
            await redisClient.rpush(key, JSON.stringify(value));
            return true;
        } catch (error) {
            logger.error(`Redis RPUSH error for key ${key}:`, error);
            return false;
        }
    },

    // 리스트 조회 함수
    async getList(key) {
        try {
            const list = await redisClient.lrange(key, 0, -1);
            return list.map(item => JSON.parse(item));
        } catch (error) {
            logger.error(`Redis LRANGE error for key ${key}:`, error);
            return [];
        }
    },

    // 이벤트 발행 함수
    async publish(channel, message) {
        try {
            await redisPubSub.publish(channel, JSON.stringify(message));
            return true;
        } catch (error) {
            logger.error(`Redis PUBLISH error for channel ${channel}:`, error);
            return false;
        }
    },

    // 이벤트 구독 함수
    subscribe(channel, callback) {
        redisPubSub.subscribe(channel, (err) => {
            if (err) {
                logger.error(`Redis SUBSCRIBE error for channel ${channel}:`, err);
            } else {
                logger.info(`Subscribed to channel: ${channel}`);
            }
        });

        redisPubSub.on('message', (subscribedChannel, message) => {
            if (subscribedChannel === channel) {
                try {
                    const parsedMessage = JSON.parse(message);
                    callback(parsedMessage);
                } catch (error) {
                    logger.error(`Error parsing message from channel ${channel}:`, error);
                }
            }
        });
    }
};

module.exports = {
    redisClient,
    redisPubSub,
    CHANNELS,
    redisUtils
};
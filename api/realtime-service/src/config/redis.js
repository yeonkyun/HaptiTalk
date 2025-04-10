const Redis = require('ioredis');
const logger = require('../utils/logger');

const createRedisClient = () => {
  const client = new Redis({
    host: process.env.REDIS_HOST || 'localhost',
    port: parseInt(process.env.REDIS_PORT) || 6379,
    password: process.env.REDIS_PASSWORD,
    maxRetriesPerRequest: null,
    enableReadyCheck: true,
    retryStrategy: (times) => {
      const delay = Math.min(times * 50, 2000);
      return delay;
    },
    reconnectOnError: (err) => {
      const targetError = 'READONLY';
      if (err.message.includes(targetError)) {
        return true;
      }
      return false;
    }
  });

  client.on('connect', () => {
    logger.info('Redis 클라이언트가 연결되었습니다');
  });

  client.on('error', (err) => {
    logger.error(`Redis 클라이언트 오류: ${err.message}`);
  });

  client.on('ready', () => {
    logger.info('Redis 클라이언트가 준비되었습니다');
  });

  return client;
};

module.exports = { createRedisClient };
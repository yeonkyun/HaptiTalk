const { Pool } = require('pg');
const redis = require('redis');

// 테스트용 데이터베이스 설정
const testDbConfig = {
    user: process.env.POSTGRES_USER || 'postgres',
    password: process.env.POSTGRES_PASSWORD || 'postgres',
    host: process.env.POSTGRES_HOST || 'localhost',
    port: process.env.POSTGRES_PORT || 5432,
    database: process.env.POSTGRES_DB || 'haptitalk_test'
};

// 테스트용 Redis 설정
const testRedisConfig = {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || 'redis'
};

// 테스트 데이터베이스 연결
const pool = new Pool(testDbConfig);

// 테스트 Redis 클라이언트
const redisClient = redis.createClient(testRedisConfig);

// 테스트 전 데이터베이스 초기화
async function setupTestDatabase() {
    try {
        // 테스트 데이터베이스 연결
        await pool.connect();

        // 테이블 초기화
        await pool.query(`
            TRUNCATE TABLE users CASCADE;
            TRUNCATE TABLE tokens CASCADE;
        `);

        // 기본 테스트 데이터 삽입
        await pool.query(`
            INSERT INTO users (email, password_hash, is_verified, verification_token)
            VALUES ('test@example.com', '$2a$10$examplehash', false, 'verification-token');
        `);
    } catch (error) {
        console.error('Error setting up test database:', error);
        throw error;
    }
}

// 테스트 후 데이터베이스 정리
async function cleanupTestDatabase() {
    try {
        await pool.query(`
            TRUNCATE TABLE users CASCADE;
            TRUNCATE TABLE tokens CASCADE;
        `);
        await pool.end();
    } catch (error) {
        console.error('Error cleaning up test database:', error);
        throw error;
    }
}

// Redis 초기화
async function setupRedis() {
    try {
        await redisClient.connect();
        await redisClient.flushAll();
    } catch (error) {
        console.error('Error setting up Redis:', error);
        throw error;
    }
}

// Redis 정리
async function cleanupRedis() {
    try {
        await redisClient.flushAll();
        await redisClient.quit();
    } catch (error) {
        console.error('Error cleaning up Redis:', error);
        throw error;
    }
}

module.exports = {
    pool,
    redisClient,
    setupTestDatabase,
    cleanupTestDatabase,
    setupRedis,
    cleanupRedis
}; 
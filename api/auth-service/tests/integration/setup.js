const { Pool } = require('pg');
const redis = require('redis');

// 테스트용 데이터베이스 설정
const testDbConfig = {
    user: process.env.POSTGRES_USER || 'postgres',
    password: process.env.POSTGRES_PASSWORD || 'postgres',
    host: process.env.POSTGRES_HOST || 'localhost',
    port: process.env.POSTGRES_PORT || 5432,
    database: process.env.POSTGRES_DB || 'haptitalk_test',
    connectionTimeoutMillis: 5000
};

// 테스트용 Redis 설정
const testRedisConfig = {
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD || 'redis',
    username: process.env.REDIS_USERNAME || '',
    socket: {
      connectTimeout: 10000, // 10초
      reconnectStrategy: 3000 // 3초마다 재시도
    }
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

        // 스키마 및 테이블 생성 확인
        await pool.query(`
            CREATE SCHEMA IF NOT EXISTS auth;
            
            CREATE TABLE IF NOT EXISTS auth.users (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                email VARCHAR(255) NOT NULL UNIQUE,
                password_hash VARCHAR(255) NOT NULL,
                salt VARCHAR(255) NOT NULL,
                last_login TIMESTAMP,
                is_active BOOLEAN DEFAULT TRUE NOT NULL,
                is_verified BOOLEAN DEFAULT FALSE NOT NULL,
                verification_token VARCHAR(255),
                reset_token VARCHAR(255),
                reset_token_expires_at TIMESTAMP,
                login_attempts INTEGER DEFAULT 0 NOT NULL,
                locked_until TIMESTAMP,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
            
            CREATE TABLE IF NOT EXISTS auth.tokens (
                id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
                token VARCHAR(255) NOT NULL,
                type VARCHAR(50) NOT NULL,
                expires_at TIMESTAMP NOT NULL,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            );
        `);

        // 테이블 초기화 (있을 경우에만)
        try {
            await pool.query(`
                TRUNCATE TABLE auth.users CASCADE;
                TRUNCATE TABLE auth.tokens CASCADE;
            `);
        } catch (truncateError) {
            console.warn('Tables might not exist yet, continuing with setup:', truncateError.message);
        }

        // 기본 테스트 데이터 삽입
        await pool.query(`
            INSERT INTO auth.users (id, email, password_hash, salt, is_verified, verification_token, created_at, updated_at)
            VALUES (gen_random_uuid(), 'test@example.com', '$2a$10$examplehash', '$2a$10$examplesalt', false, 'verification-token', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);
        `);
    } catch (error) {
        console.error('Error setting up test database:', error);
        // 테스트는 계속 진행할 수 있도록 에러를 throw하지 않음
    }
}

// 테스트 후 데이터베이스 정리
async function cleanupTestDatabase() {
    try {
        try {
            await pool.query(`
                TRUNCATE TABLE auth.users CASCADE;
                TRUNCATE TABLE auth.tokens CASCADE;
            `);
        } catch (truncateError) {
            console.warn('Tables might not exist, skipping truncate:', truncateError.message);
        }
        
        // pool.end()를 확실히 실행하고 대기
        await pool.end();
        console.log('Database pool closed successfully');
    } catch (error) {
        console.error('Error cleaning up test database:', error);
        // 에러가 발생해도 pool을 강제 종료
        try {
            pool.end();
        } catch (endError) {
            console.error('Failed to forcefully close pool:', endError);
        }
    }
}

// Redis 초기화
async function setupRedis() {
    try {
        // Redis 클라이언트가 연결되어 있지 않으면 연결 시도
        if (!redisClient.isOpen) {
            await redisClient.connect().catch(err => {
                console.warn('Redis connection failed, tests will continue without Redis:', err.message);
                return null;
            });
        }
        
        // 연결이 성공했으면 데이터 초기화
        if (redisClient.isOpen) {
            await redisClient.flushAll().catch(err => {
                console.warn('Redis flushAll failed:', err.message);
            });
        }
    } catch (error) {
        console.error('Error setting up Redis:', error);
        // 에러를 무시하고 계속 진행
    }
}

// Redis 정리
async function cleanupRedis() {
    try {
        // Redis 클라이언트가 연결되어 있으면 정리 작업 수행
        if (redisClient && redisClient.isOpen) {
            try {
                await redisClient.flushAll();
            } catch (err) {
                console.warn('Redis flushAll failed during cleanup:', err.message);
            }
            
            try {
                await redisClient.quit();
                console.log('Redis client closed successfully');
            } catch (err) {
                console.warn('Redis quit failed:', err.message);
                // 강제 종료 시도
                redisClient.disconnect();
            }
        }
    } catch (error) {
        console.error('Error cleaning up Redis:', error);
        // 강제 종료
        if (redisClient) {
            try {
                redisClient.disconnect();
            } catch (disconnectError) {
                console.error('Failed to forcefully disconnect Redis:', disconnectError);
            }
        }
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
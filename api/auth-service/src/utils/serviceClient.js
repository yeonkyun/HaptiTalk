const axios = require('axios');
const logger = require('./logger');

// 회복성을 위한 기본 설정
const defaultConfig = {
    timeout: 5000,
    maxRetries: 3,
    retryDelay: 300,
    circuitBreaker: {
        failureThreshold: 50,
        resetTimeout: 10000
    }
};

// 단순화된 서비스 클라이언트 생성 함수
function createServiceClient(name, baseURL, options = {}) {
    const client = axios.create({
        baseURL,
        timeout: options.timeout || defaultConfig.timeout,
        headers: {
            'Content-Type': 'application/json',
            ...(options.headers || {})
        }
    });

    // 로깅 및 에러 핸들링을 위한 인터셉터
    client.interceptors.request.use(
        (config) => {
            logger.debug(`[${name}] 요청: ${config.method.toUpperCase()} ${config.url}`);
            return config;
        },
        (error) => {
            logger.error(`[${name}] 요청 오류: ${error.message}`);
            return Promise.reject(error);
        }
    );

    client.interceptors.response.use(
        (response) => {
            logger.debug(`[${name}] 응답: ${response.status}`);
            return response;
        },
        (error) => {
            if (error.response) {
                logger.error(`[${name}] 응답 오류: ${error.response.status}`);
            } else {
                logger.error(`[${name}] 네트워크 오류: ${error.message}`);
            }
            return Promise.reject(error);
        }
    );

    // 재시도 로직 (간단한 구현)
    const retryableRequest = async (method, url, data, retries = defaultConfig.maxRetries) => {
        try {
            const response = await client[method](url, data);
            return response.data;
        } catch (error) {
            if (retries > 0 && !error.response) {
                logger.warn(`[${name}] 재시도 중... (남은 횟수: ${retries})`);
                await new Promise(resolve => setTimeout(resolve, defaultConfig.retryDelay));
                return retryableRequest(method, url, data, retries - 1);
            }
            throw error;
        }
    };

    // 폴백 핸들러 저장소
    const fallbacks = new Map();

    return {
        // 기본 HTTP 메서드
        async get(url, config = {}) {
            try {
                return await retryableRequest('get', url, config);
            } catch (error) {
                return this.handleFallback('get', url, error);
            }
        },
        
        async post(url, data = {}, config = {}) {
            try {
                return await retryableRequest('post', url, data, config);
            } catch (error) {
                return this.handleFallback('post', url, error, data);
            }
        },

        // 폴백 처리 함수
        async handleFallback(method, url, error, data = {}) {
            const operation = url.split('/').pop();
            if (fallbacks.has(operation)) {
                logger.warn(`[${name}] 폴백 적용: ${operation}`);
                const fallbackFn = fallbacks.get(operation);
                return fallbackFn({ ...error, ...data });
            }
            throw error;
        },

        // 폴백 핸들러 등록
        registerFallback(operation, handler) {
            fallbacks.set(operation, handler);
            logger.info(`[${name}] 폴백 핸들러 등록됨: ${operation}`);
        }
    };
}

// 서비스 클라이언트 생성
const userServiceClient = createServiceClient('user', process.env.USER_SERVICE_URL || 'http://user-service:3004', {
    logger,
    headers: {
        'X-Service-Name': 'auth-service'
    }
});

const sessionServiceClient = createServiceClient('session', process.env.SESSION_SERVICE_URL || 'http://session-service:3002', {
    logger,
    headers: {
        'X-Service-Name': 'auth-service'
    }
});

// 폴백 핸들러 등록
userServiceClient.registerFallback('getUserProfile', async (error) => {
    logger.warn('Falling back to cached user profile', { error: error.message });
    
    // Redis에서 캐시된 데이터 조회 시도
    try {
        const { redisClient } = require('../config/redis');
        const cachedData = await redisClient.get(`user:profile:${error.userId}`);
        if (cachedData) {
            return {
                ...JSON.parse(cachedData),
                _isFallback: true,
                _fromCache: true
            };
        }
    } catch (cacheError) {
        logger.error('Cache retrieval failed', { error: cacheError.message });
    }
    
    // 기본 응답 반환
    return {
        id: error.userId,
        status: 'unavailable',
        message: 'User service is temporarily unavailable',
        _isFallback: true
    };
});

sessionServiceClient.registerFallback('getSession', async (error) => {
    logger.warn('Falling back to session fallback', { error: error.message });
    
    return {
        status: 'service_unavailable',
        message: 'Session service is temporarily unavailable',
        _isFallback: true
    };
});

// 데이터베이스 작업을 위한 간소화된 회복성 패턴
const dbResilience = {
    async execute(operation, options = {}) {
        const maxRetries = options.maxRetries || 2;
        const initialDelay = options.initialDelay || 100;
        
        let lastError;
        for (let i = 0; i <= maxRetries; i++) {
            try {
                return await operation();
            } catch (error) {
                lastError = error;
                logger.warn(`데이터베이스 작업 실패, 재시도 중... (${i + 1}/${maxRetries + 1})`, { 
                    error: error.message,
                    operation: options.operationName || 'database_operation'
                });
                
                if (i < maxRetries) {
                    await new Promise(resolve => setTimeout(resolve, initialDelay * Math.pow(2, i)));
                }
            }
        }
        
        throw lastError;
    }
};

// 데이터베이스 작업 래퍼
async function withDbResilience(operation, options = {}) {
    return dbResilience.execute(operation, {
        operationName: options.operationName || 'database_operation',
        ...options
    });
}

module.exports = {
    userServiceClient,
    sessionServiceClient,
    dbResilience,
    withDbResilience
};

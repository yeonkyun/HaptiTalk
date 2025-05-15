// 회복성 정책 사용 예제
const { ResiliencePolicy } = require('../index');
const { getServiceConfig } = require('../config/resilience.config');
const axios = require('axios');
const logger = require('../../auth-service/src/utils/logger');

// 1. 서비스별 회복성 정책 인스턴스 생성
const authResilience = new ResiliencePolicy({
    ...getServiceConfig('auth'),
    logger
});

const realtimeResilience = new ResiliencePolicy({
    ...getServiceConfig('realtime'),
    logger
});

// 2. 폴백 핸들러 등록
authResilience.registerFallback('getUserProfile', async (error) => {
    // Redis 캐시에서 사용자 프로필 조회
    return {
        id: '12345',
        name: 'Cached User',
        email: 'cached@example.com',
        _isFallback: true
    };
});

authResilience.registerFallback('auth', async (error) => {
    // 인증 실패 시 기본 응답
    return {
        status: 'service_unavailable',
        message: 'Authentication service is temporarily unavailable',
        _isFallback: true
    };
});

// 3. 실제 사용 예제 - Auth Service에서 사용자 프로필 조회
async function getUserProfile(userId) {
    return authResilience.execute(
        async () => {
            const response = await axios.get(`http://user-service:3004/api/v1/users/${userId}`);
            return response.data;
        },
        {
            fallbackKey: 'getUserProfile',
            service: 'user',
            operation: 'getUserProfile'
        }
    );
}

// 4. 실제 사용 예제 - Realtime Service에서 세션 정보 조회
async function getSessionInfo(sessionId) {
    return realtimeResilience.execute(
        async () => {
            const response = await axios.get(`http://session-service:3002/api/v1/sessions/${sessionId}`);
            return response.data;
        },
        {
            fallbackKey: 'getSessionInfo',
            service: 'session',
            operation: 'getSessionInfo',
            timeout: 3000 // 특정 작업에 대해 타임아웃 오버라이드
        }
    );
}

// 5. 서비스 간 통신 래퍼 함수 예제
class InterServiceClient {
    constructor(serviceName, baseUrl, resilienceConfig) {
        this.serviceName = serviceName;
        this.baseUrl = baseUrl;
        this.resilience = new ResiliencePolicy({
            ...getServiceConfig(serviceName),
            ...resilienceConfig
        });
    }

    async get(path, options = {}) {
        return this.resilience.execute(
            async () => {
                const response = await axios.get(`${this.baseUrl}${path}`, {
                    headers: options.headers,
                    params: options.params
                });
                return response.data;
            },
            {
                service: this.serviceName,
                operation: `GET ${path}`,
                ...options.resilienceOptions
            }
        );
    }

    async post(path, data, options = {}) {
        return this.resilience.execute(
            async () => {
                const response = await axios.post(`${this.baseUrl}${path}`, data, {
                    headers: options.headers
                });
                return response.data;
            },
            {
                service: this.serviceName,
                operation: `POST ${path}`,
                ...options.resilienceOptions
            }
        );
    }

    // 다른 HTTP 메서드들도 유사하게 구현...
}

// 6. 서비스 클라이언트 사용 예제
const userServiceClient = new InterServiceClient(
    'user',
    'http://user-service:3004',
    { logger }
);

const sessionServiceClient = new InterServiceClient(
    'session',
    'http://session-service:3002',
    { logger }
);

// 7. 헬스체크 예제
async function checkServiceHealth() {
    const services = {
        auth: authResilience,
        realtime: realtimeResilience
    };

    const healthStatus = {};

    for (const [serviceName, resilience] of Object.entries(services)) {
        healthStatus[serviceName] = {
            isHealthy: resilience.isHealthy(),
            stats: resilience.getStats()
        };
    }

    return healthStatus;
}

module.exports = {
    authResilience,
    realtimeResilience,
    getUserProfile,
    getSessionInfo,
    InterServiceClient,
    userServiceClient,
    sessionServiceClient,
    checkServiceHealth
};

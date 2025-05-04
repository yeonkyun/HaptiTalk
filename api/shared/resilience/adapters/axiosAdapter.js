const axios = require('axios');
const { ResiliencePolicy } = require('../ResiliencePolicy');
const { getServiceConfig } = require('../config/resilience.config');

// Axios 인스턴스에 회복성 정책을 적용하는 어댑터
class AxiosResilienceAdapter {
    constructor(serviceName = 'default', config = {}) {
        this.serviceName = serviceName;
        this.resilience = new ResiliencePolicy({
            ...getServiceConfig(serviceName),
            ...config
        });
        
        // 기본 axios 인스턴스 생성
        this.axios = axios.create(config.axiosConfig || {});
        
        // 인터셉터 설정
        this.setupInterceptors();
    }

    setupInterceptors() {
        // 요청 인터셉터
        this.axios.interceptors.request.use(
            config => {
                // 요청 시작 시간 기록
                config.metadata = { startTime: new Date() };
                return config;
            },
            error => Promise.reject(error)
        );

        // 응답 인터셉터
        this.axios.interceptors.response.use(
            response => {
                // 응답 시간 기록
                const endTime = new Date();
                const duration = endTime - response.config.metadata.startTime;
                response.duration = duration;
                return response;
            },
            error => {
                // 에러 응답 시간 기록
                if (error.config && error.config.metadata) {
                    const endTime = new Date();
                    const duration = endTime - error.config.metadata.startTime;
                    error.duration = duration;
                }
                return Promise.reject(error);
            }
        );
    }

    // 회복성 정책이 적용된 axios 요청 메서드
    async request(config) {
        return this.resilience.execute(
            async () => {
                const response = await this.axios.request(config);
                return response.data;
            },
            {
                service: this.serviceName,
                operation: `${config.method?.toUpperCase()} ${config.url}`,
                fallbackKey: config.fallbackKey || 'default',
                ...config.resilienceOptions
            }
        );
    }

    async get(url, config = {}) {
        return this.request({ ...config, method: 'get', url });
    }

    async post(url, data, config = {}) {
        return this.request({ ...config, method: 'post', url, data });
    }

    async put(url, data, config = {}) {
        return this.request({ ...config, method: 'put', url, data });
    }

    async patch(url, data, config = {}) {
        return this.request({ ...config, method: 'patch', url, data });
    }

    async delete(url, config = {}) {
        return this.request({ ...config, method: 'delete', url });
    }

    // 폴백 핸들러 등록
    registerFallback(key, handler) {
        this.resilience.registerFallback(key, handler);
    }

    // 회복성 정책 통계 조회
    getStats() {
        return this.resilience.getStats();
    }

    // 서비스 상태 확인
    isHealthy() {
        return this.resilience.isHealthy();
    }
}

// 서비스별 axios 인스턴스 생성 헬퍼 함수
function createServiceClient(serviceName, baseURL, config = {}) {
    const adapter = new AxiosResilienceAdapter(serviceName, {
        ...config,
        axiosConfig: {
            baseURL,
            timeout: config.timeout || 5000,
            headers: {
                'Content-Type': 'application/json',
                ...config.headers
            }
        }
    });

    return adapter;
}

module.exports = {
    AxiosResilienceAdapter,
    createServiceClient
};

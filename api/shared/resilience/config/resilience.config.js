// 서비스별 기본 회복성 정책 설정
const defaultConfig = {
    auth: {
        name: 'auth-service',
        circuitBreaker: {
            failureThreshold: 5,
            resetTimeout: 60000, // 1분
            halfOpenMaxCalls: 3
        },
        retry: {
            maxRetries: 3,
            initialDelay: 100,
            maxDelay: 3000,
            backoffMultiplier: 2
        },
        timeout: {
            defaultTimeout: 5000,
            timeouts: {
                database: 3000,
                redis: 1000,
                external: 10000
            }
        },
        fallback: {
            errorThreshold: 3,
            errorWindow: 60000
        },
        bulkhead: {
            maxConcurrentCalls: 20,
            queueCapacity: 10,
            timeout: 3000
        }
    },
    
    realtime: {
        name: 'realtime-service',
        circuitBreaker: {
            failureThreshold: 10,
            resetTimeout: 30000, // 30초
            halfOpenMaxCalls: 5
        },
        retry: {
            maxRetries: 2, // 실시간 서비스는 재시도 최소화
            initialDelay: 100,
            maxDelay: 1000,
            backoffMultiplier: 2
        },
        timeout: {
            defaultTimeout: 3000,
            timeouts: {
                websocket: 5000,
                redis: 1000,
                kafka: 2000
            }
        },
        fallback: {
            errorThreshold: 5,
            errorWindow: 30000
        },
        bulkhead: {
            maxConcurrentCalls: 50, // 더 많은 동시 연결 허용
            queueCapacity: 20,
            timeout: 2000
        }
    },

    session: {
        name: 'session-service',
        circuitBreaker: {
            failureThreshold: 5,
            resetTimeout: 60000,
            halfOpenMaxCalls: 3
        },
        retry: {
            maxRetries: 3,
            initialDelay: 200,
            maxDelay: 5000,
            backoffMultiplier: 2
        },
        timeout: {
            defaultTimeout: 8000,
            timeouts: {
                database: 5000,
                redis: 2000,
                mongodb: 5000
            }
        },
        fallback: {
            errorThreshold: 3,
            errorWindow: 60000
        },
        bulkhead: {
            maxConcurrentCalls: 30,
            queueCapacity: 15,
            timeout: 4000
        }
    },

    feedback: {
        name: 'feedback-service',
        circuitBreaker: {
            failureThreshold: 5,
            resetTimeout: 45000,
            halfOpenMaxCalls: 3
        },
        retry: {
            maxRetries: 3,
            initialDelay: 150,
            maxDelay: 4000,
            backoffMultiplier: 2
        },
        timeout: {
            defaultTimeout: 6000,
            timeouts: {
                database: 4000,
                mongodb: 4000,
                aiAnalysis: 10000
            }
        },
        fallback: {
            errorThreshold: 4,
            errorWindow: 60000
        },
        bulkhead: {
            maxConcurrentCalls: 25,
            queueCapacity: 10,
            timeout: 3000
        }
    },

    user: {
        name: 'user-service',
        circuitBreaker: {
            failureThreshold: 5,
            resetTimeout: 60000,
            halfOpenMaxCalls: 3
        },
        retry: {
            maxRetries: 3,
            initialDelay: 100,
            maxDelay: 3000,
            backoffMultiplier: 2
        },
        timeout: {
            defaultTimeout: 5000,
            timeouts: {
                database: 3000,
                redis: 1000,
                external: 8000
            }
        },
        fallback: {
            errorThreshold: 3,
            errorWindow: 60000
        },
        bulkhead: {
            maxConcurrentCalls: 30,
            queueCapacity: 15,
            timeout: 3000
        }
    },

    report: {
        name: 'report-service',
        circuitBreaker: {
            failureThreshold: 5,
            resetTimeout: 90000, // 보고서 생성은 더 긴 복구 시간
            halfOpenMaxCalls: 2
        },
        retry: {
            maxRetries: 4,
            initialDelay: 500,
            maxDelay: 10000,
            backoffMultiplier: 2
        },
        timeout: {
            defaultTimeout: 15000, // 보고서 생성은 더 긴 시간 필요
            timeouts: {
                database: 5000,
                mongodb: 8000,
                reportGeneration: 30000
            }
        },
        fallback: {
            errorThreshold: 3,
            errorWindow: 120000
        },
        bulkhead: {
            maxConcurrentCalls: 10, // 리소스 집약적이므로 동시 실행 제한
            queueCapacity: 5,
            timeout: 10000
        }
    }
};

// 환경별 설정 오버라이드
const envConfig = {
    development: {
        // 개발 환경에서는 더 관대한 설정
        global: {
            retry: {
                maxRetries: 5
            },
            circuitBreaker: {
                failureThreshold: 10
            }
        }
    },
    production: {
        // 프로덕션 환경에서는 더 엄격한 설정
        global: {
            retry: {
                maxRetries: 2
            },
            circuitBreaker: {
                failureThreshold: 3
            },
            timeout: {
                defaultTimeout: 3000
            }
        }
    }
};

function getServiceConfig(serviceName) {
    const baseConfig = defaultConfig[serviceName] || defaultConfig.auth;
    const env = process.env.NODE_ENV || 'development';
    const envOverrides = envConfig[env]?.global || {};

    // 환경별 설정으로 기본 설정 오버라이드
    return {
        ...baseConfig,
        retry: { ...baseConfig.retry, ...envOverrides.retry },
        circuitBreaker: { ...baseConfig.circuitBreaker, ...envOverrides.circuitBreaker },
        timeout: { ...baseConfig.timeout, ...envOverrides.timeout },
        fallback: { ...baseConfig.fallback, ...envOverrides.fallback },
        bulkhead: { ...baseConfig.bulkhead, ...envOverrides.bulkhead }
    };
}

module.exports = {
    defaultConfig,
    envConfig,
    getServiceConfig
};

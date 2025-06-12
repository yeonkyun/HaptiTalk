class TimeoutPolicy {
    constructor(options = {}) {
        this.defaultTimeout = options.defaultTimeout || 5000; // ms
        this.timeouts = options.timeouts || {}; // 서비스별 타임아웃 설정
    }

    async execute(fn, options = {}) {
        const timeout = options.timeout || this.getTimeout(options.service);
        const operation = options.operation || 'unknown';

        return new Promise((resolve, reject) => {
            const timer = setTimeout(() => {
                const error = new Error(`Operation timed out after ${timeout}ms`);
                error.code = 'ETIMEDOUT';
                error.timeout = timeout;
                error.operation = operation;
                reject(error);
            }, timeout);

            fn()
                .then(result => {
                    clearTimeout(timer);
                    resolve(result);
                })
                .catch(error => {
                    clearTimeout(timer);
                    reject(error);
                });
        });
    }

    getTimeout(service) {
        if (service && this.timeouts[service]) {
            return this.timeouts[service];
        }
        return this.defaultTimeout;
    }

    // 서비스별 타임아웃 설정 업데이트
    updateTimeout(service, timeout) {
        this.timeouts[service] = timeout;
    }

    // 전체 타임아웃 설정 조회
    getTimeouts() {
        return {
            default: this.defaultTimeout,
            services: { ...this.timeouts }
        };
    }
}

module.exports = TimeoutPolicy;

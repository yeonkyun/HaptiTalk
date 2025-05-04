class RetryPolicy {
    constructor(options = {}) {
        this.maxRetries = options.maxRetries || 3;
        this.initialDelay = options.initialDelay || 100; // ms
        this.maxDelay = options.maxDelay || 5000; // ms
        this.backoffMultiplier = options.backoffMultiplier || 2;
        this.jitterFactor = options.jitterFactor || 0.1;
        this.retryableErrors = options.retryableErrors || ['ETIMEDOUT', 'ECONNRESET', 'ECONNREFUSED'];
        this.retryableStatusCodes = options.retryableStatusCodes || [408, 429, 500, 502, 503, 504];
    }

    async execute(fn, context = {}) {
        let lastError;
        let attempt = 0;

        while (attempt <= this.maxRetries) {
            try {
                return await fn();
            } catch (error) {
                lastError = error;
                
                if (!this.shouldRetry(error, attempt)) {
                    throw error;
                }

                const delay = this.calculateDelay(attempt);
                attempt++;

                // 로깅을 위한 컨텍스트 정보
                if (context.logger) {
                    context.logger.warn('Retrying failed operation', {
                        attempt,
                        maxRetries: this.maxRetries,
                        delay,
                        error: error.message,
                        code: error.code,
                        statusCode: error.statusCode
                    });
                }

                await this.delay(delay);
            }
        }

        throw lastError;
    }

    shouldRetry(error, attempt) {
        // 최대 재시도 횟수 초과
        if (attempt >= this.maxRetries) {
            return false;
        }

        // 네트워크 에러 확인
        if (error.code && this.retryableErrors.includes(error.code)) {
            return true;
        }

        // HTTP 상태 코드 확인
        if (error.statusCode && this.retryableStatusCodes.includes(error.statusCode)) {
            return true;
        }

        // 특정 에러 메시지 패턴 확인
        if (error.message) {
            const retryablePatterns = [
                /timeout/i,
                /ECONNRESET/i,
                /ETIMEDOUT/i,
                /socket hang up/i
            ];

            for (const pattern of retryablePatterns) {
                if (pattern.test(error.message)) {
                    return true;
                }
            }
        }

        return false;
    }

    calculateDelay(attempt) {
        // 지수 백오프 계산
        let delay = this.initialDelay * Math.pow(this.backoffMultiplier, attempt);
        
        // 최대 지연 시간 제한
        delay = Math.min(delay, this.maxDelay);
        
        // 지터 추가 (무작위성)
        const jitter = delay * this.jitterFactor * (Math.random() * 2 - 1);
        delay += jitter;
        
        return Math.max(0, delay);
    }

    delay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

module.exports = RetryPolicy;

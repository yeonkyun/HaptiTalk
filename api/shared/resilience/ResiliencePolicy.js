const CircuitBreaker = require('./circuit-breaker/CircuitBreaker');
const RetryPolicy = require('./retry/RetryPolicy');
const TimeoutPolicy = require('./timeout/TimeoutPolicy');
const FallbackPolicy = require('./fallback/FallbackPolicy');
const BulkheadPolicy = require('./bulkhead/BulkheadPolicy');

class ResiliencePolicy {
    constructor(options = {}) {
        this.name = options.name || 'default';
        this.logger = options.logger || console;

        // 각 정책 초기화
        this.circuitBreaker = new CircuitBreaker(options.circuitBreaker);
        this.retryPolicy = new RetryPolicy(options.retry);
        this.timeoutPolicy = new TimeoutPolicy(options.timeout);
        this.fallbackPolicy = new FallbackPolicy(options.fallback);
        this.bulkheadPolicy = new BulkheadPolicy(options.bulkhead);

        // 통계
        this.stats = {
            totalExecutions: 0,
            successfulExecutions: 0,
            failedExecutions: 0,
            fallbackExecutions: 0
        };

        // 이벤트 리스너 설정
        this.setupEventListeners();
    }

    setupEventListeners() {
        this.circuitBreaker.on('stateChange', (state) => {
            this.logger.info(`Circuit breaker state changed: ${state}`, {
                policy: this.name,
                stats: this.circuitBreaker.getStats()
            });
        });

        this.circuitBreaker.on('circuitOpen', (details) => {
            this.logger.warn('Circuit breaker opened', {
                policy: this.name,
                details
            });
        });

        this.bulkheadPolicy.on('rejected', () => {
            this.logger.warn('Request rejected by bulkhead policy', {
                policy: this.name,
                stats: this.bulkheadPolicy.getStats()
            });
        });
    }

    async execute(fn, options = {}) {
        this.stats.totalExecutions++;
        const context = {
            policyName: this.name,
            operation: options.operation || 'unknown',
            service: options.service || 'unknown',
            logger: this.logger
        };

        try {
            // 1. Bulkhead로 동시 실행 제한
            const result = await this.bulkheadPolicy.execute(async () => {
                // 2. Circuit Breaker로 장애 전파 방지
                return await this.circuitBreaker.execute(async () => {
                    // 3. Timeout 정책 적용
                    return await this.timeoutPolicy.execute(async () => {
                        // 4. Retry 정책 적용
                        return await this.retryPolicy.execute(fn, context);
                    }, options);
                });
            });

            this.stats.successfulExecutions++;
            return result;

        } catch (error) {
            // 5. Fallback 정책 적용
            try {
                const fallbackResult = await this.fallbackPolicy.execute(
                    () => Promise.reject(error),
                    options
                );
                this.stats.fallbackExecutions++;
                return fallbackResult;
            } catch (fallbackError) {
                this.stats.failedExecutions++;
                this.logger.error('Operation failed after all resilience policies', {
                    policy: this.name,
                    error: fallbackError.message,
                    originalError: fallbackError.originalError?.message,
                    context
                });
                throw fallbackError;
            }
        }
    }

    // 정책 설정 업데이트
    updatePolicy(policyType, options) {
        switch (policyType) {
            case 'circuitBreaker':
                Object.assign(this.circuitBreaker, options);
                break;
            case 'retry':
                Object.assign(this.retryPolicy, options);
                break;
            case 'timeout':
                Object.assign(this.timeoutPolicy, options);
                break;
            case 'fallback':
                Object.assign(this.fallbackPolicy, options);
                break;
            case 'bulkhead':
                Object.assign(this.bulkheadPolicy, options);
                break;
            default:
                throw new Error(`Unknown policy type: ${policyType}`);
        }
    }

    // 폴백 핸들러 등록
    registerFallback(key, handler) {
        this.fallbackPolicy.registerFallback(key, handler);
    }

    // 전체 통계 조회
    getStats() {
        return {
            policy: this.name,
            executions: this.stats,
            circuitBreaker: this.circuitBreaker.getStats(),
            bulkhead: this.bulkheadPolicy.getStats(),
            fallback: this.fallbackPolicy.getErrorStats()
        };
    }

    // 정책 상태 확인
    isHealthy() {
        return this.circuitBreaker.getState() !== 'OPEN';
    }
}

module.exports = ResiliencePolicy;

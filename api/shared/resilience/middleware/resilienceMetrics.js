const promClient = require('prom-client');

// 회복성 관련 메트릭 정의
const circuitBreakerStateGauge = new promClient.Gauge({
    name: 'circuit_breaker_state',
    help: 'Current state of circuit breaker (0=closed, 1=open, 2=half-open)',
    labelNames: ['service', 'operation']
});

const circuitBreakerCallsCounter = new promClient.Counter({
    name: 'circuit_breaker_calls_total',
    help: 'Total number of calls through circuit breaker',
    labelNames: ['service', 'operation', 'result']
});

const retryAttemptsCounter = new promClient.Counter({
    name: 'retry_attempts_total',
    help: 'Total number of retry attempts',
    labelNames: ['service', 'operation', 'attempt_number']
});

const timeoutCounter = new promClient.Counter({
    name: 'operation_timeouts_total',
    help: 'Total number of operation timeouts',
    labelNames: ['service', 'operation']
});

const fallbackCounter = new promClient.Counter({
    name: 'fallback_executions_total',
    help: 'Total number of fallback executions',
    labelNames: ['service', 'operation', 'fallback_key']
});

const bulkheadRejectionCounter = new promClient.Counter({
    name: 'bulkhead_rejections_total',
    help: 'Total number of requests rejected by bulkhead',
    labelNames: ['service', 'operation']
});

const bulkheadQueueSizeGauge = new promClient.Gauge({
    name: 'bulkhead_queue_size',
    help: 'Current size of bulkhead queue',
    labelNames: ['service', 'operation']
});

// 회복성 메트릭 미들웨어
const resilienceMetricsMiddleware = (resiliencePolicies) => {
    return (req, res, next) => {
        // 요청 경로에 회복성 상태 추가
        if (req.path === '/resilience/metrics') {
            const metrics = {};
            
            for (const [name, policy] of Object.entries(resiliencePolicies)) {
                const stats = policy.getStats();
                metrics[name] = {
                    ...stats,
                    healthy: policy.isHealthy()
                };
                
                // 메트릭 업데이트
                if (stats.circuitBreaker) {
                    const state = stats.circuitBreaker.state === 'CLOSED' ? 0 :
                                stats.circuitBreaker.state === 'OPEN' ? 1 : 2;
                    circuitBreakerStateGauge.set({ service: name, operation: 'default' }, state);
                }
                
                if (stats.bulkhead) {
                    bulkheadQueueSizeGauge.set(
                        { service: name, operation: 'default' },
                        stats.bulkhead.queueLength
                    );
                }
            }
            
            res.json(metrics);
        } else {
            next();
        }
    };
};

// 회복성 이벤트 리스너 설정
const setupResilienceMetrics = (resiliencePolicy, serviceName) => {
    // Circuit Breaker 이벤트
    resiliencePolicy.circuitBreaker.on('stateChange', (state) => {
        const stateValue = state === 'CLOSED' ? 0 : state === 'OPEN' ? 1 : 2;
        circuitBreakerStateGauge.set({ service: serviceName, operation: 'default' }, stateValue);
    });
    
    resiliencePolicy.circuitBreaker.on('success', () => {
        circuitBreakerCallsCounter.inc({ service: serviceName, operation: 'default', result: 'success' });
    });
    
    resiliencePolicy.circuitBreaker.on('failure', () => {
        circuitBreakerCallsCounter.inc({ service: serviceName, operation: 'default', result: 'failure' });
    });
    
    // Retry 이벤트
    resiliencePolicy.retryPolicy.on('retry', (attemptNumber) => {
        retryAttemptsCounter.inc({ service: serviceName, operation: 'default', attempt_number: attemptNumber });
    });
    
    // Timeout 이벤트
    resiliencePolicy.timeoutPolicy.on('timeout', () => {
        timeoutCounter.inc({ service: serviceName, operation: 'default' });
    });
    
    // Fallback 이벤트
    resiliencePolicy.fallbackPolicy.on('fallback', (fallbackKey) => {
        fallbackCounter.inc({ service: serviceName, operation: 'default', fallback_key: fallbackKey });
    });
    
    // Bulkhead 이벤트
    resiliencePolicy.bulkheadPolicy.on('rejected', () => {
        bulkheadRejectionCounter.inc({ service: serviceName, operation: 'default' });
    });
};

module.exports = {
    resilienceMetricsMiddleware,
    setupResilienceMetrics
};

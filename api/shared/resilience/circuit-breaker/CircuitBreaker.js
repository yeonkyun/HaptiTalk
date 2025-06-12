const EventEmitter = require('events');

class CircuitBreaker extends EventEmitter {
    constructor(options = {}) {
        super();
        
        // 기본 설정
        this.failureThreshold = options.failureThreshold || 5; // 실패 임계값
        this.resetTimeout = options.resetTimeout || 60000; // 회로 재설정 시간 (ms)
        this.halfOpenMaxCalls = options.halfOpenMaxCalls || 3; // half-open 상태에서 최대 호출 수
        
        // 상태 관리
        this.state = 'CLOSED'; // CLOSED, OPEN, HALF_OPEN
        this.failureCount = 0;
        this.lastFailureTime = null;
        this.halfOpenCallCount = 0;
        this.nextAttemptTime = null;
        
        // 통계
        this.stats = {
            totalCalls: 0,
            successfulCalls: 0,
            failedCalls: 0,
            openedCount: 0,
            lastOpenedAt: null
        };
    }
    
    async execute(fn) {
        this.stats.totalCalls++;
        
        if (!this.canExecute()) {
            const error = new Error('Circuit breaker is OPEN');
            error.code = 'CIRCUIT_OPEN';
            throw error;
        }
        
        try {
            if (this.state === 'HALF_OPEN') {
                this.halfOpenCallCount++;
            }
            
            const result = await fn();
            this.onSuccess();
            return result;
        } catch (error) {
            this.onFailure();
            throw error;
        }
    }
    
    canExecute() {
        if (this.state === 'CLOSED') {
            return true;
        }
        
        if (this.state === 'OPEN') {
            if (Date.now() >= this.nextAttemptTime) {
                this.state = 'HALF_OPEN';
                this.halfOpenCallCount = 0;
                this.emit('stateChange', 'HALF_OPEN');
                return true;
            }
            return false;
        }
        
        if (this.state === 'HALF_OPEN') {
            return this.halfOpenCallCount < this.halfOpenMaxCalls;
        }
        
        return false;
    }
    
    onSuccess() {
        this.stats.successfulCalls++;
        
        if (this.state === 'HALF_OPEN') {
            if (this.halfOpenCallCount >= this.halfOpenMaxCalls) {
                this.reset();
            }
        } else {
            this.failureCount = 0;
        }
    }
    
    onFailure() {
        this.stats.failedCalls++;
        this.failureCount++;
        this.lastFailureTime = Date.now();
        
        if (this.state === 'HALF_OPEN' || this.failureCount >= this.failureThreshold) {
            this.trip();
        }
    }
    
    trip() {
        this.state = 'OPEN';
        this.nextAttemptTime = Date.now() + this.resetTimeout;
        this.stats.openedCount++;
        this.stats.lastOpenedAt = new Date();
        this.emit('stateChange', 'OPEN');
        this.emit('circuitOpen', {
            failureCount: this.failureCount,
            lastFailureTime: this.lastFailureTime
        });
    }
    
    reset() {
        this.state = 'CLOSED';
        this.failureCount = 0;
        this.halfOpenCallCount = 0;
        this.emit('stateChange', 'CLOSED');
    }
    
    getStats() {
        return {
            ...this.stats,
            state: this.state,
            failureCount: this.failureCount,
            nextAttemptTime: this.nextAttemptTime
        };
    }
    
    getState() {
        return this.state;
    }
}

module.exports = CircuitBreaker;

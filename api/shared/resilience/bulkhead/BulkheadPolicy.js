const { EventEmitter } = require('events');

class BulkheadPolicy extends EventEmitter {
    constructor(options = {}) {
        super();
        
        this.maxConcurrentCalls = options.maxConcurrentCalls || 10;
        this.queueCapacity = options.queueCapacity || 10;
        this.timeout = options.timeout || 2000; // 대기열 타임아웃
        
        this.activeCalls = 0;
        this.queue = [];
        
        // 통계
        this.stats = {
            totalCalls: 0,
            rejectedCalls: 0,
            queuedCalls: 0,
            timedOutCalls: 0,
            successfulCalls: 0,
            failedCalls: 0
        };
    }

    async execute(fn) {
        this.stats.totalCalls++;

        // 실행 가능한 상태인지 확인
        if (this.activeCalls < this.maxConcurrentCalls) {
            return this.executeImmediately(fn);
        }

        // 대기열에 공간이 있는지 확인
        if (this.queue.length < this.queueCapacity) {
            return this.enqueue(fn);
        }

        // 대기열도 가득 찬 경우 요청 거부
        this.stats.rejectedCalls++;
        const error = new Error('Bulkhead queue is full');
        error.code = 'BULKHEAD_QUEUE_FULL';
        throw error;
    }

    async executeImmediately(fn) {
        this.activeCalls++;
        
        try {
            const result = await fn();
            this.stats.successfulCalls++;
            return result;
        } catch (error) {
            this.stats.failedCalls++;
            throw error;
        } finally {
            this.activeCalls--;
            this.processQueue(); // 대기열 처리
        }
    }

    enqueue(fn) {
        return new Promise((resolve, reject) => {
            this.stats.queuedCalls++;
            
            const timeoutId = setTimeout(() => {
                // 대기열에서 제거
                const index = this.queue.findIndex(item => item.fn === fn);
                if (index !== -1) {
                    this.queue.splice(index, 1);
                    this.stats.timedOutCalls++;
                    const error = new Error('Bulkhead queue timeout');
                    error.code = 'BULKHEAD_TIMEOUT';
                    reject(error);
                }
            }, this.timeout);

            this.queue.push({
                fn,
                resolve,
                reject,
                timeoutId,
                enqueuedAt: Date.now()
            });
        });
    }

    processQueue() {
        if (this.queue.length === 0 || this.activeCalls >= this.maxConcurrentCalls) {
            return;
        }

        const item = this.queue.shift();
        clearTimeout(item.timeoutId);

        this.activeCalls++;
        
        item.fn()
            .then(result => {
                this.stats.successfulCalls++;
                item.resolve(result);
            })
            .catch(error => {
                this.stats.failedCalls++;
                item.reject(error);
            })
            .finally(() => {
                this.activeCalls--;
                this.processQueue(); // 다음 대기 항목 처리
            });
    }

    getStats() {
        return {
            ...this.stats,
            activeCalls: this.activeCalls,
            queueLength: this.queue.length,
            maxConcurrentCalls: this.maxConcurrentCalls,
            queueCapacity: this.queueCapacity
        };
    }

    // 동적으로 동시 실행 한도 조정
    updateMaxConcurrentCalls(value) {
        this.maxConcurrentCalls = value;
        // 한도가 증가했다면 대기열 처리 시도
        if (value > this.activeCalls) {
            this.processQueue();
        }
    }

    // 동적으로 대기열 크기 조정
    updateQueueCapacity(value) {
        this.queueCapacity = value;
    }
}

module.exports = BulkheadPolicy;

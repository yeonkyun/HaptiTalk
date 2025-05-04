class FallbackPolicy {
    constructor(options = {}) {
        this.fallbackHandlers = options.fallbackHandlers || new Map();
        this.defaultFallback = options.defaultFallback || null;
        this.errorThreshold = options.errorThreshold || 3;
        this.errorWindow = options.errorWindow || 60000; // 1분
        this.errorCounts = new Map();
    }

    async execute(fn, options = {}) {
        const fallbackKey = options.fallbackKey || 'default';
        const fallbackHandler = this.fallbackHandlers.get(fallbackKey) || this.defaultFallback;

        try {
            const result = await fn();
            this.recordSuccess(fallbackKey);
            return result;
        } catch (error) {
            this.recordError(fallbackKey);
            
            if (this.shouldUseFallback(fallbackKey)) {
                if (fallbackHandler) {
                    try {
                        const fallbackResult = await fallbackHandler(error);
                        // 폴백 결과임을 표시
                        if (typeof fallbackResult === 'object' && fallbackResult !== null) {
                            fallbackResult._isFallback = true;
                        }
                        return fallbackResult;
                    } catch (fallbackError) {
                        // 폴백도 실패한 경우 원래 에러를 throw
                        fallbackError.originalError = error;
                        throw fallbackError;
                    }
                }
            }
            
            throw error;
        }
    }

    registerFallback(key, handler) {
        if (typeof handler !== 'function') {
            throw new Error('Fallback handler must be a function');
        }
        this.fallbackHandlers.set(key, handler);
    }

    setDefaultFallback(handler) {
        if (typeof handler !== 'function') {
            throw new Error('Fallback handler must be a function');
        }
        this.defaultFallback = handler;
    }

    recordError(key) {
        if (!this.errorCounts.has(key)) {
            this.errorCounts.set(key, []);
        }
        
        const errors = this.errorCounts.get(key);
        const now = Date.now();
        
        // 오래된 에러 제거
        const recentErrors = errors.filter(time => now - time < this.errorWindow);
        recentErrors.push(now);
        
        this.errorCounts.set(key, recentErrors);
    }

    recordSuccess(key) {
        // 성공 시 해당 키의 에러 카운트 초기화
        this.errorCounts.delete(key);
    }

    shouldUseFallback(key) {
        const errors = this.errorCounts.get(key);
        if (!errors) return false;
        
        const now = Date.now();
        const recentErrors = errors.filter(time => now - time < this.errorWindow);
        
        return recentErrors.length >= this.errorThreshold;
    }

    getErrorStats() {
        const stats = {};
        for (const [key, errors] of this.errorCounts.entries()) {
            const now = Date.now();
            const recentErrors = errors.filter(time => now - time < this.errorWindow);
            stats[key] = recentErrors.length;
        }
        return stats;
    }
}

module.exports = FallbackPolicy;

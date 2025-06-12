/**
 * 데이터베이스 회복성 패턴 구현
 * 
 * 데이터베이스 연결 및 쿼리에 회복성 패턴을 적용하는 유틸리티
 */

const CircuitBreaker = require('./circuit-breaker');
const Retry = require('./retry');
const Timeout = require('./timeout');
const Bulkhead = require('./bulkhead');

class DatabaseResilience {
  /**
   * 데이터베이스 회복성 패턴 생성자
   * @param {Object} options - 옵션
   * @param {Object} options.logger - 로거 인스턴스
   */
  constructor(options = {}) {
    this.logger = options.logger || console;
    
    // 회복성 패턴 인스턴스 생성
    this.circuitBreaker = new CircuitBreaker({
      timeout: options.timeout || 5000,
      errorThresholdPercentage: options.errorThresholdPercentage || 50,
      resetTimeout: options.resetTimeout || 10000,
      name: options.name || 'DatabaseResilience',
      logger: this.logger
    });
    
    this.retry = new Retry({
      maxRetries: options.maxRetries || 3,
      initialDelay: options.initialDelay || 500,
      maxDelay: options.maxDelay || 5000,
      exponentialBackoff: options.exponentialBackoff !== false,
      shouldRetry: this.shouldRetryDatabaseOperation,
      logger: this.logger
    });
    
    this.timeout = new Timeout({
      defaultTimeout: options.timeout || 5000,
      logger: this.logger
    });
    
    this.bulkhead = new Bulkhead({
      concurrentLimit: options.concurrentLimit || 20,
      queueSize: options.queueSize || 100,
      queueTimeout: options.queueTimeout || 5000,
      logger: this.logger
    });
  }

  /**
   * 데이터베이스 작업 재시도 조건
   * @param {Error} error - 데이터베이스 오류
   * @returns {boolean} 재시도 여부
   */
  shouldRetryDatabaseOperation(error) {
    // 연결 관련 오류는 재시도
    if (error.code === 'ECONNREFUSED' || 
        error.code === 'ETIMEDOUT' || 
        error.code === 'ECONNRESET') {
      return true;
    }
    
    // PostgreSQL 특정 오류 코드
    if (error.code === '08006' || // 연결 실패
        error.code === '08001' || // 연결 거부
        error.code === '57P01' || // 관리자에 의한 종료
        error.code === '40001' || // 직렬화 실패
        error.code === '40P01' || // 교착 상태 감지
        error.code === '08000' || // 연결 예외
        error.code === '53300' || // 너무 많은 연결
        error.code === '55P03') { // 리소스 부족
      return true;
    }
    
    // MongoDB 특정 오류 코드
    if (error.name === 'MongoNetworkError' ||
        error.name === 'MongoTimeoutError' ||
        error.name === 'MongoServerSelectionError') {
      return true;
    }
    
    // Redis 특정 오류 
    if (error.code === 'ECONNREFUSED' ||
        error.code === 'ETIMEDOUT' ||
        error.code === 'ECONNRESET' ||
        error.code === 'NR_CLOSED' ||
        error.message.includes('ECONNREFUSED') ||
        error.message.includes('ETIMEDOUT') ||
        error.message.includes('ECONNRESET') ||
        error.message.includes('connection lost')) {
      return true;
    }
    
    // 그 외의 오류는 재시도하지 않음
    return false;
  }

  /**
   * 회복성 패턴을 적용하여 데이터베이스 작업 실행
   * @param {Function} fn - 실행할 함수
   * @param {Object} options - 옵션
   * @returns {Promise<any>} 함수 실행 결과
   */
  async executeWithResilience(fn, options = {}) {
    const operationName = options.name || 'DatabaseOperation';
    
    // Bulkhead 패턴으로 최대 동시 실행 수 제한
    return this.bulkhead.execute(async () => {
      // Retry 패턴으로 일시적인 오류 재시도
      return this.retry.execute(async () => {
        // Circuit Breaker 패턴으로 연쇄 장애 방지
        return this.circuitBreaker.execute(async () => {
          // Timeout 패턴으로 최대 대기 시간 제한
          return this.timeout.execute(async () => {
            return await fn();
          }, {
            timeout: options.timeout,
            name: `${operationName}-Timeout`
          });
        }, {
          name: `${operationName}-CircuitBreaker`
        });
      }, {
        name: `${operationName}-Retry`,
        maxRetries: options.maxRetries,
        shouldRetry: options.shouldRetry || this.shouldRetryDatabaseOperation
      });
    }, {
      name: `${operationName}-Bulkhead`,
      concurrentLimit: options.concurrentLimit
    });
  }

  /**
   * PostgreSQL 연결에 회복성 패턴 적용
   * @param {Object} sequelize - Sequelize 인스턴스
   * @returns {Object} 회복성이 강화된 래퍼 객체
   */
  wrapSequelize(sequelize) {
    const original = {
      query: sequelize.query.bind(sequelize),
      transaction: sequelize.transaction.bind(sequelize)
    };
    
    const self = this;
    
    // 쿼리 메서드 래핑
    sequelize.query = async function(...args) {
      return self.executeWithResilience(
        () => original.query(...args),
        { name: 'SequelizeQuery' }
      );
    };
    
    // 트랜잭션 메서드 래핑
    sequelize.transaction = async function(...args) {
      return self.executeWithResilience(
        () => original.transaction(...args),
        { name: 'SequelizeTransaction' }
      );
    };
    
    self.logger.info('Sequelize 인스턴스에 회복성 패턴 적용됨', {
      component: 'database-resilience',
      type: 'sequelize'
    });
    
    return sequelize;
  }

  /**
   * MongoDB 연결에 회복성 패턴 적용
   * @param {Object} mongoose - Mongoose 인스턴스
   * @returns {Object} 회복성이 강화된 래퍼 객체
   */
  wrapMongoose(mongoose) {
    const self = this;
    
    // 원본 메서드 저장
    const originalExec = mongoose.Query.prototype.exec;
    
    // exec 메서드 래핑
    mongoose.Query.prototype.exec = function(...args) {
      return self.executeWithResilience(
        () => originalExec.apply(this, args),
        { name: 'MongooseQuery' }
      );
    };
    
    self.logger.info('Mongoose 인스턴스에 회복성 패턴 적용됨', {
      component: 'database-resilience',
      type: 'mongoose'
    });
    
    return mongoose;
  }

  /**
   * Redis 클라이언트에 회복성 패턴 적용
   * @param {Object} redisClient - Redis 클라이언트 인스턴스
   * @returns {Object} 회복성이 강화된 래퍼 객체
   */
  wrapRedis(redisClient) {
    const self = this;
    const methods = [
      'get', 'set', 'del', 'hget', 'hset', 'hdel', 'hmset',
      'hmget', 'hgetall', 'rpush', 'lpush', 'lrange', 'sadd',
      'srem', 'smembers', 'publish', 'subscribe'
    ];
    
    // 원본 메서드 저장
    const originals = {};
    methods.forEach(method => {
      if (typeof redisClient[method] === 'function') {
        originals[method] = redisClient[method].bind(redisClient);
      }
    });
    
    // 메서드 래핑
    methods.forEach(method => {
      if (typeof redisClient[method] === 'function') {
        redisClient[method] = function(...args) {
          return self.executeWithResilience(
            () => originals[method](...args),
            { name: `Redis-${method}` }
          );
        };
      }
    });
    
    self.logger.info('Redis 클라이언트에 회복성 패턴 적용됨', {
      component: 'database-resilience',
      type: 'redis'
    });
    
    return redisClient;
  }

  /**
   * 회복성 패턴 상태 조회
   * @returns {Object} 회복성 패턴 상태
   */
  getResilienceStatus() {
    return {
      circuitBreaker: this.circuitBreaker.getAllStatus(),
      bulkhead: this.bulkhead.getAllStatus()
    };
  }
}

module.exports = DatabaseResilience;
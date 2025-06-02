/**
 * WebSocket 연결 관리 유틸리티
 * 연결 상태 추적 및 관리를 위한 기능 제공
 */

const logger = require('./logger');

class ConnectionManager {
  constructor(io, redisClient) {
    this.io = io;
    this.redisClient = redisClient;
    this.connections = new Map();
    this.healthCheckInterval = null;
    this.heartbeatTimeout = 30000; // 30초
  }

  /**
   * 연결 관리자 초기화
   */
  initialize() {
    // 주기적인 연결 상태 확인 설정
    this.healthCheckInterval = setInterval(() => {
      this.checkConnectionHealth();
    }, 60000); // 1분마다 체크
    
    logger.info('WebSocket 연결 관리자가 초기화되었습니다');
  }

  /**
   * 새 연결 추가
   * @param {string} socketId 소켓 ID
   * @param {object} user 사용자 정보
   */
  async addConnection(socketId, user) {
    try {
      // 메모리에 연결 정보 저장
      this.connections.set(socketId, {
        userId: user.id,
        lastActivity: Date.now(),
        isActive: true,
        socketId
      });

      // Redis에 연결 정보 저장
      await this.redisClient.hset(
        `socket:${socketId}`, 
        'userId', user.id,
        'connectedAt', Date.now(),
        'lastActivity', Date.now()
      );
      
      // Redis에 사용자별 연결 정보 저장
      await this.redisClient.sadd(`user:connections:${user.id}`, socketId);
      
      logger.debug(`연결 추가됨: 사용자 ${user.id}, 소켓 ID ${socketId}`);
    } catch (error) {
      logger.error(`연결 추가 오류: ${error.message}`);
    }
  }

  /**
   * 연결 활동 업데이트
   * @param {string} socketId 소켓 ID
   */
  async updateActivity(socketId) {
    try {
      const connection = this.connections.get(socketId);
      if (connection) {
        connection.lastActivity = Date.now();
        await this.redisClient.hset(`socket:${socketId}`, 'lastActivity', Date.now());
      }
    } catch (error) {
      logger.error(`연결 활동 업데이트 오류: ${error.message}`);
    }
  }

  /**
   * 연결 제거
   * @param {string} socketId 소켓 ID
   */
  async removeConnection(socketId) {
    try {
      const connection = this.connections.get(socketId);
      if (connection) {
        // 메모리에서 제거
        this.connections.delete(socketId);
        
        // Redis에서 제거
        await this.redisClient.del(`socket:${socketId}`);
        
        if (connection.userId) {
          await this.redisClient.srem(`user:connections:${connection.userId}`, socketId);
          
          // 세션 연결 정보 확인 및 정리
          const sessionId = await this.redisClient.hget(`connections:user:${connection.userId}`, 'sessionId');
          if (sessionId) {
            // 다른 활성 연결이 있는지 확인
            const activeConnections = await this.redisClient.smembers(`user:connections:${connection.userId}`);
            if (activeConnections.length === 0) {
              // 다른 활성 연결이 없는 경우에만 세션 참여 상태 제거
              await this.redisClient.srem(`session:participants:${sessionId}`, connection.userId);
              await this.redisClient.hdel(`connections:user:${connection.userId}`, 'sessionId');
              
              // 다른 참가자들에게 알림
              this.io.to(`session:${sessionId}`).emit('participant_left', {
                userId: connection.userId,
                timestamp: new Date().toISOString(),
                reason: 'disconnected'
              });
            }
          }
        }
        
        logger.debug(`연결 제거됨: 소켓 ID ${socketId}`);
      }
    } catch (error) {
      logger.error(`연결 제거 오류: ${error.message}`);
    }
  }

  /**
   * 사용자의 모든 연결 조회
   * @param {string} userId 사용자 ID
   * @returns {Promise<Array>} 사용자의 모든 소켓 ID 배열
   */
  async getUserConnections(userId) {
    try {
      return await this.redisClient.smembers(`user:connections:${userId}`);
    } catch (error) {
      logger.error(`사용자 연결 조회 오류: ${error.message}`);
      return [];
    }
  }

  /**
   * 연결 상태 확인
   */
  async checkConnectionHealth() {
    const now = Date.now();
    
    for (const [socketId, connection] of this.connections.entries()) {
      // 일정 시간 동안 활동이 없는 연결 확인
      if (now - connection.lastActivity > this.heartbeatTimeout) {
        logger.warn(`비활성 연결 감지: 소켓 ID ${socketId}, 마지막 활동 ${new Date(connection.lastActivity).toISOString()}`);
        
        // 연결이 여전히 활성 상태인지 확인 (ping/pong)
        const socket = this.io.sockets.sockets.get(socketId);
        if (socket) {
          // ping 메시지 전송
          socket.timeout(5000).emit('ping_check', { timestamp: now }, (err, response) => {
            if (err || !response) {
              // 응답이 없으면 연결 종료
              logger.warn(`비활성 연결 종료: 소켓 ID ${socketId}`);
              socket.disconnect(true);
            } else {
              // 응답이 있으면 활동 시간 업데이트
              this.updateActivity(socketId);
            }
          });
        } else {
          // 소켓 객체가 없으면 연결 정보 제거
          this.removeConnection(socketId);
        }
      }
    }
    
    logger.debug(`연결 상태 확인 완료: ${this.connections.size}개 연결`);
  }

  /**
   * 연결 통계 조회
   * @returns {object} 연결 통계 정보
   */
  getConnectionStats() {
    return {
      totalConnections: this.connections.size,
      timestamp: new Date().toISOString()
    };
  }

  /**
   * 리소스 정리
   */
  cleanup() {
    if (this.healthCheckInterval) {
      clearInterval(this.healthCheckInterval);
    }
    
    logger.info('WebSocket 연결 관리자가 정리되었습니다');
  }
}

module.exports = ConnectionManager; 
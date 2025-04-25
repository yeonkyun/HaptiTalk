/**
 * WebSocket 모니터링 유틸리티
 * 실시간 연결 상태 모니터링 및 통계 수집
 */

const logger = require('./logger');

class SocketMonitor {
  constructor(io, redisClient) {
    this.io = io;
    this.redisClient = redisClient;
    this.metrics = {
      totalConnections: 0,
      activeConnections: 0,
      messagesSent: 0,
      messagesReceived: 0,
      errors: 0,
      reconnections: 0
    };
    this.metricsInterval = null;
    this.serverStartTime = Date.now();
  }

  /**
   * 모니터링 시작
   */
  start() {
    // 주기적인 메트릭스 수집 및 저장
    this.metricsInterval = setInterval(() => {
      this.collectMetrics();
    }, 30000); // 30초마다 메트릭스 수집
    
    // 소켓 이벤트 리스너 등록
    this.setupEventListeners();
    
    logger.info('WebSocket 모니터링이 시작되었습니다');
  }

  /**
   * 이벤트 리스너 설정
   */
  setupEventListeners() {
    // 연결 이벤트
    this.io.on('connection', (socket) => {
      this.metrics.totalConnections++;
      this.metrics.activeConnections++;
      
      // 재연결 이벤트
      socket.on('reconnect_attempt', () => {
        this.metrics.reconnections++;
      });
      
      // 메시지 수신 이벤트 추적
      const originalOnevent = socket.onevent;
      socket.onevent = (packet) => {
        if (packet.data && packet.data[0] !== 'ping' && packet.data[0] !== 'pong') {
          this.metrics.messagesReceived++;
        }
        originalOnevent.call(socket, packet);
      };
      
      // 에러 이벤트
      socket.on('error', () => {
        this.metrics.errors++;
      });
      
      // 연결 해제 이벤트
      socket.on('disconnect', () => {
        this.metrics.activeConnections--;
      });
    });
    
    // 발신 메시지 추적
    const originalEmit = this.io.emit;
    this.io.emit = function() {
      this.metrics.messagesSent++;
      return originalEmit.apply(this.io, arguments);
    }.bind(this);
  }

  /**
   * 메트릭스 수집
   */
  async collectMetrics() {
    try {
      // 현재 상태 복사
      const currentMetrics = { ...this.metrics };
      
      // 추가 정보 수집
      currentMetrics.timestamp = new Date().toISOString();
      currentMetrics.uptime = Date.now() - this.serverStartTime;
      
      // 룸 정보 수집
      const rooms = [];
      for (const [roomName, sockets] of this.io.sockets.adapter.rooms.entries()) {
        if (!roomName.startsWith('#')) { // 소켓 ID 필터링
          rooms.push({
            name: roomName,
            clients: sockets.size
          });
        }
      }
      currentMetrics.rooms = rooms;
      
      // Redis에 저장
      await this.redisClient.hset(
        `stats:realtime:${currentMetrics.timestamp}`,
        'metrics', JSON.stringify(currentMetrics)
      );
      
      // 만료 시간 설정 (24시간)
      await this.redisClient.expire(`stats:realtime:${currentMetrics.timestamp}`, 86400);
      
      logger.debug(`메트릭스 수집 완료: 활성 연결=${currentMetrics.activeConnections}, 메시지 송신=${currentMetrics.messagesSent}, 메시지 수신=${currentMetrics.messagesReceived}`);
    } catch (error) {
      logger.error(`메트릭스 수집 오류: ${error.message}`);
    }
  }

  /**
   * 현재 메트릭스 조회
   * @returns {object} 현재 메트릭스
   */
  getMetrics() {
    return {
      ...this.metrics,
      timestamp: new Date().toISOString(),
      uptime: Date.now() - this.serverStartTime
    };
  }

  /**
   * 특정 소켓의 상태 진단
   * @param {string} socketId 소켓 ID
   * @returns {object} 소켓 상태 정보
   */
  async diagnoseSocket(socketId) {
    try {
      const socket = this.io.sockets.sockets.get(socketId);
      if (!socket) {
        return { error: '소켓을 찾을 수 없습니다' };
      }
      
      // Redis에서 소켓 정보 조회
      const socketInfo = await this.redisClient.hgetall(`socket:${socketId}`);
      
      // 세션 정보 조회
      const sessionId = await this.redisClient.hget(`connections:user:${socketInfo.userId}`, 'sessionId');
      
      return {
        socketId,
        userId: socketInfo.userId,
        sessionId,
        connectedAt: new Date(parseInt(socketInfo.connectedAt)).toISOString(),
        lastActivity: new Date(parseInt(socketInfo.lastActivity)).toISOString(),
        rooms: Array.from(socket.rooms),
        transport: socket.conn.transport.name,
        remoteAddress: socket.handshake.address
      };
    } catch (error) {
      logger.error(`소켓 진단 오류: ${error.message}`);
      return { error: `소켓 진단 오류: ${error.message}` };
    }
  }

  /**
   * 리소스 정리
   */
  stop() {
    if (this.metricsInterval) {
      clearInterval(this.metricsInterval);
    }
    
    logger.info('WebSocket 모니터링이 중지되었습니다');
  }
}

module.exports = SocketMonitor; 
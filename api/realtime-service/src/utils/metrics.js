/**
 * Prometheus 메트릭 설정
 * realtime-service용 메트릭 모듈
 */

const client = require('prom-client');
const logger = require('./logger');

// 메트릭 레지스트리 생성
const collectDefaultMetrics = client.collectDefaultMetrics;
const Registry = client.Registry;
const register = new Registry();

// 기본 Node.js 메트릭 수집 (CPU, 메모리 등)
collectDefaultMetrics({ register });

// HTTP 요청 지속시간 측정 히스토그램
const httpRequestDurationMicroseconds = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'HTTP 요청 처리 시간 (초)',
  labelNames: ['method', 'route', 'status_code'],
  buckets: [0.01, 0.05, 0.1, 0.5, 1, 2, 5, 10]
});
register.registerMetric(httpRequestDurationMicroseconds);

// 요청 카운터 - API 엔드포인트별 호출 횟수
const httpRequestsTotal = new client.Counter({
  name: 'http_requests_total',
  help: '총 HTTP 요청 수',
  labelNames: ['method', 'route', 'status_code']
});
register.registerMetric(httpRequestsTotal);

// 활성 연결 수 게이지
const httpActiveConnections = new client.Gauge({
  name: 'http_active_connections',
  help: '현재 활성 HTTP 연결 수'
});
register.registerMetric(httpActiveConnections);

// API 오류 카운터
const apiErrorsTotal = new client.Counter({
  name: 'api_errors_total',
  help: 'API 처리 중 발생한 오류 수',
  labelNames: ['method', 'route', 'error_type']
});
register.registerMetric(apiErrorsTotal);

// 실시간 통신 관련 메트릭
const realtimeMetrics = {
  socketConnectionsTotal: new client.Counter({
    name: 'socket_connections_total',
    help: '웹소켓 연결 총 수',
    labelNames: ['status'] // connected, disconnected
  }),
  activeSocketConnections: new client.Gauge({
    name: 'active_socket_connections',
    help: '현재 활성 웹소켓 연결 수',
    labelNames: ['namespace'] // default, chat, etc.
  }),
  socketMessagesTotal: new client.Counter({
    name: 'socket_messages_total',
    help: '주고받은 웹소켓 메시지 총 수',
    labelNames: ['type', 'direction'] // type: chat, event, etc. direction: incoming, outgoing
  }),
  socketEventsTotal: new client.Counter({
    name: 'socket_events_total',
    help: '발생한 소켓 이벤트 총 수',
    labelNames: ['event'] // connect, disconnect, error, etc.
  })
};

// 실시간 메트릭 등록
Object.values(realtimeMetrics).forEach(metric => register.registerMetric(metric));

// Express.js 미들웨어 설정
function setupMetricsMiddleware(app) {
  // 메트릭 엔드포인트 설정
  app.get('/metrics', async function(req, res) {
    try {
      res.set('Content-Type', register.contentType);
      res.end(await register.metrics());
    } catch (error) {
      logger.error('메트릭 생성 중 오류 발생', { error: error.message });
      res.status(500).end();
    }
  });

  // 요청 측정 미들웨어
  app.use((req, res, next) => {
    // 활성 연결 증가
    httpActiveConnections.inc();
    
    // 요청 타이머 시작
    const end = httpRequestDurationMicroseconds.startTimer();
    
    // 응답 완료 이벤트 핸들러
    res.on('finish', () => {
      // 라벨 데이터 준비
      const route = req.route ? req.route.path : req.path;
      const method = req.method;
      const statusCode = res.statusCode;
      
      // 타이머 종료 및 히스토그램 업데이트
      end({ method, route, status_code: statusCode });
      
      // 요청 카운터 증가
      httpRequestsTotal.inc({ method, route, status_code: statusCode });
      
      // 활성 연결 감소
      httpActiveConnections.dec();
    });
    
    next();
  });
}

// 에러 처리 미들웨어
function errorMetricsMiddleware(err, req, res, next) {
  const route = req.route ? req.route.path : req.path;
  const method = req.method;
  const errorType = err.name || 'UnknownError';
  
  // 오류 카운터 증가
  apiErrorsTotal.inc({ method, route, error_type: errorType });
  
  next(err);
}

// Socket.IO 모니터링 설정
function monitorSocketIO(io) {
  // 네임스페이스별 연결 카운터 초기화
  const namespaces = Object.keys(io.nsps || {});
  namespaces.forEach(nsp => {
    realtimeMetrics.activeSocketConnections.set({ namespace: nsp }, 0);
  });
  
  // 소켓 이벤트 모니터링
  io.on('connection', socket => {
    // 연결 카운터 증가
    realtimeMetrics.socketConnectionsTotal.inc({ status: 'connected' });
    realtimeMetrics.activeSocketConnections.inc({ namespace: socket.nsp.name });
    
    // 연결 이벤트 카운터 증가
    realtimeMetrics.socketEventsTotal.inc({ event: 'connect' });
    
    // 모든 이벤트 메시지 카운팅
    const onevent = socket.onevent;
    socket.onevent = function(packet) {
      const eventName = packet.data[0];
      realtimeMetrics.socketEventsTotal.inc({ event: eventName });
      realtimeMetrics.socketMessagesTotal.inc({ 
        type: eventName, 
        direction: 'incoming' 
      });
      onevent.call(this, packet);
    };
    
    // 원래 emit 함수 저장
    const emit = socket.emit;
    socket.emit = function(eventName, ...args) {
      realtimeMetrics.socketMessagesTotal.inc({ 
        type: eventName, 
        direction: 'outgoing' 
      });
      return emit.apply(this, [eventName, ...args]);
    };
    
    // 연결 해제 이벤트
    socket.on('disconnect', (reason) => {
      realtimeMetrics.socketConnectionsTotal.inc({ status: 'disconnected' });
      realtimeMetrics.activeSocketConnections.dec({ namespace: socket.nsp.name });
      realtimeMetrics.socketEventsTotal.inc({ event: 'disconnect' });
    });
    
    // 에러 이벤트
    socket.on('error', (error) => {
      realtimeMetrics.socketEventsTotal.inc({ event: 'error' });
      logger.error('Socket.IO 에러', { 
        error: error.message,
        socketId: socket.id,
        userId: socket.userId
      });
    });
  });
}

module.exports = {
  register,
  setupMetricsMiddleware,
  errorMetricsMiddleware,
  monitorSocketIO,
  metrics: {
    httpRequestDurationMicroseconds,
    httpRequestsTotal,
    httpActiveConnections,
    apiErrorsTotal,
    ...realtimeMetrics
  }
}; 
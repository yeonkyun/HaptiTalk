/**
 * Prometheus 메트릭 설정
 * session-service용 메트릭 모듈
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

// 세션 관련 메트릭
const sessionMetrics = {
  sessionCreationsTotal: new client.Counter({
    name: 'session_creations_total',
    help: '세션 생성 총 수',
    labelNames: ['status'] // success, failed
  }),
  sessionUpdatesTotal: new client.Counter({
    name: 'session_updates_total',
    help: '세션 업데이트 총 수',
    labelNames: ['status', 'type'] // status: success, failed, type: join, leave, etc.
  }),
  sessionEndTotal: new client.Counter({
    name: 'session_end_total',
    help: '세션 종료 총 수',
    labelNames: ['status'] // success, failed, timeout
  }),
  activeSessionsGauge: new client.Gauge({
    name: 'active_sessions_gauge',
    help: '현재 활성 세션 수'
  }),
  sessionDurationSeconds: new client.Histogram({
    name: 'session_duration_seconds',
    help: '세션 지속 시간 (초)',
    buckets: [60, 300, 600, 1200, 1800, 3600, 7200]
  }),
  sessionParticipantsGauge: new client.Gauge({
    name: 'session_participants_gauge',
    help: '세션별 참가자 수',
    labelNames: ['session_id']
  })
};

// 세션 메트릭 등록
Object.values(sessionMetrics).forEach(metric => register.registerMetric(metric));

// Express.js 미들웨어 설정
function setupMetricsMiddleware(app) {
  // 메트릭 엔드포인트 설정
  app.get('/metrics', async function(req, res) {
    try {
      logger.info('메트릭 엔드포인트 접근', { path: '/metrics' });
      res.set('Content-Type', register.contentType);
      res.end(await register.metrics());
    } catch (error) {
      logger.error('메트릭 생성 중 오류 발생', { error: error.message, stack: error.stack });
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

module.exports = {
  register,
  setupMetricsMiddleware,
  errorMetricsMiddleware,
  metrics: {
    httpRequestDurationMicroseconds,
    httpRequestsTotal,
    httpActiveConnections,
    apiErrorsTotal,
    ...sessionMetrics
  }
}; 
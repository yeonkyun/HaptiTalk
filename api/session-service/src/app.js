// OpenTelemetry 트레이싱 초기화 (가장 먼저 로드되어야 함)
require('./utils/tracing');

const express = require('express');
const cors = require('cors');
const morgan = require('morgan');
const helmet = require('helmet');
const compression = require('compression');
const dotenv = require('dotenv');
const {sequelize, testConnection, syncModels} = require('./config/database');
const {redisClient} = require('./config/redis');
const sessionRoutes = require('./routes/session.routes');
const errorHandler = require('./middleware/errorHandler.middleware');
const logger = require('./utils/logger');
const metrics = require('./utils/metrics');
const { v4: uuidv4 } = require('uuid');
const { swaggerUi, specs } = require('./utils/swagger');

// 환경변수 로드
dotenv.config();

// Express 앱 생성
const app = express();
const PORT = process.env.PORT || 3002;

// 요청 ID 미들웨어 - 각 요청에 고유 ID 부여
app.use((req, res, next) => {
    req.id = req.headers['x-request-id'] || uuidv4();
    res.setHeader('X-Request-ID', req.id);
    next();
});

// 미들웨어 설정
app.use(helmet()); // 보안 헤더 설정
app.use(compression()); // 응답 압축
app.use(cors()); // CORS 설정

// 로깅 미들웨어 추가
app.use(logger.requestMiddleware);

// 메트릭 미들웨어 설정
metrics.setupMetricsMiddleware(app);

// 명시적 메트릭 라우트 등록
app.get('/metrics', async (req, res) => {
  try {
    logger.info('명시적 메트릭 엔드포인트 접근', { path: '/metrics' });
    res.set('Content-Type', metrics.register.contentType);
    res.end(await metrics.register.metrics());
  } catch (error) {
    logger.error('명시적 메트릭 생성 중 오류 발생', { error: error.message, stack: error.stack });
    res.status(500).end();
  }
});

// Morgan 설정 변경 - JSON 형식 로그 출력
app.use(morgan((tokens, req, res) => {
    return JSON.stringify({
        method: tokens.method(req, res),
        url: tokens.url(req, res),
        status: tokens.status(req, res),
        contentLength: tokens.res(req, res, 'content-length'),
        responseTime: tokens['response-time'](req, res),
        timestamp: new Date().toISOString(),
        requestId: req.id,
        userAgent: tokens['user-agent'](req, res)
    });
}, { stream: { write: message => logger.http(message) } }));

app.use(express.json()); // JSON 파싱
app.use(express.urlencoded({extended: true})); // URL 인코딩 파싱

// 라우트 설정
app.use('/api/v1/sessions', sessionRoutes);

// Swagger UI 설정
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs, { explorer: true }));

// 상태 확인 라우트
app.get('/health', (req, res) => {
    res.status(200).json({
        service: 'session-service',
        status: 'ok',
        timestamp: new Date().toISOString()
    });
});

// 로깅 에러 미들웨어 추가
app.use(logger.errorMiddleware);

// 메트릭 에러 미들웨어 추가
app.use(metrics.errorMetricsMiddleware);

// 404 처리 미들웨어
app.use(errorHandler.notFoundHandler);

// 에러 처리 미들웨어
if (process.env.NODE_ENV === 'production') {
    app.use(errorHandler.productionErrorHandler);
} else {
    app.use(errorHandler.developmentErrorHandler);
}

// 서버 시작 함수
const startServer = async () => {
    try {
        // 데이터베이스 연결 테스트
        const dbConnected = await testConnection();

        if (!dbConnected) {
            logger.error('Failed to connect to database. Exiting...', {
                component: 'database',
                status: 'failed'
            });
            process.exit(1);
        }

        // 개발 환경에서는 모델 동기화 (선택 사항)
        if (process.env.NODE_ENV === 'development' && process.env.SYNC_MODELS === 'true') {
            await syncModels(false); // force: false
        }

        // 서버 시작
        app.listen(PORT, () => {
            logger.info(`Session service running on port ${PORT}`, { 
                port: PORT, 
                environment: process.env.NODE_ENV,
                node_version: process.version
            });
        });
    } catch (error) {
        logger.error('Error starting server:', { 
            error: error.message, 
            stack: error.stack,
            component: 'startup'
        });
        process.exit(1);
    }
};

// Redis 연결 오류 처리
redisClient.on('error', (err) => {
    logger.error('Redis connection error:', { 
        error: err.message,
        stack: err.stack,
        component: 'redis'
    });
    if (process.env.NODE_ENV === 'production') {
        process.exit(1);
    }
});

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection', { 
        reason: reason instanceof Error ? reason.message : reason,
        stack: reason instanceof Error ? reason.stack : undefined,
        promise
    });
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception', { 
        error: error.message, 
        stack: error.stack
    });
    process.exit(1);
});

// 서버 시작
startServer();

// 깔끔한 종료 처리
const gracefulShutdown = async () => {
    logger.info('Shutting down gracefully...', {
        component: 'lifecycle',
        action: 'shutdown'
    });

    try {
        // 활성 연결 종료
        await sequelize.close();
        logger.info('Database connections closed', {
            component: 'database',
            status: 'closed'
        });

        await redisClient.quit();
        logger.info('Redis connections closed', {
            component: 'redis',
            status: 'closed'
        });

        // 정상 종료
        process.exit(0);
    } catch (error) {
        logger.error('Error during shutdown:', { 
            error: error.message,
            stack: error.stack
        });
        process.exit(1);
    }
};

// 종료 신호 처리
process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

module.exports = app;
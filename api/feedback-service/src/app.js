// OpenTelemetry 트레이싱 초기화 (가장 먼저 로드되어야 함)
require('./utils/tracing');

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const {errorHandler} = require('./middleware/errorHandler.middleware');
const logger = require('./utils/logger');
const metrics = require('./utils/metrics');
const routes = require('./routes');
const appConfig = require('./config/app');
const {connectToMongoDB} = require('./config/mongodb');
const { v4: uuidv4 } = require('uuid');
const { swaggerUi, specs } = require('./utils/swagger');

// Express 앱 초기화
const app = express();

// 요청 ID 미들웨어 - 각 요청에 고유 ID 부여
app.use((req, res, next) => {
    req.id = req.headers['x-request-id'] || uuidv4();
    res.setHeader('X-Request-ID', req.id);
    next();
});

// 기본 미들웨어 설정
app.use(helmet());
app.use(cors());

// 로깅 미들웨어 추가
app.use(logger.requestMiddleware);

// 메트릭 미들웨어 설정
metrics.setupMetricsMiddleware(app);

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
}, { stream: logger.stream }));

app.use(express.json());
app.use(express.urlencoded({extended: true}));

// API 라우트 설정
app.use('/api/v1/feedback', routes);

// Swagger UI 설정
app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(specs, { explorer: true }));

// 헬스체크 엔드포인트
app.get('/health', (req, res) => {
    res.status(200).json({status: 'OK', service: 'feedback-service'});
});

// 로깅 에러 미들웨어 추가
app.use(logger.errorMiddleware);

// 메트릭 에러 미들웨어 추가
app.use(metrics.errorMetricsMiddleware);

// 에러 핸들링 미들웨어
app.use(errorHandler);

// 서버 시작
const PORT = appConfig.port || 3003;
app.listen(PORT, async () => {
    logger.info(`Feedback service is running on port ${PORT}`, { 
        port: PORT, 
        environment: process.env.NODE_ENV,
        node_version: process.version
    });
    
    // MongoDB 연결 초기화
    try {
        await connectToMongoDB();
        logger.info('MongoDB connection initialized successfully', {
            component: 'database',
            type: 'mongodb',
            status: 'connected'
        });
    } catch (err) {
        logger.error('Failed to initialize MongoDB connection:', { 
            error: err.message, 
            stack: err.stack,
            component: 'database',
            type: 'mongodb'
        });
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

module.exports = app;
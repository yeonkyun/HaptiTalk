const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const {sequelize} = require('./config/database');
const {errorHandler} = require('./middleware/errorHandler.middleware');
const routes = require('./routes');
const logger = require('./utils/logger');
const metrics = require('./utils/metrics');
const { v4: uuidv4 } = require('uuid');

// Express 앱 초기화
const app = express();
const port = process.env.PORT || 3004;

// 요청 ID 미들웨어 - 각 요청에 고유 ID 부여
app.use((req, res, next) => {
    req.id = req.headers['x-request-id'] || uuidv4();
    res.setHeader('X-Request-ID', req.id);
    next();
});

// 미들웨어 설정
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
}, { stream: { write: message => logger.http(message) } }));

app.use(express.json());
app.use(express.urlencoded({extended: true}));

// 헬스체크 엔드포인트
app.get('/health', (req, res) => {
    res.status(200).json({status: 'UP', service: 'user-service'});
});

// API 라우트 설정
app.use('/api/v1/users', routes);

// 로깅 에러 미들웨어 추가
app.use(logger.errorMiddleware);

// 메트릭 에러 미들웨어 추가
app.use(metrics.errorMetricsMiddleware);

// 오류 처리 미들웨어
app.use(errorHandler);

// 서버 시작
const startServer = async () => {
    try {
        // 데이터베이스 연결 확인
        await sequelize.authenticate();
        logger.info('Database connection has been established successfully.', { component: 'database' });

        // 서버 시작
        app.listen(port, () => {
            logger.info(`User service running on port ${port}`, { 
                port: port, 
                environment: process.env.NODE_ENV,
                node_version: process.version
            });
        });
    } catch (error) {
        logger.error('Unable to start server:', { 
            error: error.message, 
            stack: error.stack,
            component: 'startup'
        });
        process.exit(1);
    }
};

// 서버 시작 함수 호출
startServer();

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
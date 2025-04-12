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

// 환경변수 로드
dotenv.config();

// Express 앱 생성
const app = express();
const PORT = process.env.PORT || 3002;

// 미들웨어 설정
app.use(helmet()); // 보안 헤더 설정
app.use(compression()); // 응답 압축
app.use(cors()); // CORS 설정
app.use(express.json()); // JSON 파싱
app.use(express.urlencoded({extended: true})); // URL 인코딩 파싱

// 로깅 미들웨어
app.use(morgan('dev', {
    stream: {
        write: (message) => logger.info(message.trim())
    }
}));

// 라우트 설정
app.use('/api/v1/sessions', sessionRoutes);

// 상태 확인 라우트
app.get('/health', (req, res) => {
    res.status(200).json({
        service: 'session-service',
        status: 'ok',
        timestamp: new Date().toISOString()
    });
});

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
            logger.error('Failed to connect to database. Exiting...');
            process.exit(1);
        }

        // 개발 환경에서는 모델 동기화 (선택 사항)
        if (process.env.NODE_ENV === 'development' && process.env.SYNC_MODELS === 'true') {
            await syncModels(false); // force: false
        }

        // 서버 시작
        app.listen(PORT, () => {
            logger.info(`Session service running on port ${PORT}`);
        });
    } catch (error) {
        logger.error('Error starting server:', error);
        process.exit(1);
    }
};

// Redis 연결 오류 처리
redisClient.on('error', (err) => {
    logger.error('Redis connection error:', err);
    if (process.env.NODE_ENV === 'production') {
        process.exit(1);
    }
});

// 서버 시작
startServer();

// 깔끔한 종료 처리
const gracefulShutdown = async () => {
    logger.info('Shutting down gracefully...');

    try {
        // 활성 연결 종료
        await sequelize.close();
        logger.info('Database connections closed');

        await redisClient.quit();
        logger.info('Redis connections closed');

        // 정상 종료
        process.exit(0);
    } catch (error) {
        logger.error('Error during shutdown:', error);
        process.exit(1);
    }
};

// 종료 신호 처리
process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

module.exports = app;
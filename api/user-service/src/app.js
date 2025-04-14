const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const {sequelize} = require('./config/database');
const {errorHandler} = require('./middleware/errorHandler.middleware');
const routes = require('./routes');
const logger = require('./utils/logger');

// Express 앱 초기화
const app = express();
const port = process.env.PORT || 3004;

// 미들웨어 설정
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({extended: true}));

// 로깅 미들웨어
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.originalUrl}`);
    next();
});

// 헬스체크 엔드포인트
app.get('/health', (req, res) => {
    res.status(200).json({status: 'UP', service: 'user-service'});
});

// API 라우트 설정
app.use('/api/v1/users', routes);

// 오류 처리 미들웨어
app.use(errorHandler);

// 서버 시작
const startServer = async () => {
    try {
        // 데이터베이스 연결 확인
        await sequelize.authenticate();
        logger.info('Database connection has been established successfully.');

        // 서버 시작
        app.listen(port, () => {
            logger.info(`User service running on port ${port}`);
        });
    } catch (error) {
        logger.error('Unable to start server:', error);
        process.exit(1);
    }
};

// 서버 시작 함수 호출
startServer();

module.exports = app;
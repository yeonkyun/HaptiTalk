const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const {errorHandler} = require('./middleware/errorHandler.middleware');
const logger = require('./utils/logger');
const routes = require('./routes');
const appConfig = require('./config/app');

// Express 앱 초기화
const app = express();

// 기본 미들웨어 설정
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({extended: true}));

// 로깅 미들웨어
app.use((req, res, next) => {
    logger.info(`${req.method} ${req.originalUrl}`);
    next();
});

// API 라우트 설정
app.use('/api/v1/feedback', routes);

// 헬스체크 엔드포인트
app.get('/health', (req, res) => {
    res.status(200).json({status: 'OK', service: 'feedback-service'});
});

// 에러 핸들링 미들웨어
app.use(errorHandler);

// 서버 시작
const PORT = appConfig.port || 3003;
app.listen(PORT, () => {
    logger.info(`Feedback service is running on port ${PORT}`);
});

module.exports = app;
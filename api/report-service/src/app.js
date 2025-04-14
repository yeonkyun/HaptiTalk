const express = require('express');
const cors = require('cors');
const logger = require('./utils/logger');
const {errorHandler} = require('./middleware/errorHandler.middleware');
const routes = require('./routes');

// 앱 초기화
const app = express();
const port = process.env.PORT || 3005;

// 미들웨어 설정
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
    res.status(200).send('OK');
});

// API 라우트
app.use('/api/v1/reports', routes);

// 오류 처리 미들웨어
app.use(errorHandler);

// 서버 시작
app.listen(port, () => {
    logger.info(`Report service running on port ${port}`);
});

module.exports = app;
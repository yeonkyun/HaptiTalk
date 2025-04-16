const express = require('express');
const http = require('http');
const {Server} = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const {createRedisClient} = require('./config/redis');
const authMiddleware = require('./middleware/auth.middleware');
const logger = require('./utils/logger');
const {setServiceAuthToken} = require('./config/api-client');

// 기본 설정
const PORT = process.env.PORT || 3001;

// 서비스 간 통신을 위한 API 토큰
const INTER_SERVICE_TOKEN = process.env.INTER_SERVICE_TOKEN || 'default-service-token';

// Redis 클라이언트 초기화
const redisClient = createRedisClient();

// Express 앱 초기화
const app = express();
const server = http.createServer(app);

// Express 미들웨어
app.use(helmet());
app.use(cors());
app.use(express.json());

// 상태 확인 엔드포인트
app.get('/health', (req, res) => {
    res.status(200).send('OK');
});

// 버전 정보 엔드포인트
app.get('/api/v1/realtime/version', (req, res) => {
    res.json({
        service: 'realtime-service',
        version: '0.1.0',
        status: 'running'
    });
});

// Socket.io 초기화
const io = new Server(server, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST']
    },
    path: '/socket.io/'
});

// Socket.io 미들웨어 적용
io.use(async (socket, next) => {
    try {
        const token = socket.handshake.auth.token;
        if (!token) {
            return next(new Error('인증 토큰이 필요합니다'));
        }

        // 토큰 검증
        const user = await authMiddleware.verifySocketToken(token, redisClient);
        socket.user = user;
        next();
    } catch (error) {
        logger.error(`소켓 인증 오류: ${error.message}`);
        next(new Error('유효하지 않은 토큰입니다'));
    }
});

// 이벤트 핸들러 등록
require('./events')(io, redisClient);

// 서버 시작
const startServer = async () => {
    try {
        // Redis 연결 확인
        await redisClient.ping();
        logger.info('Redis 서버 연결 성공');

        // 서비스 간 통신을 위한 API 토큰 설정
        setServiceAuthToken(INTER_SERVICE_TOKEN);
        logger.info('서비스 간 통신을 위한 인증 토큰이 설정되었습니다');

        // 서버 시작
        server.listen(PORT, () => {
            logger.info(`실시간 서비스가 포트 ${PORT}에서 실행 중입니다`);
        });
    } catch (error) {
        logger.error(`서버 시작 실패: ${error.message}`);
        process.exit(1);
    }
};

// 종료 시 정리 작업
const gracefulShutdown = async () => {
    logger.info('서버 종료 중...');

    // Socket.io 연결 종료
    io.close(() => {
        logger.info('모든 WebSocket 연결이 종료되었습니다');
    });

    // Redis 연결 종료
    await redisClient.quit();
    logger.info('Redis 연결이 종료되었습니다');

    // HTTP 서버 종료
    server.close(() => {
        logger.info('HTTP 서버가 종료되었습니다');
        process.exit(0);
    });

    // 5초 후 강제 종료
    setTimeout(() => {
        logger.error('서버 강제 종료');
        process.exit(1);
    }, 5000);
};

// 종료 시그널 처리
process.on('SIGTERM', gracefulShutdown);
process.on('SIGINT', gracefulShutdown);

// 서버 시작
startServer();

module.exports = {app, server, io};
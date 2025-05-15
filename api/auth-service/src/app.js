// OpenTelemetry 트레이싱 초기화 (가장 먼저 로드되어야 함)
require('./utils/tracing');

require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const {sequelize} = require('./config/database');
const {redisClient} = require('./config/redis');
const logger = require('./utils/logger');
const metrics = require('./utils/metrics');
const authRoutes = require('./routes/auth.routes');
const deviceRoutes = require('./routes/device.routes');
const errorHandler = require('./middleware/errorHandler.middleware');
const { v4: uuidv4 } = require('uuid');

// 회복성 관련 임포트
const { userServiceClient, sessionServiceClient, dbResilience } = require('./utils/serviceClient');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// 요청 ID 미들웨어 - 각 요청에 고유 ID 부여
app.use((req, res, next) => {
    req.id = req.headers['x-request-id'] || uuidv4();
    res.setHeader('X-Request-ID', req.id);
    next();
});

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // CORS support

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

app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({extended: true})); // Parse URL-encoded bodies

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({status: 'ok', service: 'auth-service'});
});

// Resilience status endpoint
app.get('/resilience/status', (req, res) => {
    const status = {
        userService: {
            healthy: true, // 간소화된 헬스 체크
            stats: {} // 필요한 경우 실제 통계 추가
        },
        sessionService: {
            healthy: true,
            stats: {}
        },
        database: {
            healthy: true,
            stats: {}
        }
    };
    
    res.status(200).json({
        service: 'auth-service',
        resilience: status
    });
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/devices', deviceRoutes);


app.get('/token/status', (req, res) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(400).json({
            success: false,
            message: 'Access token is required'
        });
    }
    
    const token = authHeader.split(' ')[1];
    
    // 토큰 서비스로 리디렉션
    const tokenService = require('./services/token.service');
    
    tokenService.checkTokenStatus(token)
        .then(status => {
            return res.status(200).json({
                success: true,
                data: status
            });
        })
        .catch(error => {
            logger.error('Error checking token status', { error: error.message, stack: error.stack });
            return res.status(500).json({
                success: false,
                message: 'Error checking token status'
            });
        });
});

// 토큰 사전 갱신 엔드포인트 추가
app.post('/token/proactive-refresh', (req, res) => {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
        return res.status(400).json({
            success: false,
            message: 'Access token is required'
        });
    }
    
    const token = authHeader.split(' ')[1];
    
    // 토큰 서비스로 리디렉션
    const tokenService = require('./services/token.service');
    
    tokenService.proactiveTokenRefresh(token)
        .then(newToken => {
            if (!newToken) {
                return res.status(200).json({
                    success: true,
                    data: {
                        refreshed: false,
                        message: 'Token refresh not needed'
                    }
                });
            }
            
            return res.status(200).json({
                success: true,
                data: {
                    refreshed: true,
                    access_token: newToken.token,
                    expires_in: Math.floor((newToken.expires - new Date()) / 1000)
                },
                message: 'Token refreshed proactively'
            });
        })
        .catch(error => {
            logger.error('Error refreshing token', { error: error.message, stack: error.stack });
            return res.status(500).json({
                success: false,
                message: 'Error refreshing token'
            });
        });
});

// 로깅 에러 미들웨어 추가
app.use(logger.errorMiddleware);

// 메트릭 에러 미들웨어 추가
app.use(metrics.errorMetricsMiddleware);

// Error handling middleware
app.use(errorHandler);

// Start server
async function startServer() {
    try {
        // Connect to PostgreSQL
        await sequelize.authenticate();
        logger.info('PostgreSQL connection established', { component: 'database' });

        // Sync database models
        await sequelize.sync();
        logger.info('Database models synchronized', { component: 'database' });

        // Connect to Redis
        await redisClient.connect();
        logger.info('Redis connection established', { component: 'cache' });

        // Start Express server
        app.listen(PORT, () => {
            logger.info(`Auth service running on port ${PORT}`, { 
                port: PORT, 
                environment: process.env.NODE_ENV,
                node_version: process.version
            });
        });
    } catch (error) {
        logger.error('Failed to start server', { 
            error: error.message, 
            stack: error.stack,
            component: 'startup'
        });
        process.exit(1);
    }
}

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

// Graceful shutdown
process.on('SIGTERM', async () => {
    logger.info('SIGTERM signal received, shutting down gracefully');
    
    // 데이터베이스 연결 종료
    await sequelize.close();
    logger.info('Database connection closed');
    
    // Redis 연결 종료 
    await redisClient.disconnect();
    logger.info('Redis connection closed');
    
    process.exit(0);
});

// Export app for testing
module.exports = app;

// Start server if not in test mode
if (process.env.NODE_ENV !== 'test') {
    startServer();
}

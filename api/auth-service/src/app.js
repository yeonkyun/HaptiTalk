require('dotenv').config();
const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const {sequelize} = require('./config/database');
const {redisClient} = require('./config/redis');
const logger = require('./utils/logger');
const authRoutes = require('./routes/auth.routes');
const deviceRoutes = require('./routes/device.routes');
const errorHandler = require('./middleware/errorHandler.middleware');

// Initialize Express app
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet()); // Security headers
app.use(cors()); // CORS support
app.use(morgan('combined', {stream: {write: message => logger.info(message.trim())}})); // Request logging
app.use(express.json()); // Parse JSON bodies
app.use(express.urlencoded({extended: true})); // Parse URL-encoded bodies

// Health check endpoint
app.get('/health', (req, res) => {
    res.status(200).json({status: 'ok', service: 'auth-service'});
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
            console.error('Error checking token status:', error);
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
            console.error('Error refreshing token:', error);
            return res.status(500).json({
                success: false,
                message: 'Error refreshing token'
            });
        });
});

// Error handling middleware
app.use(errorHandler);

// Start server
async function startServer() {
    try {
        // Connect to PostgreSQL
        await sequelize.authenticate();
        logger.info('PostgreSQL connection established');

        // Sync database models
        await sequelize.sync();
        logger.info('Database models synchronized');

        // Connect to Redis
        await redisClient.connect();
        logger.info('Redis connection established');

        // Start Express server
        app.listen(PORT, () => {
            logger.info(`Auth service running on port ${PORT}`);
        });
    } catch (error) {
        logger.error('Failed to start server:', error);
        process.exit(1);
    }
}

// Handle unhandled promise rejections
process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

// Handle uncaught exceptions
process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception:', error);
    process.exit(1);
});

// Start the server
startServer();

module.exports = app; // For testing purposes
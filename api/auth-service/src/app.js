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
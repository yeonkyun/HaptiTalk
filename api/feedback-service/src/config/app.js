const config = {
    port: process.env.PORT || 3003,
    env: process.env.NODE_ENV || 'development',
    logLevel: process.env.LOG_LEVEL || 'info',
    apiVersion: 'v1',
    corsOptions: {
        origin: '*',
        methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
        allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
    },
    rateLimits: {
        windowMs: 15 * 60 * 1000, // 15분
        max: 100 // 15분당 최대 요청 수
    },
    defaults: {
        pageSize: 10,
        hapticStrength: 5,
        minimumFeedbackInterval: 10, // 초
        feedbackFrequency: 'medium',
        priorityThreshold: 'medium'
    }
};

module.exports = config;
/**
 * 애플리케이션 설정 관리
 */

// 환경 설정
const nodeEnv = process.env.NODE_ENV || 'development';
const isDevelopment = nodeEnv === 'development';
const isProduction = nodeEnv === 'production';
const isTest = nodeEnv === 'test';

// 애플리케이션 기본 설정
const appConfig = {
    env: nodeEnv,
    port: parseInt(process.env.PORT || '3005', 10),
    logLevel: process.env.LOG_LEVEL || (isDevelopment ? 'debug' : 'info'),

    // 리포트 설정
    reports: {
        pdfStorage: process.env.PDF_STORAGE_PATH || '/tmp/reports',
        defaultFormat: 'json',
        maxComparisonSessions: 5,
        chartWidth: 800,
        chartHeight: 600
    },

    // 캐싱 설정
    cache: {
        enabled: isProduction,
        reportTTL: 3600, // 1시간
        statsTTL: 900,   // 15분
        progressTTL: 1800 // 30분
    },

    // 코어 설정
    cors: {
        allowedOrigins: process.env.ALLOWED_ORIGINS ?
            process.env.ALLOWED_ORIGINS.split(',') :
            ['http://localhost:3000', 'http://localhost:8000']
    }
};

module.exports = appConfig;
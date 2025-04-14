const winston = require('winston');
const appConfig = require('../config/app');

// 로그 레벨 설정
const logLevel = appConfig.logLevel || 'info';

// 로그 포맷 정의
const logFormat = winston.format.combine(
    winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
    winston.format.errors({ stack: true }),
    winston.format.splat(),
    winston.format.json()
);

// 로거 인스턴스 생성
const logger = winston.createLogger({
    level: logLevel,
    format: logFormat,
    defaultMeta: { service: 'feedback-service' },
    transports: [
        // 콘솔 로그
        new winston.transports.Console({
            format: winston.format.combine(
                winston.format.colorize(),
                winston.format.printf(
                    info => `${info.timestamp} ${info.level}: ${info.message}${info.stack ? '\n' + info.stack : ''}`
                )
            )
        })
    ]
});

// 프로덕션 환경에서는 파일 로그 추가
if (process.env.NODE_ENV === 'production') {
    logger.add(new winston.transports.File({
        filename: 'logs/error.log',
        level: 'error',
        maxsize: 5242880, // 5MB
        maxFiles: 5
    }));

    logger.add(new winston.transports.File({
        filename: 'logs/combined.log',
        maxsize: 5242880, // 5MB
        maxFiles: 5
    }));
}

// HTTP 요청 로깅 포맷
logger.stream = {
    write: message => {
        logger.info(message.trim());
    }
};

module.exports = logger;
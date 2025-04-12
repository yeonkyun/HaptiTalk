const winston = require('winston');
const {format, transports} = winston;

// 로그 레벨 설정
const logLevel = process.env.LOG_LEVEL || 'info';

// 로그 포맷 설정
const logFormat = format.combine(
    format.timestamp({format: 'YYYY-MM-DD HH:mm:ss'}),
    format.errors({stack: true}),
    format.splat(),
    format.json()
);

// 콘솔 출력용 포맷
const consoleFormat = format.combine(
    format.colorize(),
    format.timestamp({format: 'YYYY-MM-DD HH:mm:ss'}),
    format.printf(({timestamp, level, message, ...meta}) => {
        // 에러 스택이 있으면 출력
        const stack = meta.stack ? `\n${meta.stack}` : '';

        // 메타데이터가 있으면 JSON 형태로 출력
        const metaData = Object.keys(meta).length && !meta.stack
            ? `\n${JSON.stringify(meta, null, 2)}`
            : '';

        return `[${timestamp}] ${level}: ${message}${stack}${metaData}`;
    })
);

// Winston 로거 인스턴스 생성
const logger = winston.createLogger({
    level: logLevel,
    format: logFormat,
    defaultMeta: {service: 'session-service'},
    transports: [
        // 콘솔 출력 설정
        new transports.Console({
            format: consoleFormat
        }),

        // 에러 로그 파일 출력 설정
        new transports.File({
            filename: 'logs/error.log',
            level: 'error',
            maxsize: 5242880, // 5MB
            maxFiles: 5
        }),

        // 전체 로그 파일 출력 설정
        new transports.File({
            filename: 'logs/combined.log',
            maxsize: 5242880, // 5MB
            maxFiles: 5
        })
    ]
});

// 개발 환경에서는 console에 더 깔끔하게 출력
if (process.env.NODE_ENV !== 'production') {
    logger.format = consoleFormat;
}

// uncaughtException 로깅
process.on('uncaughtException', (error) => {
    logger.error('Uncaught Exception:', error);

    // 안전하게 프로세스 종료 (선택사항)
    if (process.env.NODE_ENV === 'production') {
        process.exit(1);
    }
});

// unhandledRejection 로깅
process.on('unhandledRejection', (reason, promise) => {
    logger.error('Unhandled Rejection at:', {promise, reason});
});

module.exports = logger;
const winston = require('winston');
const { format } = winston;

// 서비스 이름 설정
const SERVICE_NAME = 'report-service';

// Define log format with standardized structure
const logFormat = format.combine(
    format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss.SSS' }),
    format.errors({ stack: true }),
    format.metadata({ fillExcept: ['message', 'level', 'timestamp', 'service'] }),
    format.json()
);

// Create logger instance
const logger = winston.createLogger({
    level: process.env.LOG_LEVEL || 'info',
    format: logFormat,
    defaultMeta: { 
        service: SERVICE_NAME,
        // host 정보 추가
        host: process.env.HOSTNAME || 'localhost',
        environment: process.env.NODE_ENV || 'development'
    },
    transports: [
        // 파일 로깅 설정
        new winston.transports.File({ filename: 'logs/error.log', level: 'error' }),
        new winston.transports.File({ filename: 'logs/combined.log' }),
    ],
    // 종료 시 로깅 처리
    exitOnError: false
});

// 개발 환경에서는 콘솔에 출력
if (process.env.NODE_ENV !== 'production') {
    logger.add(new winston.transports.Console({
        format: format.combine(
            format.colorize(),
            format.printf(info => {
                const { timestamp, level, message, metadata } = info;
                const metaStr = Object.keys(metadata).length ? 
                    ` ${JSON.stringify(metadata)}` : '';
                
                return `${timestamp} ${level}: [${SERVICE_NAME}] ${message}${metaStr}`;
            })
        ),
    }));
}

// HTTP 요청 로깅 미들웨어
logger.requestMiddleware = (req, res, next) => {
    const start = Date.now();
    const requestId = req.headers['x-request-id'] || req.id;
    
    // 요청 정보 로깅
    logger.info(`Request received: ${req.method} ${req.originalUrl}`, {
        requestId,
        method: req.method,
        url: req.originalUrl,
        ip: req.ip,
        headers: req.headers,
        userId: req.user?.id
    });

    // 응답이 끝나면 결과 로깅
    res.on('finish', () => {
        const duration = Date.now() - start;
        const message = `Request completed: ${req.method} ${req.originalUrl} ${res.statusCode} ${duration}ms`;
        
        const logObject = {
            requestId,
            method: req.method,
            url: req.originalUrl,
            statusCode: res.statusCode,
            duration,
            ip: req.ip,
            userId: req.user?.id
        };

        if (res.statusCode >= 400) {
            logger.warn(message, logObject);
        } else {
            logger.info(message, logObject);
        }
    });

    next();
};

// 에러 핸들링 미들웨어
logger.errorMiddleware = (err, req, res, next) => {
    const requestId = req.headers['x-request-id'] || req.id;

    logger.error(`Error processing request: ${err.message}`, {
        requestId,
        method: req.method,
        url: req.originalUrl,
        statusCode: err.status || 500,
        error: err.message,
        stack: err.stack,
        userId: req.user?.id
    });

    next(err);
};

// 로깅 스트림 (morgan 통합용)
logger.stream = {
    write: message => {
        logger.http(message.trim());
    }
};

module.exports = logger;
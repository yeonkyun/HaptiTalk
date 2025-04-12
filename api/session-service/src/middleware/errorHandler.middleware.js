const httpStatus = require('http-status');
const logger = require('../utils/logger');

/**
 * 에러 핸들러 미들웨어
 * 애플리케이션 전체에서 발생하는 에러를 처리
 */
const errorHandler = {
    /**
     * 개발 환경용 에러 핸들러 (자세한 에러 정보 포함)
     * @param {Error} err - 발생한 에러 객체
     * @param {Object} req - 요청 객체
     * @param {Object} res - 응답 객체
     * @param {Function} next - 다음 미들웨어 호출 함수
     */
    developmentErrorHandler: (err, req, res, next) => {
        const statusCode = err.statusCode || httpStatus.INTERNAL_SERVER_ERROR;

        logger.error(`Error [${req.method} ${req.originalUrl}]: ${err.message}`, {
            stack: err.stack,
            metadata: {
                url: req.originalUrl,
                method: req.method,
                ip: req.ip,
                user: req.user ? req.user.id : 'unauthorized'
            }
        });

        return res.status(statusCode).json({
            success: false,
            message: err.message,
            stack: err.stack,
            error: err
        });
    },

    /**
     * 프로덕션 환경용 에러 핸들러 (최소한의 에러 정보만 포함)
     * @param {Error} err - 발생한 에러 객체
     * @param {Object} req - 요청 객체
     * @param {Object} res - 응답 객체
     * @param {Function} next - 다음 미들웨어 호출 함수
     */
    productionErrorHandler: (err, req, res, next) => {
        const statusCode = err.statusCode || httpStatus.INTERNAL_SERVER_ERROR;

        // 로깅은 자세하게 하되, 응답은 간략하게
        logger.error(`Error [${req.method} ${req.originalUrl}]: ${err.message}`, {
            stack: err.stack,
            metadata: {
                url: req.originalUrl,
                method: req.method,
                ip: req.ip,
                user: req.user ? req.user.id : 'unauthorized'
            }
        });

        // 클라이언트에게는 최소한의 정보만 제공
        let message = '서버 오류가 발생했습니다.';

        // 4xx 에러는 상세 메시지 제공 가능 (클라이언트 측 오류)
        if (statusCode < 500) {
            message = err.message;
        }

        return res.status(statusCode).json({
            success: false,
            message
        });
    },

    /**
     * 404 Not Found 에러 핸들러
     * @param {Object} req - 요청 객체
     * @param {Object} res - 응답 객체
     */
    notFoundHandler: (req, res) => {
        logger.warn(`Not Found: ${req.method} ${req.originalUrl}`);

        return res.status(httpStatus.NOT_FOUND).json({
            success: false,
            message: '요청한 리소스를 찾을 수 없습니다.'
        });
    }
};

module.exports = errorHandler;
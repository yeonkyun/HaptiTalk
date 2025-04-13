const httpStatus = require('http-status');
const logger = require('../utils/logger');
const { formatResponse } = require('../utils/responseFormatter');

/**
 * 에러 핸들링 미들웨어
 */
const errorHandler = (err, req, res, next) => {
    // 기본 에러 정보
    let statusCode = err.statusCode || httpStatus.INTERNAL_SERVER_ERROR;
    let message = err.message || '서버에 오류가 발생했습니다.';
    let errorCode = err.code || 'internal_server_error';

    // 개발 환경에서 추가 로깅
    if (process.env.NODE_ENV === 'development') {
        logger.error(`Error in ${req.method} ${req.originalUrl}:`, {
            error: err.stack || err,
            body: req.body,
            params: req.params,
            query: req.query
        });
    } else {
        // 프로덕션 환경에서는 간소화된 로깅
        logger.error(`${req.method} ${req.originalUrl} - ${statusCode}: ${message}`);
    }

    // 특정 에러 유형에 따른 처리
    if (err.name === 'SequelizeValidationError' || err.name === 'SequelizeUniqueConstraintError') {
        statusCode = httpStatus.UNPROCESSABLE_ENTITY;
        errorCode = 'validation_error';

        const errors = err.errors.map(e => ({
            code: 'validation_error',
            field: e.path,
            message: e.message
        }));

        return res.status(statusCode).json(formatResponse(
            false,
            null,
            '데이터베이스 유효성 검사 오류가 발생했습니다.',
            null,
            errors
        ));
    }

    // JWT 인증 오류
    if (err.name === 'JsonWebTokenError' || err.name === 'TokenExpiredError') {
        statusCode = httpStatus.UNAUTHORIZED;
        errorCode = 'auth_error';
        message = '유효하지 않거나 만료된 토큰입니다.';
    }

    // 몽고DB 오류
    if (err.name === 'MongoError' || err.name === 'MongoServerError') {
        statusCode = err.code === 11000 ? httpStatus.CONFLICT : httpStatus.INTERNAL_SERVER_ERROR;
        errorCode = err.code === 11000 ? 'duplicate_key_error' : 'database_error';
        message = err.code === 11000 ? '중복된 데이터가 존재합니다.' : '데이터베이스 오류가 발생했습니다.';
    }

    // 최종 에러 응답
    return res.status(statusCode).json(formatResponse(
        false,
        null,
        message,
        null,
        [{
            code: errorCode,
            message
        }]
    ));
};

module.exports = {
    errorHandler
};
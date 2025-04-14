const logger = require('../utils/logger');

const errorHandler = (err, req, res, next) => {
    // 로그 기록
    logger.error(`Error: ${err.message}`, {stack: err.stack});

    // 검증 오류 처리
    if (err.name === 'ValidationError' || err.name === 'SequelizeValidationError') {
        return res.status(422).json({
            success: false,
            message: '유효성 검사 오류가 발생했습니다.',
            errors: err.errors?.map(e => ({
                code: 'validation_error',
                field: e.path || e.param,
                message: e.message
            })) || [{code: 'validation_error', message: err.message}]
        });
    }

    // 데이터베이스 오류 처리
    if (err.name === 'SequelizeUniqueConstraintError') {
        return res.status(409).json({
            success: false,
            message: '중복된 데이터가 존재합니다.',
            errors: err.errors?.map(e => ({
                code: 'conflict',
                field: e.path,
                message: `이미 사용 중인 ${e.path}입니다.`
            })) || [{code: 'conflict', message: err.message}]
        });
    }

    // 리소스 찾을 수 없음 오류
    if (err.name === 'NotFoundError') {
        return res.status(404).json({
            success: false,
            message: err.message || '요청한 리소스를 찾을 수 없습니다.',
            errors: [{code: 'resource_not_found'}]
        });
    }

    // 그 외 모든 오류
    const statusCode = err.statusCode || 500;
    return res.status(statusCode).json({
        success: false,
        message: err.message || '서버 내부 오류가 발생했습니다.',
        errors: [{code: err.code || 'internal_server_error'}]
    });
};

module.exports = {
    errorHandler
};
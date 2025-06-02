const { formatErrorResponse } = require('../utils/responseFormatter');
const logger = require('../utils/logger');

/**
 * 전역 오류 처리 미들웨어
 */
const errorHandler = (err, req, res, next) => {
    logger.error(`Error: ${err.message}`);
    logger.error(err.stack);

    // 사용자 정의 오류
    if (err.statusCode) {
        return formatErrorResponse(res, err.statusCode, err.message);
    }

    // MongoDB 오류
    if (err.name === 'MongoServerError') {
        if (err.code === 11000) {
            return formatErrorResponse(res, 409, '중복된 데이터가 있습니다');
        }
        return formatErrorResponse(res, 500, '데이터베이스 오류가 발생했습니다');
    }

    // 기타 오류
    return formatErrorResponse(res, 500, '서버 오류가 발생했습니다');
};

module.exports = {
    errorHandler
};
const { validationResult } = require('express-validator');
const httpStatus = require('http-status');
const { formatResponse } = require('../utils/responseFormatter');

/**
 * 유효성 검사 미들웨어
 * express-validator 라이브러리와 함께 사용
 */
const validate = (validations) => {
    return async (req, res, next) => {
        // 모든 유효성 검사 실행
        await Promise.all(validations.map(validation => validation.run(req)));

        // 에러 결과 확인
        const errors = validationResult(req);
        if (errors.isEmpty()) {
            return next();
        }

        // 유효성 검사 실패 시 에러 응답
        const formattedErrors = errors.array().map(error => ({
            code: 'validation_error',
            field: error.param,
            message: error.msg
        }));

        return res.status(httpStatus.UNPROCESSABLE_ENTITY).json(formatResponse(
            false,
            null,
            '유효성 검사 오류가 발생했습니다.',
            null,
            formattedErrors
        ));
    };
};

module.exports = {
    validate
};
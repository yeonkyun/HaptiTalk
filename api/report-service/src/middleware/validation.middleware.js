const { validationResult } = require('express-validator');
const { formatErrorResponse } = require('../utils/responseFormatter');

/**
 * express-validator를 사용한 요청 유효성 검사 미들웨어
 */
const validate = validations => {
    return async (req, res, next) => {
        await Promise.all(validations.map(validation => validation.run(req)));

        const errors = validationResult(req);
        if (errors.isEmpty()) {
            return next();
        }

        const formattedErrors = errors.array().map(error => ({
            field: error.param,
            message: error.msg
        }));

        return formatErrorResponse(
            res,
            422,
            '입력값 유효성 검사에 실패했습니다',
            formattedErrors
        );
    };
};

module.exports = {
    validate
};
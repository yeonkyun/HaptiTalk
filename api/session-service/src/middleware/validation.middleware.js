const {validationResult} = require('express-validator');
const httpStatus = require('http-status');

/**
 * 요청 유효성 검사 미들웨어
 */
const validationMiddleware = {
    /**
     * express-validator로 검증한 결과 처리
     * @param {Object} req - 요청 객체
     * @param {Object} res - 응답 객체
     * @param {Function} next - 다음 미들웨어 호출 함수
     */
    validate: (req, res, next) => {
        const errors = validationResult(req);

        if (!errors.isEmpty()) {
            // 에러 메시지 형식 가공
            const errorMessages = errors.array().map(error => ({
                param: error.param,
                value: error.value,
                message: error.msg
            }));

            return res.status(httpStatus.BAD_REQUEST).json({
                success: false,
                message: '입력값 검증에 실패했습니다.',
                errors: errorMessages
            });
        }

        next();
    }
};

module.exports = validationMiddleware;
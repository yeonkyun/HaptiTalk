/**
 * API 응답 형식을 일관되게 포맷팅하는 유틸리티
 */
function formatResponse(res, statusCode, success, data, message = '', meta = {}) {
    return res.status(statusCode).json({
        success,
        data,
        message,
        meta
    });
}

/**
 * 에러 응답 형식을 일관되게 포맷팅하는 유틸리티
 */
function formatErrorResponse(res, statusCode, message, errors = []) {
    return res.status(statusCode).json({
        success: false,
        message,
        errors
    });
}

module.exports = {
    formatResponse,
    formatErrorResponse
};
/**
 * 성공 응답 포맷 생성
 * @param {Object} data - 응답 데이터
 * @param {string} message - 성공 메시지
 * @param {Object} meta - 메타 데이터 (페이지네이션 등)
 * @returns {Object} 포맷된 응답 객체
 */
const formatSuccess = (data, message = null, meta = null) => {
    const response = {
        success: true,
        data: data || {}
    };

    if (message) {
        response.message = message;
    }

    if (meta) {
        response.meta = meta;
    }

    return response;
};

/**
 * 오류 응답 포맷 생성
 * @param {string} message - 오류 메시지
 * @param {Array} errors - 오류 세부 정보 배열
 * @returns {Object} 포맷된 오류 응답 객체
 */
const formatError = (message, errors = []) => {
    return {
        success: false,
        message: message,
        errors: errors
    };
};

module.exports = {
    formatSuccess,
    formatError
};
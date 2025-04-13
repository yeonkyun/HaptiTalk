/**
 * API 응답 형식 표준화
 * @param {boolean} success - 요청 성공 여부
 * @param {*} data - 응답 데이터
 * @param {string} message - 응답 메시지
 * @param {object} meta - 메타데이터 (페이지네이션 등)
 * @param {array} errors - 오류 정보 배열
 * @returns {object} 형식화된 응답 객체
 */
const formatResponse = (success, data = null, message = '', meta = null, errors = []) => {
    const response = {
        success
    };

    if (data !== null) {
        response.data = data;
    }

    if (message) {
        response.message = message;
    }

    if (errors && errors.length > 0) {
        response.errors = errors;
    }

    if (meta) {
        response.meta = meta;
    }

    return response;
};

module.exports = {
    formatResponse
};
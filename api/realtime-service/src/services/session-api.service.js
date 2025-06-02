const logger = require('../utils/logger');
const { sessionServiceClient } = require('../config/api-client');

/**
 * 세션 서비스 API 클라이언트
 * 세션 서비스와의 HTTP 통신을 담당
 */
class SessionApiService {
  /**
   * 세션 정보 조회
   * @param {string} sessionId - 세션 ID
   * @returns {Promise<Object>} - 세션 정보
   */
  async getSession(sessionId) {
    try {
      logger.debug(`세션 서비스 API 호출: 세션 조회 ${sessionId}`);
      const response = await sessionServiceClient.get(`/api/v1/sessions/${sessionId}`);
      
      return response.data;
    } catch (error) {
      logger.error(`세션 조회 API 오류 [${sessionId}]: ${error.message}`);
      throw new Error(`세션 조회 실패: ${error.message}`);
    }
  }

  /**
   * 세션 유효성 검증
   * @param {string} sessionId - 세션 ID
   * @param {string} userId - 사용자 ID
   * @returns {Promise<boolean>} - 세션 유효성 여부
   */
  async validateSession(sessionId, userId) {
    try {
      logger.debug(`세션 서비스 API 호출: 세션 유효성 검증 ${sessionId} for user ${userId}`);
      const response = await sessionServiceClient.post('/api/v1/sessions/validate', {
        sessionId,
        userId
      });
      
      return response.data.isValid;
    } catch (error) {
      logger.error(`세션 유효성 검증 API 오류 [${sessionId}]: ${error.message}`);
      // API 호출 실패 시 안전하게 false 반환
      return false;
    }
  }

  /**
   * 세션 참가자 추가
   * @param {string} sessionId - 세션 ID
   * @param {string} userId - 사용자 ID
   * @returns {Promise<Object>} - 참가자 추가 결과
   */
  async addParticipant(sessionId, userId) {
    try {
      logger.debug(`세션 서비스 API 호출: 참가자 추가 ${userId} to session ${sessionId}`);
      const response = await sessionServiceClient.post(`/api/v1/sessions/${sessionId}/participants`, {
        userId
      });
      
      return response.data;
    } catch (error) {
      logger.error(`세션 참가자 추가 API 오류 [${sessionId}]: ${error.message}`);
      throw new Error(`참가자 추가 실패: ${error.message}`);
    }
  }

  /**
   * 세션 참가자 제거
   * @param {string} sessionId - 세션 ID
   * @param {string} userId - 사용자 ID
   * @returns {Promise<Object>} - 참가자 제거 결과
   */
  async removeParticipant(sessionId, userId) {
    try {
      logger.debug(`세션 서비스 API 호출: 참가자 제거 ${userId} from session ${sessionId}`);
      const response = await sessionServiceClient.delete(`/api/v1/sessions/${sessionId}/participants/${userId}`);
      
      return response.data;
    } catch (error) {
      logger.error(`세션 참가자 제거 API 오류 [${sessionId}]: ${error.message}`);
      throw new Error(`참가자 제거 실패: ${error.message}`);
    }
  }

  /**
   * 세션 상태 조회
   * @param {string} sessionId - 세션 ID
   * @returns {Promise<Object>} - 세션 상태 정보
   */
  async getSessionStatus(sessionId) {
    try {
      logger.debug(`세션 서비스 API 호출: 세션 상태 조회 ${sessionId}`);
      const response = await sessionServiceClient.get(`/api/v1/sessions/${sessionId}/status`);
      
      return response.data;
    } catch (error) {
      logger.error(`세션 상태 조회 API 오류 [${sessionId}]: ${error.message}`);
      throw new Error(`세션 상태 조회 실패: ${error.message}`);
    }
  }
}

module.exports = new SessionApiService(); 
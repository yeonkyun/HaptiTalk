const axios = require('axios');
const { jwtDecode } = require('jwt-decode');

/**
 * 토큰 관리 클래스
 * 액세스 토큰 및 리프레시 토큰을 관리하고 자동 갱신 로직을 제공합니다.
 */
class TokenManager {
  /**
   * TokenManager 생성자
   * @param {Object} options 설정 옵션
   * @param {string} options.baseUrl API 기본 URL
   * @param {number} options.refreshThreshold 토큰 갱신 임계값(초) - 만료 전 이 시간에 도달하면 갱신 시도
   * @param {function} options.onTokenRefreshed 토큰 갱신 시 호출될 콜백
   * @param {function} options.onTokenExpired 토큰 만료 시 호출될 콜백
   */
  constructor(options = {}) {
    this.baseUrl = options.baseUrl || 'http://localhost:8000';
    this.refreshThreshold = options.refreshThreshold || 300; // 기본값 5분
    this.onTokenRefreshed = options.onTokenRefreshed || (() => {});
    this.onTokenExpired = options.onTokenExpired || (() => {});
    
    this.accessToken = null;
    this.refreshToken = null;
    this.refreshPromise = null;
    
    // 자동 갱신 타이머
    this.refreshTimer = null;
  }

  /**
   * 토큰 설정
   * @param {string} accessToken 액세스 토큰
   * @param {string} refreshToken 리프레시 토큰
   */
  setTokens(accessToken, refreshToken) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    
    // 토큰 자동 갱신 타이머 설정
    this._scheduleTokenRefresh();
  }

  /**
   * 액세스 토큰이 유효한지 확인
   * @returns {boolean} 토큰 유효 여부
   */
  isAccessTokenValid() {
    if (!this.accessToken) return false;
    
    try {
      const decoded = jwtDecode(this.accessToken);
      const now = Math.floor(Date.now() / 1000);
      
      return decoded.exp > now;
    } catch (error) {
      console.error('토큰 검증 오류:', error);
      return false;
    }
  }
  
  /**
   * 액세스 토큰이 곧 만료되는지 확인
   * @returns {boolean} 토큰 만료 임박 여부
   */
  isAccessTokenExpiringSoon() {
    if (!this.accessToken) return false;
    
    try {
      const decoded = jwtDecode(this.accessToken);
      const now = Math.floor(Date.now() / 1000);
      
      return decoded.exp - now < this.refreshThreshold;
    } catch (error) {
      console.error('토큰 검증 오류:', error);
      return false;
    }
  }

  /**
   * 액세스 토큰 가져오기
   * 필요시 자동 갱신 처리
   * @returns {Promise<string>} 유효한 액세스 토큰
   */
  async getAccessToken() {
    // 토큰이 없는 경우
    if (!this.accessToken) {
      throw new Error('인증 토큰이 없습니다. 먼저 로그인해주세요.');
    }
    
    // 토큰이 유효하고 만료가 임박하지 않은 경우
    if (this.isAccessTokenValid() && !this.isAccessTokenExpiringSoon()) {
      return this.accessToken;
    }
    
    // 토큰이 유효하지 않거나 만료 임박한 경우 갱신 시도
    if (this.refreshToken) {
      try {
        // 이미 갱신 중인 경우 해당 Promise 반환
        if (this.refreshPromise) {
          return this.refreshPromise;
        }
        
        this.refreshPromise = this._refreshTokens();
        const newToken = await this.refreshPromise;
        this.refreshPromise = null;
        return newToken;
      } catch (error) {
        this.refreshPromise = null;
        this.onTokenExpired();
        throw new Error('토큰 갱신 실패: ' + error.message);
      }
    } else {
      this.onTokenExpired();
      throw new Error('리프레시 토큰이 없습니다. 다시 로그인해주세요.');
    }
  }

  /**
   * 토큰 상태 확인
   * @returns {Promise<Object>} 토큰 상태 정보
   */
  async checkTokenStatus() {
    try {
      const response = await axios.get(`${this.baseUrl}/token/status`, {
        headers: {
          Authorization: `Bearer ${this.accessToken}`
        }
      });
      
      return response.data.data;
    } catch (error) {
      console.error('토큰 상태 확인 오류:', error);
      throw error;
    }
  }

  /**
   * 토큰 갱신 처리
   * @private
   * @returns {Promise<string>} 새로운 액세스 토큰
   */
  async _refreshTokens() {
    try {
      // 사전 갱신 시도
      const proactiveResponse = await axios.post(
        `${this.baseUrl}/token/proactive-refresh`,
        {},
        {
          headers: {
            Authorization: `Bearer ${this.accessToken}`
          }
        }
      );
      
      if (proactiveResponse.data.data.refreshed) {
        // 사전 갱신 성공
        const { access_token, expires_in } = proactiveResponse.data.data;
        this.accessToken = access_token;
        
        // 갱신 이벤트 발생
        this.onTokenRefreshed(this.accessToken, expires_in);
        
        // 새로운 타이머 설정
        this._scheduleTokenRefresh();
        
        return this.accessToken;
      }
      
      // 사전 갱신이 필요 없거나 실패한 경우, 표준 갱신 시도
      const response = await axios.post(
        `${this.baseUrl}/api/v1/auth/refresh`,
        {
          refresh_token: this.refreshToken
        }
      );
      
      const { access_token, refresh_token, expires_in } = response.data.data;
      
      this.accessToken = access_token;
      if (refresh_token) {
        this.refreshToken = refresh_token;
      }
      
      // 갱신 이벤트 발생
      this.onTokenRefreshed(this.accessToken, expires_in);
      
      // 새로운 타이머 설정
      this._scheduleTokenRefresh();
      
      return this.accessToken;
    } catch (error) {
      console.error('토큰 갱신 오류:', error);
      
      // 만료된 토큰으로 인한 오류인 경우
      if (error.response && error.response.status === 401) {
        this.onTokenExpired();
      }
      
      throw error;
    }
  }

  /**
   * 토큰 자동 갱신 타이머 설정
   * @private
   */
  _scheduleTokenRefresh() {
    // 기존 타이머가 있으면 제거
    if (this.refreshTimer) {
      clearTimeout(this.refreshTimer);
    }
    
    // 토큰이 없으면 타이머 설정 안함
    if (!this.accessToken) return;
    
    try {
      const decoded = jwtDecode(this.accessToken);
      const now = Math.floor(Date.now() / 1000);
      
      // 만료 시간까지 남은 시간 계산 (임계값 적용)
      const timeUntilRefresh = Math.max(
        0,
        (decoded.exp - now - this.refreshThreshold) * 1000
      );
      
      // 타이머 설정
      this.refreshTimer = setTimeout(() => {
        this._refreshTokens().catch(error => {
          console.error('자동 토큰 갱신 실패:', error);
        });
      }, timeUntilRefresh);
      
    } catch (error) {
      console.error('토큰 갱신 타이머 설정 오류:', error);
    }
  }

  /**
   * 토큰 정리 (로그아웃 시 호출)
   */
  clearTokens() {
    // 타이머 제거
    if (this.refreshTimer) {
      clearTimeout(this.refreshTimer);
    }
    
    this.accessToken = null;
    this.refreshToken = null;
    this.refreshPromise = null;
  }
}

module.exports = TokenManager; 
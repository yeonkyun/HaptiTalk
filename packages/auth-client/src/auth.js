const axios = require('axios');
const TokenManager = require('./token');

/**
 * 인증 클라이언트 클래스
 * 인증 서비스와의 통신 및 토큰 관리를 담당합니다.
 */
class AuthClient {
  /**
   * AuthClient 생성자
   * @param {Object} options 설정 옵션
   * @param {string} options.baseUrl API 기본 URL
   * @param {number} options.refreshThreshold 토큰 갱신 임계값(초)
   * @param {function} options.onTokenRefreshed 토큰 갱신 시 호출될 콜백
   * @param {function} options.onTokenExpired 토큰 만료 시 호출될 콜백
   * @param {Storage} options.storage 토큰 저장소 (기본값: localStorage)
   */
  constructor(options = {}) {
    this.baseUrl = options.baseUrl || 'http://localhost:8000';
    this.storage = options.storage || (typeof localStorage !== 'undefined' ? localStorage : null);
    
    // 토큰 관리자 생성
    this.tokenManager = new TokenManager({
      baseUrl: this.baseUrl,
      refreshThreshold: options.refreshThreshold,
      onTokenRefreshed: (token, expiresIn) => {
        this._saveTokens(token, this.tokenManager.refreshToken);
        if (options.onTokenRefreshed) {
          options.onTokenRefreshed(token, expiresIn);
        }
      },
      onTokenExpired: () => {
        this._clearTokens();
        if (options.onTokenExpired) {
          options.onTokenExpired();
        }
      }
    });
    
    // HTTP 클라이언트 생성
    this.client = axios.create({
      baseURL: this.baseUrl
    });
    
    // 요청 인터셉터 설정
    this.client.interceptors.request.use(
      async config => {
        // 인증이 필요한 요청에만 토큰 추가
        if (config.url !== '/api/v1/auth/login' && 
            config.url !== '/api/v1/auth/register' && 
            config.url !== '/api/v1/auth/refresh') {
          try {
            const token = await this.tokenManager.getAccessToken();
            config.headers.Authorization = `Bearer ${token}`;
          } catch (error) {
            // 토큰 가져오기 실패 시 처리
            console.error('인증 토큰 가져오기 실패:', error);
          }
        }
        return config;
      },
      error => Promise.reject(error)
    );
    
    // 응답 인터셉터 설정
    this.client.interceptors.response.use(
      response => response,
      async error => {
        const originalRequest = error.config;
        
        // 401 에러이고, 재시도 플래그가 없는 경우에만 토큰 갱신 시도
        if (error.response && 
            error.response.status === 401 && 
            !originalRequest._retry) {
          
          originalRequest._retry = true;
          
          try {
            // 토큰 갱신 시도
            await this.tokenManager.getAccessToken();
            
            // 갱신된 토큰으로 요청 재시도
            originalRequest.headers.Authorization = `Bearer ${this.tokenManager.accessToken}`;
            return this.client(originalRequest);
          } catch (refreshError) {
            // 갱신 실패 시 로그아웃 처리
            this._clearTokens();
            return Promise.reject(refreshError);
          }
        }
        
        return Promise.reject(error);
      }
    );
    
    // 저장된 토큰 복원
    this._restoreTokens();
  }

  /**
   * 로그인 처리
   * @param {string} email 이메일
   * @param {string} password 비밀번호
   * @param {Object} deviceInfo 기기 정보 (옵션)
   * @returns {Promise<Object>} 로그인 결과 (사용자 정보 포함)
   */
  async login(email, password, deviceInfo = {}) {
    try {
      const response = await this.client.post('/api/v1/auth/login', {
        email,
        password,
        device_info: deviceInfo
      });
      
      const { access_token, refresh_token } = response.data.data;
      
      // 토큰 설정 및 저장
      this.tokenManager.setTokens(access_token, refresh_token);
      this._saveTokens(access_token, refresh_token);
      
      return response.data.data;
    } catch (error) {
      console.error('로그인 실패:', error);
      throw error;
    }
  }

  /**
   * 로그아웃 처리
   * @returns {Promise<Object>} 로그아웃 결과
   */
  async logout() {
    try {
      // 현재 액세스 토큰과 리프레시 토큰 가져오기
      const accessToken = this.tokenManager.accessToken;
      const refreshToken = this.tokenManager.refreshToken;
      
      if (!accessToken) {
        throw new Error('로그인되어 있지 않습니다.');
      }
      
      // 로그아웃 요청
      const response = await this.client.post('/api/v1/auth/logout', {
        refresh_token: refreshToken
      });
      
      // 토큰 정리
      this._clearTokens();
      
      return response.data;
    } catch (error) {
      // 오류가 발생하더라도 로컬 토큰은 제거
      this._clearTokens();
      
      console.error('로그아웃 실패:', error);
      throw error;
    }
  }

  /**
   * 회원가입 처리
   * @param {Object} userData 사용자 데이터
   * @returns {Promise<Object>} 회원가입 결과
   */
  async register(userData) {
    try {
      const response = await this.client.post('/api/v1/auth/register', userData);
      return response.data;
    } catch (error) {
      console.error('회원가입 실패:', error);
      throw error;
    }
  }

  /**
   * 사용자 정보 가져오기
   * @returns {Promise<Object>} 사용자 정보
   */
  async getUserInfo() {
    return await this.client.get('/api/v1/users/me');
  }

  /**
   * 인증이 필요한 API 요청 처리
   * 토큰 갱신 및 재시도 로직이 자동으로 적용됩니다.
   * @param {string} url API 엔드포인트
   * @param {Object} options 요청 옵션
   * @returns {Promise<Object>} API 응답
   */
  async request(url, options = {}) {
    const { method = 'GET', data, headers = {} } = options;
    
    try {
      const response = await this.client({
        url,
        method,
        data,
        headers
      });
      
      return response.data;
    } catch (error) {
      console.error(`API 요청 실패 (${url}):`, error);
      throw error;
    }
  }

  /**
   * 토큰 저장
   * @private
   * @param {string} accessToken 액세스 토큰
   * @param {string} refreshToken 리프레시 토큰
   */
  _saveTokens(accessToken, refreshToken) {
    if (this.storage) {
      this.storage.setItem('haptitalk_access_token', accessToken);
      this.storage.setItem('haptitalk_refresh_token', refreshToken);
    }
  }

  /**
   * 저장된 토큰 복원
   * @private
   */
  _restoreTokens() {
    if (this.storage) {
      const accessToken = this.storage.getItem('haptitalk_access_token');
      const refreshToken = this.storage.getItem('haptitalk_refresh_token');
      
      if (accessToken && refreshToken) {
        this.tokenManager.setTokens(accessToken, refreshToken);
      }
    }
  }

  /**
   * 토큰 정리
   * @private
   */
  _clearTokens() {
    // 토큰 관리자 초기화
    this.tokenManager.clearTokens();
    
    // 저장소에서 토큰 제거
    if (this.storage) {
      this.storage.removeItem('haptitalk_access_token');
      this.storage.removeItem('haptitalk_refresh_token');
    }
  }

  /**
   * 인증 상태 확인
   * @returns {boolean} 로그인 상태
   */
  isAuthenticated() {
    return this.tokenManager.isAccessTokenValid();
  }

  /**
   * 토큰 상태 확인
   * @returns {Promise<Object>} 토큰 상태 정보
   */
  async checkTokenStatus() {
    return await this.tokenManager.checkTokenStatus();
  }
}

module.exports = AuthClient; 
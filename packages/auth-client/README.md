# HaptiTalk Auth Client

HaptiTalk 서비스용 인증 클라이언트 패키지

## 개요

이 패키지는 HaptiTalk 인증 서비스와의 통신을 간소화하고, 다음과 같은 기능을 제공합니다:

- 액세스 토큰 및 리프레시 토큰 자동 관리
- 토큰 만료 감지 및 자동 갱신
- 인증 관련 API 호출을 위한 편리한 인터페이스
- 인증이 필요한 API 요청에 대한 토큰 자동 추가

## 설치

```bash
npm install @haptitalk/auth-client
```

## 사용법

### 기본 사용

```javascript
const { AuthClient } = require('@haptitalk/auth-client');

const authClient = new AuthClient({
  baseUrl: 'https://api.haptitalk.com',
  refreshThreshold: 300, // 5분
  onTokenExpired: () => {
    // 토큰 만료 시 로그인 페이지로 리다이렉트
    window.location.href = '/login';
  }
});

// 로그인
async function login(email, password) {
  try {
    const result = await authClient.login(email, password);
    console.log('로그인 성공:', result.user);
  } catch (error) {
    console.error('로그인 실패:', error);
  }
}

// 인증이 필요한 API 요청
async function fetchUserData() {
  try {
    // 토큰이 자동으로 추가되고, 필요시 갱신됨
    const userData = await authClient.request('/api/v1/users/me');
    console.log('사용자 데이터:', userData);
  } catch (error) {
    console.error('사용자 데이터 가져오기 실패:', error);
  }
}
```

### 토큰 상태 확인

```javascript
async function checkTokenStatus() {
  try {
    const status = await authClient.checkTokenStatus();
    console.log('토큰 상태:', status);
    
    // 토큰이 만료 임박한 경우
    if (status.status === 'expiring_soon') {
      console.log(`토큰이 ${status.expiresIn}초 후에 만료됩니다.`);
    }
  } catch (error) {
    console.error('토큰 상태 확인 실패:', error);
  }
}
```

### 리프레시 토큰 관리

토큰 갱신은 대부분 자동으로 처리되지만, 수동으로 제어해야 하는 경우:

```javascript
// 로그아웃 (서버에 로그아웃 요청 및 로컬 토큰 제거)
async function logout() {
  try {
    await authClient.logout();
    console.log('로그아웃 성공');
  } catch (error) {
    console.error('로그아웃 실패:', error);
  }
}

// 인증 상태 확인
function isLoggedIn() {
  return authClient.isAuthenticated();
}
```

## 고급 설정

```javascript
const authClient = new AuthClient({
  baseUrl: 'https://api.haptitalk.com',
  refreshThreshold: 600, // 토큰 만료 10분 전에 갱신 시도
  storage: sessionStorage, // localStorage 대신 sessionStorage 사용
  onTokenRefreshed: (token, expiresIn) => {
    console.log('토큰이 갱신되었습니다. 만료까지:', expiresIn, '초');
  },
  onTokenExpired: () => {
    console.log('토큰이 만료되었습니다. 다시 로그인해주세요.');
  }
});
```

## 마이크로서비스 간 인증

다른 마이크로서비스에서 인증 서비스를 사용하는 예:

```javascript
const { AuthClient } = require('@haptitalk/auth-client');
const { createServer } = require('http');

class ServiceAuthManager {
  constructor() {
    this.authClient = new AuthClient({
      baseUrl: 'http://auth-service:3000',
      storage: new InMemoryStorage() // 서버 환경용 인메모리 스토리지
    });
    
    // 서비스 인증
    this.authenticate();
  }
  
  async authenticate() {
    // 서비스 인증 토큰 획득
    const serviceTokenData = await this.authClient.request('/api/v1/auth/service-token', {
      method: 'POST',
      data: {
        service_id: process.env.SERVICE_ID,
        service_secret: process.env.SERVICE_SECRET
      }
    });
    
    // 서비스 토큰 저장
    this.serviceToken = serviceTokenData.token;
  }
  
  getServiceToken() {
    return this.serviceToken;
  }
}

// 인메모리 스토리지 구현
class InMemoryStorage {
  constructor() {
    this.storage = {};
  }
  
  getItem(key) {
    return this.storage[key] || null;
  }
  
  setItem(key, value) {
    this.storage[key] = value;
  }
  
  removeItem(key) {
    delete this.storage[key];
  }
}
```

## 주의사항

- 프론트엔드에서 사용 시, 토큰은 localStorage나 sessionStorage에 저장됩니다.
- 백엔드 서비스에서 사용 시, 인메모리 저장소를 구현해야 합니다.
- 토큰 갱신 로직은 네트워크 요청이 발생할 때만 동작합니다.
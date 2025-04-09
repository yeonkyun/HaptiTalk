# HaptiTalk Auth Service

인증 관리를 담당하는 마이크로서비스입니다.

## 기능

- 사용자 인증 (회원가입, 로그인, 로그아웃)
- 이메일 인증
- 비밀번호 재설정
- 기기 관리 (등록, 조회, 삭제)
- JWT 기반 인증
- 보안 기능 (계정 잠금, 로그인 시도 제한)

## 기술 스택

- **런타임**: Node.js
- **프레임워크**: Express.js
- **데이터베이스**: PostgreSQL (Sequelize ORM)
- **캐시/세션**: Redis
- **컨테이너화**: Docker
- **로깅**: Winston
- **인증**: JWT (jsonwebtoken)
- **보안**: bcryptjs, helmet
- **유효성 검사**: express-validator

## 환경 변수

```env
# 서버 설정
NODE_ENV=development
PORT=3000

# PostgreSQL 설정
POSTGRES_USER=your_postgres_user
POSTGRES_PASSWORD=your_postgres_password
POSTGRES_DB=your_postgres_db
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# Redis 설정
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# JWT 설정
JWT_ACCESS_SECRET=your_jwt_access_secret
JWT_REFRESH_SECRET=your_jwt_refresh_secret
JWT_SESSION_SECRET=your_jwt_session_secret
JWT_ACCESS_EXPIRES_IN=1h
JWT_REFRESH_EXPIRES_IN=30d
JWT_SESSION_EXPIRES_IN=24h

# 이메일 설정
EMAIL_FROM=noreply@haptitalk.com
FRONTEND_URL=http://localhost:80

# 로깅 설정
LOG_LEVEL=info
```

## API 엔드포인트

### 인증 API

#### 회원가입
```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!",
  "device_info": {
    "type": "mobile",
    "model": "iPhone 13",
    "os_version": "iOS 15.4",
    "app_version": "1.0.0"
  }
}

Response 201:
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "is_verified": false
    }
  },
  "message": "Registration successful. Please verify your email."
}
```

#### 로그인
```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "Password123!",
  "device_info": {
    "type": "mobile",
    "model": "iPhone 13",
    "os_version": "iOS 15.4",
    "app_version": "1.0.0"
  }
}

Response 200:
{
  "success": true,
  "data": {
    "user": {
      "id": "uuid",
      "email": "user@example.com",
      "is_verified": false
    },
    "access_token": "jwt_access_token",
    "refresh_token": "jwt_refresh_token",
    "expires_in": 3600
  },
  "message": "Login successful"
}
```

#### 로그아웃
```http
POST /api/v1/auth/logout
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "refresh_token": "jwt_refresh_token"
}

Response 200:
{
  "success": true,
  "message": "Logout successful"
}
```

### 기기 API

#### 기기 등록
```http
POST /api/v1/devices
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "device_type": "watch",
  "device_name": "Apple Watch",
  "device_model": "Apple Watch Series 7",
  "os_version": "watchOS 8.5",
  "is_watch": true
}

Response 201:
{
  "success": true,
  "data": {
    "device": {
      "id": "uuid",
      "user_id": "user_uuid",
      "device_type": "watch",
      "device_name": "Apple Watch",
      "device_model": "Apple Watch Series 7",
      "os_version": "watchOS 8.5",
      "is_watch": true,
      "last_active": "2025-04-09T13:07:49.408Z"
    }
  },
  "message": "Device registered successfully"
}
```

## 보안 기능

- **비밀번호 해싱**: bcryptjs를 사용하여 안전하게 저장
- **JWT 기반 인증**: 
  - Access Token (1시간)
  - Refresh Token (30일)
  - Session Token (24시간)
- **로그인 보안**:
  - 5회 실패 시 30분 계정 잠금
  - 비밀번호 복잡도 검증
  - 이메일 인증 필수
- **토큰 관리**: Redis를 사용한 토큰 블랙리스트 관리
- **API 보안**: 
  - CORS 설정
  - Helmet 미들웨어
  - Rate Limiting

## 설치 및 실행

1. 환경 변수 설정
```bash
cp .env.example .env
# .env 파일 수정
```

2. Docker Compose로 실행
```bash
docker-compose up -d
```

3. 데이터베이스 마이그레이션
```bash
docker-compose exec auth-service npm run migrate
```

## 로깅

- **로그 레벨**: error, warn, info, debug
- **로그 형식**: JSON
- **로그 저장 위치**: /app/logs/
  - error.log: 에러 로그만 저장
  - combined.log: 모든 로그 저장
- **로그 포함 정보**:
  - 타임스탬프
  - 로그 레벨
  - 서비스 이름
  - 메시지
  - 스택 트레이스 (에러의 경우)

## 모니터링

- **헬스체크**: GET /health
  - 서비스 상태
  - 데이터베이스 연결 상태
  - Redis 연결 상태
- **Docker 헬스체크**:
  - 30초 간격으로 체크
  - 3회 실패 시 컨테이너 재시작
- **데이터베이스 모니터링**:
  - 연결 풀 상태
  - 쿼리 성능
  - 에러 로깅

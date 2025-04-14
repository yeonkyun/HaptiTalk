# User Service

## 개요
User Service는 HaptiTalk 시스템의 사용자 프로필 및 설정 관리를 담당하는 마이크로서비스입니다. 이 서비스는 사용자 개인 정보, 앱 설정, 그리고 사용자 경험과 관련된 설정 데이터를 관리합니다.

## 주요 기능
* 사용자 프로필 관리 (조회, 업데이트)
* 사용자 앱 설정 관리 (조회, 업데이트)
* 인증 서비스와 연동된 JWT 기반 사용자 인증
* Redis 캐싱을 통한 빠른 데이터 접근
* 피드백 서비스와의 설정 동기화

## 기술 스택
* **런타임**: Node.js
* **프레임워크**: Express.js
* **ORM**: Sequelize
* **데이터베이스**: PostgreSQL
* **캐싱**: Redis
* **인증**: JWT

## API 엔드포인트

### 프로필 관리
* `GET /api/v1/users/profile`: 사용자 프로필 조회
* `PATCH /api/v1/users/profile`: 사용자 프로필 업데이트

### 설정 관리
* `GET /api/v1/users/settings`: 사용자 설정 조회
* `PATCH /api/v1/users/settings`: 사용자 설정 업데이트

### 헬스체크
* `GET /health`: 서비스 상태 확인

## 설치 및 실행

### 필요 조건
* Node.js 18 이상
* Docker 및 Docker Compose
* PostgreSQL
* Redis

### 로컬 환경에서 실행
1. 프로젝트 복제
   ```bash
   git clone https://github.com/your-repo/haptitalk.git
   cd haptitalk/api/user-service
   ```

2. 종속성 설치
   ```bash
   npm install
   ```

3. 환경 변수 설정
   `.env` 파일을 생성하거나 시스템 환경 변수를 설정합니다:
   ```
   PORT=3004
   POSTGRES_USER=postgres
   POSTGRES_PASSWORD=your_password
   POSTGRES_DB=haptitalk
   POSTGRES_HOST=localhost
   POSTGRES_PORT=5432
   REDIS_HOST=localhost
   REDIS_PORT=6379
   REDIS_PASSWORD=your_redis_password
   JWT_ACCESS_SECRET=your_jwt_secret
   LOG_LEVEL=info
   ```

4. 서비스 실행
   ```bash
   npm start
   ```
   개발 모드로 실행:
   ```bash
   npm run dev
   ```

### Docker Compose를 이용한 실행
1. 프로젝트 루트 디렉토리에서 Docker Compose 실행
   ```bash
   docker-compose up -d user-service
   ```

2. 로그 확인
   ```bash
   docker-compose logs -f user-service
   ```

## 테스트

### API 테스트 예제

```bash
# 프로필 조회
curl -X GET http://localhost:8000/api/v1/users/profile \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 프로필 업데이트
curl -X PATCH http://localhost:8000/api/v1/users/profile \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{"first_name": "홍", "last_name": "길동", "bio": "테스트 프로필입니다."}'

# 설정 조회
curl -X GET http://localhost:8000/api/v1/users/settings \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 설정 업데이트
curl -X PATCH http://localhost:8000/api/v1/users/settings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{"haptic_strength": 7, "theme": "dark", "default_mode": "interview"}'
```

## 프로젝트 구조

```
api/user-service/
├── src/
│   ├── config/
│   │   ├── database.js      # PostgreSQL 연결 설정
│   │   └── redis.js         # Redis 연결 설정
│   ├── controllers/
│   │   ├── profile.controller.js  # 프로필 관련 API 컨트롤러
│   │   └── settings.controller.js # 설정 관련 API 컨트롤러
│   ├── middleware/
│   │   ├── auth.middleware.js     # 인증 검증 미들웨어
│   │   └── errorHandler.middleware.js # 오류 처리 미들웨어
│   ├── models/
│   │   ├── profile.model.js       # 사용자 프로필 모델
│   │   └── settings.model.js      # 사용자 설정 모델
│   ├── routes/
│   │   ├── profile.routes.js      # 프로필 관련 라우팅
│   │   ├── settings.routes.js     # 설정 관련 라우팅
│   │   └── index.js               # 라우트 통합
│   ├── services/
│   │   ├── profile.service.js     # 프로필 관련 비즈니스 로직
│   │   └── settings.service.js    # 설정 관련 비즈니스 로직
│   ├── utils/
│   │   ├── logger.js              # 로깅 유틸리티
│   │   └── responseFormatter.js   # API 응답 포맷 유틸리티
│   └── app.js                     # Express 앱 초기화
├── tests/                         # 테스트 코드
├── Dockerfile                     # Docker 빌드 파일
├── package.json                   # 프로젝트 종속성
└── README.md                      # 서비스 문서
```

## 데이터 모델

### 프로필 (Profile)

| **필드** | **타입** | **설명** |
|----------|----------|----------|
| id | UUID | 사용자 고유 ID (PK) |
| username | String | 사용자명 (Unique) |
| first_name | String | 이름 |
| last_name | String | 성 |
| birth_date | Date | 생년월일 |
| gender | String | 성별 |
| profile_image_url | String | 프로필 이미지 URL |
| bio | Text | 자기소개 |
| created_at | DateTime | 생성 시간 |
| updated_at | DateTime | 업데이트 시간 |

### 설정 (Settings)

| **필드** | **타입** | **설명** |
|----------|----------|----------|
| id | UUID | 사용자 고유 ID (PK) |
| notification_enabled | Boolean | 알림 활성화 여부 |
| haptic_strength | Integer | 햅틱 피드백 강도 (1-10) |
| analysis_level | String | 분석 수준 (basic/standard/advanced) |
| audio_retention_days | Integer | 오디오 보관 일수 |
| data_anonymization_level | String | 데이터 익명화 수준 |
| default_mode | String | 기본 모드 (dating/interview/business/coaching) |
| theme | String | 앱 테마 (light/dark/system) |
| language | String | 앱 언어 설정 |
| updated_at | DateTime | 업데이트 시간 |

## 캐싱 전략

사용자 서비스는 Redis를 사용하여 다음과 같은 캐싱 전략을 구현합니다:

* 사용자 프로필: `user:profile:{userId}` - 1시간 TTL
* 사용자 설정: `user:settings:{userId}` - 1시간 TTL
* 피드백 설정 공유: `feedback:user:{userId}` - TTL 없음 (피드백 서비스와 공유)

## 오류 처리

사용자 서비스는 다양한 오류 상황에 대한 표준화된 응답 형식을 제공합니다:

```json
{
  "success": false,
  "message": "오류 메시지",
  "errors": [
    {
      "code": "error_code",
      "field": "field_name",
      "message": "상세 오류 메시지"
    }
  ]
}
```
# HaptiTalk 세션 서비스

세션 서비스는 HaptiTalk 시스템의 대화 세션을 관리하는 마이크로서비스입니다. 이 서비스는 다양한 대화 유형(소개팅, 면접, 비즈니스 미팅, 발표)의 세션을 생성, 관리, 분석하는 기능을 제공합니다.

## 주요 기능

- 다양한 유형의 대화 세션 생성 및 관리
- 세션 메타데이터 및 설정 관리
- 발표 모드를 위한 타이머 관리 기능
  - 타이머 설정, 시작, 일시정지, 재개, 리셋
  - 실시간 진행률 및 알림 지원
- 실시간 피드백 시스템 연동
  - 실시간 서비스와 연동하여 피드백 데이터 처리
  - 세션별 피드백 설정 관리
- 실시간 세션 상태 추적
- 세션 요약 데이터 저장 및 관리

## 기술 스택

- **Node.js**: 서버 런타임
- **Express**: API 프레임워크
- **PostgreSQL**: 관계형 데이터베이스
- **Sequelize**: ORM(Object-Relational Mapping)
- **Redis**: 캐싱 및 실시간 데이터 처리
- **JWT**: 인증 및 권한 관리

## API 엔드포인트

### 세션 관리

| 메소드 | 엔드포인트 | 설명 |
|-------|------------|------|
| POST | `/api/v1/sessions` | 새 세션 생성 |
| GET | `/api/v1/sessions` | 사용자의 세션 목록 조회 |
| GET | `/api/v1/sessions/:id` | 특정 세션 정보 조회 |
| PUT | `/api/v1/sessions/:id` | 세션 정보 업데이트 |
| POST | `/api/v1/sessions/:id/end` | 세션 종료 |
| PUT | `/api/v1/sessions/:id/summary` | 세션 요약 정보 업데이트 |

### 타이머 관리

| 메소드 | 엔드포인트 | 설명 |
|-------|------------|------|
| POST | `/api/v1/sessions/:id/timer/setup` | 발표 타이머 설정 |
| POST | `/api/v1/sessions/:id/timer/start` | 타이머 시작 |
| POST | `/api/v1/sessions/:id/timer/pause` | 타이머 일시 중지 |
| POST | `/api/v1/sessions/:id/timer/resume` | 타이머 재개 |
| POST | `/api/v1/sessions/:id/timer/reset` | 타이머 리셋 |
| GET | `/api/v1/sessions/:id/timer` | 타이머 상태 조회 |

## 설치 및 실행

### 필수 조건

- Node.js 18 이상
- PostgreSQL 15 이상
- Redis 6 이상

### 환경 변수

`.env` 파일 또는 환경 변수로 다음 설정이 필요합니다:

```
# 서버 설정
PORT=3002
NODE_ENV=development
SYNC_MODELS=true  # 개발 환경에서 모델 동기화 여부

# 데이터베이스 설정
POSTGRES_HOST=postgres
POSTGRES_PORT=5432
POSTGRES_DB=haptitalk
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres

# Redis 설정
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=
REDIS_SESSION_DB=1

# JWT 설정
JWT_SECRET=your-secret-key
JWT_EXPIRES_IN=1d

# 서비스 설정
AUTH_SERVICE_HOST=auth-service
AUTH_SERVICE_PORT=3001
```

### 로컬 개발 환경 실행

```bash
# 의존성 설치
npm install

# 개발 모드 실행
npm run dev
```

### Docker로 실행

```bash
# 이미지 빌드
docker build -t haptitalk-session-service .

# 컨테이너 실행
docker run -p 3002:3002 --env-file .env --name session-service haptitalk-session-service
```

## 테스트

```bash
# 단위 테스트 실행
npm test
```
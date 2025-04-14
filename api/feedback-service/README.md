# HaptiTalk 피드백 서비스

HaptiTalk 피드백 서비스는 실시간 대화 분석 결과를 기반으로 스마트워치를 통해 사용자에게 적절한 햅틱 피드백을 제공하는 마이크로서비스입니다. 이 서비스는 다양한 햅틱 패턴 관리, 사용자별 피드백 설정, 피드백 이력 관리 및 실시간 피드백 생성 기능을 담당합니다.

## 주요 기능

- **햅틱 패턴 관리**: 다양한 상황에 맞는 햅틱 패턴 제공 및 관리
- **사용자 피드백 설정**: 사용자별 햅틱 강도, 활성화된 패턴, 피드백 빈도 등 맞춤 설정
- **실시간 피드백 전송**: 대화 세션 중 분석 결과에 기반한 실시간 피드백 생성
- **피드백 이력 관리**: 이전에 제공된 피드백 기록 저장 및 조회

## 기술 스택

- **언어 및 프레임워크**: Node.js, Express
- **데이터베이스**: 
  - PostgreSQL: 사용자 설정, 햅틱 패턴 정의 등 구조화된 데이터
  - MongoDB: 피드백 이력, 세션 분석 등 비정형 데이터
- **통신**: RESTful API, Redis Pub/Sub

## API 엔드포인트

### 헬스체크
- `GET /health`: 서비스 상태 확인

### 햅틱 패턴
- `GET /api/v1/feedback/haptic-patterns`: 모든 햅틱 패턴 조회
- `GET /api/v1/feedback/haptic-patterns/:id`: 특정 햅틱 패턴 조회
- `POST /api/v1/feedback/haptic-patterns`: 새 햅틱 패턴 생성 (관리자 전용)
- `PUT /api/v1/feedback/haptic-patterns/:id`: 패턴 업데이트 (관리자 전용)
- `DELETE /api/v1/feedback/haptic-patterns/:id`: 패턴 비활성화 (관리자 전용)

### 사용자 설정
- `GET /api/v1/feedback/settings`: 사용자 피드백 설정 조회
- `PATCH /api/v1/feedback/settings`: 사용자 피드백 설정 업데이트

### 피드백 생성 및 관리
- `POST /api/v1/feedback`: 햅틱 피드백 생성
- `POST /api/v1/feedback/:feedback_id/acknowledge`: 피드백 수신 확인

### 피드백 이력
- `GET /api/v1/feedback/history`: 사용자 피드백 이력 조회

## 데이터 모델

### PostgreSQL 테이블

#### public.user_feedback_settings
사용자별 피드백 설정 정보를 저장합니다.
```
- user_id: UUID (PK)
- haptic_strength: INTEGER
- active_patterns: VARCHAR(255)[]
- priority_threshold: VARCHAR(10)
- minimum_interval_seconds: INTEGER
- feedback_frequency: VARCHAR(10)
- mode_settings: JSONB
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE
```

#### public.haptic_patterns
햅틱 패턴 정의를 저장합니다.
```
- id: VARCHAR(50) (PK)
- name: VARCHAR(100)
- description: TEXT
- pattern_data: JSONB
- category: VARCHAR(50)
- intensity_default: INTEGER
- duration_ms: INTEGER
- version: INTEGER
- is_active: BOOLEAN
- created_at: TIMESTAMP WITH TIME ZONE
- updated_at: TIMESTAMP WITH TIME ZONE
```

### MongoDB 컬렉션

#### hapticFeedbackHistory
사용자에게 전송된 햅틱 피드백 이력을 저장합니다.
```
- _id: ObjectId
- userId: String
- sessionId: String
- deviceId: String
- patternId: String
- timestamp: Date
- intensity: Number
- reason: String
- context: Object
- acknowledged: Boolean
- acknowledgedAt: Date
- created_at: Date
```

## 개발 및 테스트

### 로컬 개발 환경 설정
1. `.env` 파일에 필요한 환경 변수 설정
2. 필요한 의존성 설치: `npm install`
3. 개발 서버 실행: `npm run dev`

### Docker 환경에서 테스트
```bash
# 피드백 서비스 빌드
docker-compose build feedback-service

# 피드백 서비스 실행
docker-compose up -d feedback-service

# 로그 확인
docker logs -f haptitalk-feedback-service
```

### API 테스트

#### 직접 서비스 테스트
```bash
# 헬스체크
curl http://localhost:3003/health

# 햅틱 패턴 목록 조회
curl -X GET "http://localhost:3003/api/v1/feedback/haptic-patterns"

# 특정 패턴 조회
curl -X GET "http://localhost:3003/api/v1/feedback/haptic-patterns/S1"
```

#### Kong API Gateway를 통한 테스트
```bash
# 헬스체크
curl http://localhost:8000/api/v1/feedback/health

# 햅틱 패턴 목록 조회
curl -X GET "http://localhost:8000/api/v1/feedback/haptic-patterns"

# 인증 필요한 API (토큰 필요)
curl -X GET "http://localhost:8000/api/v1/feedback/settings" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"

# 설정 업데이트
curl -X PATCH "http://localhost:8000/api/v1/feedback/settings" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -d '{
    "haptic_strength": 7,
    "active_patterns": ["S1", "L1", "F1", "R1"],
    "minimum_interval_seconds": 15
  }'
```
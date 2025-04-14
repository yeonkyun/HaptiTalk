# HaptiTalk Report Service

세션 분석 데이터를 기반으로 포괄적인 리포트를 생성하는 마이크로서비스입니다.

## 주요 기능

- 세션 분석 기반 포괄적인 리포트 생성
- PDF 내보내기 기능
- 세션 간 비교 리포트 생성
- 사용자 통계 및 발전 추이 분석
- 차트 생성 및 시각화
- 상황별 특화 인사이트 제공 (데이팅, 면접, 비즈니스, 발표)

## 기술 스택

- **런타임**: Node.js
- **프레임워크**: Express.js
- **데이터베이스**: MongoDB (세션 분석 데이터)
- **관계형 데이터베이스**: PostgreSQL (사용자 및 세션 메타데이터)
- **캐시**: Redis
- **컨테이너화**: Docker
- **로깅**: Winston
- **PDF 생성**: PDFKit
- **차트 생성**: ChartJS-Node-Canvas
- **인증**: JWT (jsonwebtoken)
- **유효성 검사**: express-validator

## 환경 변수

```env
# 서버 설정
NODE_ENV=development
PORT=3005

# PostgreSQL 설정
POSTGRES_USER=your_postgres_user
POSTGRES_PASSWORD=your_postgres_password
POSTGRES_DB=your_postgres_db
POSTGRES_HOST=postgres
POSTGRES_PORT=5432

# MongoDB 설정
MONGO_USER=your_mongo_user
MONGO_PASSWORD=your_mongo_password
MONGO_DB=your_mongo_db
MONGO_HOST=mongodb
MONGO_PORT=27017

# Redis 설정
REDIS_HOST=redis
REDIS_PORT=6379
REDIS_PASSWORD=your_redis_password

# JWT 설정
JWT_ACCESS_SECRET=your_jwt_access_secret

# 로깅 설정
LOG_LEVEL=info
```

## API 엔드포인트

### 리포트 API

#### 세션별 리포트 생성
```http
POST /api/v1/reports/generate/:sessionId
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "format": "json", // or "pdf"
  "includeCharts": true,
  "detailLevel": "detailed" // "basic", "detailed", "comprehensive"
}

Response 201:
{
  "success": true,
  "data": {
    "report": {
      "id": "report_id",
      "userId": "user_id",
      "sessionId": "session_id",
      "sessionType": "presentation",
      "duration": 1800,
      "createdAt": "2025-04-14T14:00:00.000Z",
      "overallInsights": ["인사이트1", "인사이트2", "인사이트3"],
      "keyMetrics": {
        "speakingRate": "120 WPM",
        "userSpeakingRatio": 0.65,
        "fillerWordsCount": 12
      },
      "emotionAnalysis": {
        "positive": 0.6,
        "neutral": 0.3,
        "negative": 0.1
      },
      // ... 기타 리포트 데이터
    }
  },
  "message": "Report generated successfully"
}
```

#### 세션별 리포트 조회
```http
GET /api/v1/reports/:reportId
Authorization: Bearer {access_token}

Response 200:
{
  "success": true,
  "data": {
    "report": {
      // 리포트 데이터 (생성 응답과 동일)
    }
  },
  "message": "Report retrieved successfully"
}
```

#### 사용자별 리포트 목록 조회
```http
GET /api/v1/reports?page=1&limit=10&sessionType=presentation
Authorization: Bearer {access_token}

Response 200:
{
  "success": true,
  "data": {
    "reports": [
      {
        "id": "report_id1",
        "sessionId": "session_id1",
        "sessionType": "presentation",
        "createdAt": "2025-04-14T14:00:00.000Z",
        "duration": 1800,
        "keyMetrics": { /* 간략한 지표 정보 */ },
        "overallInsights": ["인사이트1", "인사이트2", "인사이트3"]
      },
      // ... 더 많은 리포트
    ],
    "pagination": {
      "total": 25,
      "page": 1,
      "limit": 10,
      "pages": 3
    }
  },
  "message": "Reports retrieved successfully",
  "meta": {}
}
```

#### 리포트 PDF 내보내기
```http
GET /api/v1/reports/:reportId/export
Authorization: Bearer {access_token}

Response: PDF 파일 (application/pdf)
```

#### 세션 간 비교 리포트 생성
```http
POST /api/v1/reports/compare
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "sessionIds": ["session_id1", "session_id2"],
  "metrics": ["speakingRate", "emotionAnalysis", "fillerWords"]
}

Response 201:
{
  "success": true,
  "data": {
    "comparison": {
      "sessions": [
        {
          "id": "session_id1",
          "title": "첫 번째 세션",
          "date": "2025-04-10T14:00:00.000Z",
          "type": "presentation"
        },
        {
          "id": "session_id2",
          "title": "두 번째 세션",
          "date": "2025-04-14T14:00:00.000Z",
          "type": "presentation"
        }
      ],
      "metrics": {
        "speakingRate": {
          "session_id1": 120,
          "session_id2": 125,
          "improvement": "+4.2%"
        },
        // ... 기타 비교 지표
      },
      "recommendations": [
        "첫 번째 세션보다 두 번째 세션에서 말하기 속도가 개선되었습니다.",
        // ... 기타 인사이트
      ]
    }
  },
  "message": "Comparison report generated successfully"
}
```

### 통계 API

#### 세션 유형별 통계 조회
```http
GET /api/v1/reports/stats/by-type
Authorization: Bearer {access_token}

Response 200:
{
  "success": true,
  "data": {
    "stats": {
      "presentation": {
        "count": 10,
        "averageDuration": 1500,
        "averageRating": 4.2
      },
      "interview": {
        "count": 5,
        "averageDuration": 1800,
        "averageRating": 3.8
      }
      // ... 기타 세션 유형
    }
  },
  "message": "Statistics retrieved successfully"
}
```

### 발전 추이 API

#### 사용자 발전 추이 조회
```http
GET /api/v1/reports/progress?period=30&metrics=userSpeakingRatio,positiveEmotion
Authorization: Bearer {access_token}

Response 200:
{
  "success": true,
  "data": {
    "period": 30,
    "sessionCount": 8,
    "firstSessionDate": "2025-03-15T10:00:00.000Z",
    "lastSessionDate": "2025-04-14T14:00:00.000Z",
    "trends": {
      "userSpeakingRatio": [
        { "date": "2025-03-15T10:00:00.000Z", "value": 0.55 },
        // ... 더 많은 데이터 포인트
      ],
      "positiveEmotion": [
        { "date": "2025-03-15T10:00:00.000Z", "value": 0.4 },
        // ... 더 많은 데이터 포인트
      ]
    },
    "analysis": {
      "userSpeakingRatio": {
        "trend": "improving",
        "percentChange": 12.5,
        "startValue": 0.55,
        "currentValue": 0.62
      },
      "positiveEmotion": {
        "trend": "improving",
        "percentChange": 25,
        "startValue": 0.4,
        "currentValue": 0.5
      }
    }
  },
  "message": "Progress trend retrieved successfully"
}
```

## 설치 및 실행

1. 환경 변수 설정
```bash
cp .env.example .env
# .env 파일 수정
```

2. Docker Compose로 실행
```bash
docker-compose up -d report-service
```

## 종속성

- auth-service: 사용자 인증
- session-service: 세션 메타데이터
- feedback-service: 햅틱 피드백 데이터

## 데이터 저장소

### MongoDB 컬렉션
- sessionAnalytics: 세션 분석 데이터
- sessionReports: 생성된 리포트
- hapticFeedbacks: 피드백 이력

### PostgreSQL 테이블
- session.sessions: 세션 메타데이터
- user.users: 사용자 정보

## 로깅

- **로그 레벨**: error, warn, info, debug
- **로그 형식**: JSON
- **로그 저장 위치**: /app/logs/
  - error.log: 에러 로그만 저장
  - combined.log: 모든 로그 저장

## 모니터링

- **헬스체크**: GET /health
  - 서비스 상태
  - 데이터베이스 연결 상태
  - Redis 연결 상태

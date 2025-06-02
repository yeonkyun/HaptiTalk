# HaptiTalk 실시간 서비스

실시간 대화 분석 및 피드백 통신을 위한 WebSocket 서비스입니다.

## 기능

- 실시간 세션 관리 및 사용자 연결 처리
- 대화 분석 데이터 수신 및 처리
- 햅틱 피드백 전달
- 실시간 분석 결과 전송

## 주요 구성 요소

- **ConnectionManager**: WebSocket 연결 관리 및 상태 추적
- **SocketMonitor**: 실시간 연결 상태 모니터링 및 통계 수집
- **MessageBatcher**: 대량 메시지 효율적 처리를 위한 배치 처리 기능
- **RedisPubSub**: Redis 기반 메시지 구독 및 발행, 재시도 로직 제공

## 성능 개선 사항

실시간 서비스는 다음과 같은 성능 개선이 적용되었습니다:

- **연결 안정성 향상**: 자동 재연결 및 네트워크 변경 대응
- **메시지 배치 처리**: 대량 메시지 효율적 처리로 CPU 사용량 감소
- **메시지 큐**: 연결 끊김 상태에서 메시지 손실 방지
- **최적화된 메시지 처리**: JSON 파싱 최적화 및 효율적인 이벤트 처리

자세한 내용은 [성능 개선 내역](./PERFORMANCE_IMPROVEMENTS.md) 문서를 참조하세요.

## 기술 스택

- Node.js
- Express
- Socket.io
- Redis (Pub/Sub 및 데이터 저장)
- JWT (인증)

## 설치 및 실행

### 로컬 환경

```bash
# 의존성 설치
npm install

# 개발 모드 실행
npm run dev

# 배포 모드 실행
npm start
```

### 도커 환경

```bash
# 도커 이미지 빌드
docker build -t haptitalk-realtime-service .

# 컨테이너 실행
docker run -p 3001:3001 --env-file .env --name haptitalk-realtime-service haptitalk-realtime-service
```

## API 문서

### WebSocket 이벤트

**클라이언트 → 서버**:
- `join_session`: 세션 참여 요청
- `leave_session`: 세션 나가기 요청
- `speech_features`: 음성 특성 데이터 전송
- `text_segment`: 텍스트 세그먼트 데이터 전송
- `feedback_request`: 피드백 요청
- `ping`: 지연 시간 측정 핑

**서버 → 클라이언트**:
- `session_joined`: 세션 참여 성공
- `session_left`: 세션 나가기 성공
- `participant_joined`: 다른 참가자 입장
- `participant_left`: 다른 참가자 퇴장
- `feedback`: 피드백 데이터
- `analysis_update`: 분석 결과 업데이트
- `pong`: 지연 시간 측정 응답

## 테스트

실시간 서비스의 성능과 기능을 테스트하는 스크립트가 포함되어 있습니다:

```bash
# 연결 테스트
cd tests
node test-connection.js

# 세션 관리 테스트
node test-session.js

# 데이터 전송 테스트
node test-data-transfer.js
```

## 환경 변수

서비스 실행을 위한 필수 환경 변수:

- `PORT`: 서비스 포트 (기본값: 3001)
- `REDIS_URL`: Redis 서버 URL
- `INTER_SERVICE_TOKEN`: 서비스 간 통신용 토큰
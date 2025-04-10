# HaptiTalk 실시간 서비스

실시간 대화 분석 및 피드백 통신을 위한 WebSocket 서비스입니다.

## 기능

- 실시간 세션 관리 및 사용자 연결 처리
- 대화 분석 데이터 수신 및 처리
- 햅틱 피드백 전달
- 실시간 분석 결과 전송

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
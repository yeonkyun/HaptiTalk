# HaptiTalk - 실시간 대화 코칭 시스템 (수정중)

<img width="171" alt="image" src="https://github.com/user-attachments/assets/cc098176-34d0-4bc3-8f8c-00d0a1bfd8d1" />

실시간 대화 분석을 통해 말하기 패턴과 상대방 반응을 감지하여 스마트워치 햅틱 진동으로 피드백을 제공하는 실시간 대화 코칭 시스템

<!-- 🖼️ 여기에 앱 사용 예시 GIF 또는 데모 비디오 스크린샷 추가 -->

## 시스템 아키텍처
![image](https://github.com/user-attachments/assets/b35c5895-b616-4941-be5a-7f259f09f79c)


### 📱 **Frontend**
- **모바일 앱**: Flutter 기반 크로스 플랫폼 모바일 애플리케이션
<img width="199" alt="image" src="https://github.com/user-attachments/assets/1c423ed1-91bc-4e55-8cd2-21514e67be33" />
<img width="199" alt="image" src="https://github.com/user-attachments/assets/179e2e86-6c3f-4614-a046-5bcb9c405134" />
<img width="199" alt="image" src="https://github.com/user-attachments/assets/c268e907-2346-44fd-b42e-8f3203d41bf9" />
<img width="199" alt="image" src="https://github.com/user-attachments/assets/7691ba08-e78b-4a36-a7b2-b5613563b4c3" />
<img width="199" alt="image" src="https://github.com/user-attachments/assets/1452b4c9-1959-4062-9433-e2eaf389c32f" />
<img width="600" alt="image" src="https://github.com/user-attachments/assets/c36f245b-d66d-443c-925a-9a42d9f9291d" />




### 🔧 **API 서비스 (Microservices)**
- **인증 서비스** (`auth-service`): JWT 기반 사용자 인증/인가
- **사용자 서비스** (`user-service`): 사용자 프로필 및 계정 관리
- **세션 서비스** (`session-service`): 통화 세션 생명주기 관리
- **실시간 서비스** (`realtime-service`): WebSocket 기반 실시간 데이터 스트리밍
- **피드백 서비스** (`feedback-service`): AI 분석 결과 기반 피드백 생성
- **리포트 서비스** (`report-service`): 통화 분석 리포트 생성 및 관리
- **알림 서비스** (`notification-service`): 푸시 알림 및 이벤트 처리

### 🤖 **AI 서비스**
- **STT 서비스** (`stt-service`): 음성-텍스트 변환
- **감정 분석 서비스** (`emotion-analysis-service`): 음성 감정 상태 분석
- **화자 분리 서비스** (`speaker-diarization-service`): 다중 화자 구분 및 분리

### 🏗️ **인프라스트럭처**
- **API Gateway**: Kong (라우팅, 인증, 로드밸런싱)
- **메시징**: Apache Kafka (이벤트 드리븐 아키텍처)
- **데이터베이스**: 
  - PostgreSQL (관계형 데이터)
  - MongoDB (비정형 분석 데이터)
  - Redis (캐싱 및 세션 스토리지)
- **모니터링**: OpenTelemetry, Grafana
- **컨테이너 오케스트레이션**: Docker Compose

<!-- 🖼️ 여기에 인프라스트럭처 구성도 추가 (Docker Compose 서비스 관계도) -->

<!-- 🖼️ 여기에 데이터 플로우 다이어그램 추가 (Kafka 메시지 흐름) -->

## 📚 API 문서

각 서비스의 API 문서는 다음 엔드포인트에서 확인할 수 있습니다:

- **API Gateway**: `http://localhost:8000`
- **인증 서비스**: `http://localhost:3001/api-docs`
- **사용자 서비스**: `http://localhost:3002/api-docs`
- **세션 서비스**: `http://localhost:3003/api-docs`
- **피드백 서비스**: `http://localhost:3004/api-docs`


### 개발 워크플로우
1. **새로운 기능 개발**: `git flow feature start [feature-name]`
2. **로컬 테스트**: Docker Compose 환경에서 전체 서비스 테스트
3. **컨테이너 환경 검증**: 모든 서비스가 정상 동작하는지 확인
4. **커밋**: 테스트 완료 후 커밋 수행

## 📊 모니터링 & 관리

### 관리 도구 접근
- **Kafka UI**: `http://localhost:8080` (Kafka 토픽 및 메시지 모니터링)
- **Kong Admin**: `http://localhost:8001` (API Gateway 관리)
- **Grafana**: 모니터링 대시보드 (설정 시)

## 🤝 개발 가이드라인

### Git 워크플로우
- **브랜치 전략**: Git Flow 사용
- **커밋 메시지**: Conventional Commits 규칙 준수
  ```
  feat: 사용자 로그인 기능 추가
  fix: 회원가입 시 이메일 중복 오류 수정
  docs: API 문서 업데이트
  ```

### 코드 스타일
- **ESLint**: JavaScript/TypeScript 코딩 표준
- **Prettier**: 코드 포맷팅
- **Husky**: Pre-commit 훅을 통한 코드 품질 관리

## 🗂️ 프로젝트 구조

```
haptitalk/
├── api/                    # 마이크로서비스 API
│   ├── auth-service/       # 인증 서비스
│   ├── user-service/       # 사용자 관리 서비스
│   ├── session-service/    # 세션 관리 서비스
│   ├── realtime-service/   # 실시간 통신 서비스
│   ├── feedback-service/   # 피드백 생성 서비스
│   ├── report-service/     # 리포트 생성 서비스
│   ├── notification-service/ # 알림 서비스
│   └── shared/            # 공통 라이브러리
├── ai/                    # AI 서비스
│   ├── stt-service/       # 음성-텍스트 변환
│   ├── emotion-analysis-service/ # 감정 분석
│   └── speaker-diarization-service/ # 화자 분리
├── frontend/              # 프론트엔드 애플리케이션
│   └── mobile/           # React Native 모바일 앱
├── infrastructure/        # 인프라스트럭처 설정
│   ├── api-gateway/      # Kong 설정
│   ├── database/         # DB 초기화 스크립트
│   ├── messaging/        # Kafka 설정
│   ├── monitoring/       # 모니터링 도구
│   └── deployment/       # 배포 스크립트
├── scripts/              # 유틸리티 스크립트
├── docker-compose.yml    # 개발 환경 구성
├── docker-compose.prod.yml # 프로덕션 환경 구성
└── README.md            # 이 파일
```

## 🔒 보안

- **JWT 토큰**: Access/Refresh 토큰 기반 인증
- **API 게이트웨이**: Kong을 통한 중앙화된 보안 정책
- **서비스 간 통신**: 내부 서비스 토큰 기반 인증
- **데이터 암호화**: 민감한 데이터의 저장 시 암호화

## 📄 라이선스

이 프로젝트는 [라이선스 이름] 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

---

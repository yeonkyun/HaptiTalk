# HaptiTalk Prometheus & Grafana 모니터링

HaptiTalk 마이크로서비스 아키텍처를 위한 메트릭 기반 모니터링 시스템입니다.

## 구성 요소

### 1. Prometheus
- 메트릭 수집 및 저장
- 알림 관리
- 시계열 데이터베이스

### 2. Grafana
- 메트릭 시각화
- 대시보드 관리
- 알림 설정

### 3. Node Exporter
- 호스트 시스템 메트릭 수집 (CPU, 메모리, 디스크 등)

## 주요 기능

- 마이크로서비스 상태 모니터링
- 리소스 사용량 측정
- API 엔드포인트 응답 시간 모니터링
- 오류율 및 요청 수 추적
- 사용자 정의 메트릭 지원

## 사용 방법

```bash
# 시작하기
./start-monitoring.sh

# 중지하기
./stop-monitoring.sh
```

## 환경 변수 설정

기본 설정은 `.env` 파일에 정의되어 있으며, 필요에 따라 변경할 수 있습니다:

```
# 포트 설정
PROMETHEUS_PORT=9090    # Prometheus 웹 인터페이스 포트
GRAFANA_PORT=3000       # Grafana 웹 인터페이스 포트
NODE_EXPORTER_PORT=9100 # Node Exporter 메트릭 포트

# Grafana 계정 설정
GRAFANA_ADMIN_USER=admin
GRAFANA_ADMIN_PASSWORD=admin
```

## 접속 정보

- **Prometheus**: http://localhost:{PROMETHEUS_PORT} - 메트릭 쿼리 및 그래프
- **Grafana**: http://localhost:{GRAFANA_PORT} - 대시보드 및 시각화 (기본 계정: admin/admin)
- **Node Exporter**: http://localhost:{NODE_EXPORTER_PORT}/metrics - 호스트 시스템 메트릭

## 서비스 계측 방법

각 마이크로서비스에 다음 패키지를 추가하세요:

### Node.js 서비스
```bash
# Prometheus 클라이언트 라이브러리 설치
npm install prom-client
```

### Express.js 기본 설정 예제
```javascript
const express = require('express');
const app = express();
const client = require('prom-client');

// 메트릭 레지스트리 생성
const collectDefaultMetrics = client.collectDefaultMetrics;
const Registry = client.Registry;
const register = new Registry();
collectDefaultMetrics({ register });

// HTTP 요청 지표 생성
const httpRequestDurationMicroseconds = new client.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'code'],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10]
});
register.registerMetric(httpRequestDurationMicroseconds);

// 메트릭 엔드포인트 설정
app.get('/metrics', async (req, res) => {
  res.set('Content-Type', register.contentType);
  res.end(await register.metrics());
});

// 요청 처리 지표 수집 미들웨어
app.use((req, res, next) => {
  const end = httpRequestDurationMicroseconds.startTimer();
  res.on('finish', () => {
    end({ method: req.method, route: req.route?.path || req.path, code: res.statusCode });
  });
  next();
});
```

## 알림 설정

Grafana에서 다음과 같은 알림 규칙을 설정할 수 있습니다:

1. 서비스 다운 알림
2. 높은 CPU/메모리 사용량
3. 오류율 임계값 초과
4. 응답 시간 지연

## 대시보드 가이드

기본 대시보드에서는 다음 정보를 확인할 수 있습니다:

1. 서비스 상태 개요
2. 리소스 사용량 (CPU, 메모리, 디스크)
3. API 엔드포인트 성능
4. 오류율 및 응답 코드 분포 
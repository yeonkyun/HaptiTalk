# HaptiTalk Jaeger 분산 트레이싱

HaptiTalk 마이크로서비스 아키텍처를 위한 분산 트레이싱 시스템 구성입니다.

## 개요

Jaeger는 분산 트레이싱 시스템으로 마이크로서비스 환경에서 다음과 같은 이점을 제공합니다:

- 요청의 전체 경로 추적 (End-to-end distributed tracing)
- 서비스 간 호출 지연 시간 측정
- 성능 병목 구간 식별
- 오류 및 문제 추적/디버깅

## 구성 요소

### 1. Jaeger

- **Jaeger UI**: 트레이스 시각화 및 분석
- **Jaeger Collector**: 스팬 데이터 수집 및 저장
- **Jaeger Agent**: 서비스로부터 스팬 데이터 수신
- **Jaeger Query**: 스팬 데이터 검색 서비스

### 2. OpenTelemetry Collector

- 다양한 형식의 트레이싱 데이터 수집
- 데이터 처리 및 변환
- Jaeger로 데이터 전송

## 설치 및 실행

```bash
# Jaeger 및 OpenTelemetry Collector 시작
cd infrastructure/monitoring/jaeger
./start-monitoring.sh

# Jaeger 및 OpenTelemetry Collector 중지
./stop-monitoring.sh
```

## 접속 정보

- **Jaeger UI**: http://localhost:16686 - 트레이스 검색 및 시각화
- **OpenTelemetry Collector gRPC**: http://localhost:4317 - OTLP gRPC 엔드포인트
- **OpenTelemetry Collector HTTP**: http://localhost:4318 - OTLP HTTP 엔드포인트
- **Prometheus Metrics**: http://localhost:8889/metrics - OpenTelemetry Collector 메트릭
- **zPages Dashboard**: http://localhost:55679 - OpenTelemetry Collector 디버깅

## 서비스 통합 방법

### Node.js 서비스 (예: Express)

1. 필요한 패키지 설치:

```bash
npm install @opentelemetry/sdk-node @opentelemetry/auto-instrumentations-node @opentelemetry/exporter-trace-otlp-http
```

2. 트레이싱 초기화 파일 생성 (`tracing.js`):

```javascript
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

// 서비스 이름 정의
const serviceName = 'your-service-name';

// OpenTelemetry Collector 엔드포인트 설정
const exporter = new OTLPTraceExporter({
  url: process.env.OTEL_EXPORTER_OTLP_ENDPOINT || 'http://localhost:4318/v1/traces',
});

// SDK 초기화
const sdk = new NodeSDK({
  serviceName,
  traceExporter: exporter,
  instrumentations: [
    getNodeAutoInstrumentations({
      '@opentelemetry/instrumentation-fs': { enabled: false },
    }),
  ],
});

// 애플리케이션 시작 시 SDK 시작
sdk.start();

// 애플리케이션 종료 시 SDK 종료
process.on('SIGTERM', () => {
  sdk.shutdown()
    .then(() => console.log('Tracing terminated'))
    .catch((error) => console.log('Error terminating tracing', error))
    .finally(() => process.exit(0));
});
```

3. 애플리케이션 진입점에서 트레이싱 초기화 (예: `app.js`):

```javascript
// 가장 먼저 트레이싱 초기화
require('./tracing');

const express = require('express');
// ... 나머지 코드
```

### 수동 스팬 생성 예제

```javascript
const { trace } = require('@opentelemetry/api');

async function handleRequest(req, res) {
  // 현재 트레이싱 컨텍스트 가져오기
  const tracer = trace.getTracer('my-service');
  
  // 수동 스팬 생성
  const span = tracer.startSpan('process-data');
  
  try {
    // 스팬에 속성 추가
    span.setAttribute('user.id', req.userId);
    
    // 비즈니스 로직 수행
    const result = await processData(req.body);
    
    // 추가 속성 설정
    span.setAttribute('process.status', 'success');
    
    res.json(result);
  } catch (error) {
    // 에러 정보 기록
    span.recordException(error);
    span.setAttribute('process.status', 'error');
    res.status(500).json({ error: error.message });
  } finally {
    // 스팬 종료
    span.end();
  }
}
```

## 트러블슈팅

- **트레이스가 보이지 않음**: 
  - 서비스가 올바른 엔드포인트로 트레이스를 전송하는지 확인
  - 네트워크 연결 및 방화벽 설정 확인
  - Docker 네트워크 설정 확인

- **OpenTelemetry Collector 문제**:
  - 로그 확인: `docker logs haptitalk-otel-collector`
  - 설정 파일 오류 확인
  - zPages 대시보드 확인하여 문제 진단

- **성능 문제**:
  - 샘플링 비율 조정 고려
  - 수집기 리소스 할당량 확인

## 추가 리소스

- [Jaeger 공식 문서](https://www.jaegertracing.io/docs/latest/)
- [OpenTelemetry 공식 문서](https://opentelemetry.io/docs/)
- [OpenTelemetry JavaScript SDK](https://github.com/open-telemetry/opentelemetry-js) 
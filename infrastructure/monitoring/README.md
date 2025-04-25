# HaptiTalk 통합 모니터링 시스템

HaptiTalk 마이크로서비스 아키텍처를 위한 통합 모니터링 시스템 구성입니다.

## 구성 요소

### 1. ELK 스택 (로그 모니터링)

[ELK 스택 설정 및 사용 방법](./elk/README.md)

- Elasticsearch: 로그 데이터 저장 및 검색
- Logstash: 로그 수집 및 처리
- Kibana: 로그 시각화 및 대시보드
- Filebeat: 서비스에서 로그 수집

### 2. Prometheus & Grafana (메트릭 모니터링)

[Prometheus/Grafana 설정 및 사용 방법](./prometheus/README.md)

- Prometheus: 메트릭 수집 및 저장
- Grafana: 메트릭 시각화 및 대시보드
- Node Exporter: 시스템 메트릭 수집

### 3. Jaeger (분산 트레이싱)

[Jaeger 설정 및 사용 방법](./jaeger/README.md)

- Jaeger UI: 트레이스 시각화 및 분석
- Jaeger Collector: 스팬 데이터 수집 및 저장
- OpenTelemetry Collector: 다양한 형식의 트레이싱 데이터 수집 및 변환

## 주요 기능

### 로그 모니터링
- 마이크로서비스 로그 중앙 집중화
- 로그 기반 알림 및 대시보드
- 인덱스 수명 주기 관리
- 로그 레벨 및 서비스별 필터링

### 메트릭 모니터링
- 서비스 상태 및 리소스 사용량 추적
- API 성능 및 오류율 모니터링
- 사용자 정의 메트릭 지원
- 알림 설정 및 대시보드 제공

### 분산 트레이싱
- 요청의 전체 경로 추적
- 서비스 간 호출 지연 시간 측정
- 성능 병목 구간 식별
- 오류 및 문제 추적/디버깅

## 통합 모니터링

### 통합 모니터링 설정

HaptiTalk는 Grafana를 중심으로 모든 모니터링 데이터를 통합하여 볼 수 있도록 구성되어 있습니다. 이를 통해 다음과 같은 이점이 있습니다:

- 단일 인터페이스에서 모든 모니터링 데이터 확인 가능
- 서비스 상태, 로그, 트레이스 데이터의 상관 관계 분석
- 통합 알림 및 대시보드 구성

### 통합 데이터 소스

Grafana에는 다음 데이터 소스가 설정되어 있습니다:

1. **Prometheus**: 메트릭 데이터 조회
2. **Elasticsearch**: 로그 데이터 조회
3. **Jaeger**: 분산 트레이싱 데이터 조회

### 통합 대시보드

`HaptiTalk 통합 모니터링 대시보드`는 다음 정보를 한 화면에서 제공합니다:

- 서비스 상태 및 가용성
- API 응답 시간 및 오류율
- 중요 로그 메시지 (오류/경고)
- 성능이 느린 요청의 트레이스 정보

## 사용 방법

### 통합 모니터링 시작

```bash
# 전체 통합 모니터링 시스템 시작
./start-integrated-monitoring.sh

# 전체 통합 모니터링 시스템 중지
./stop-integrated-monitoring.sh
```

### 개별 모니터링 시스템 시작

```bash
# ELK 스택 시작
cd elk
./start-monitoring.sh

# Prometheus/Grafana 시작
cd prometheus
./start-monitoring.sh

# Jaeger 분산 트레이싱 시작
cd jaeger
./start-monitoring.sh
```

## 모니터링 접속 정보

### 통합 대시보드
- **Grafana**: http://localhost:3000 - 통합 모니터링 대시보드 (기본 계정: admin/admin)

### 개별 모니터링 시스템
- **Kibana**: http://localhost:5601 - 로그 분석 및 대시보드
- **Elasticsearch**: http://localhost:9200 - 로그 데이터 API
- **Prometheus**: http://localhost:9090 - 메트릭 쿼리 및 그래프
- **Jaeger UI**: http://localhost:16686 - 트레이스 검색 및 시각화 
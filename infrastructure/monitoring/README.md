# HaptiTalk 모니터링 시스템

HaptiTalk 마이크로서비스 아키텍처를 위한 모니터링 시스템 구성입니다.

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

## 사용 방법

```bash
# ELK 스택 시작
cd elk
./start-monitoring.sh

# ELK 스택 중지
./stop-monitoring.sh

# Prometheus/Grafana 시작
cd prometheus
./start-monitoring.sh

# Prometheus/Grafana 중지
./stop-monitoring.sh
```

## 모니터링 접속 정보

### ELK 스택
- **Kibana**: http://localhost:5601 - 로그 분석 및 대시보드
- **Elasticsearch**: http://localhost:9200 - 로그 데이터 API
- **Logstash**: http://localhost:9600 - 로그 수집 상태

### Prometheus/Grafana
- **Prometheus**: http://localhost:9090 - 메트릭 쿼리 및 그래프
- **Grafana**: http://localhost:3000 - 대시보드 및 시각화
- **Node Exporter**: http://localhost:9100/metrics - 시스템 메트릭 
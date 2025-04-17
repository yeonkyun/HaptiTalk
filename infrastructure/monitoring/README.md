# HaptiTalk 모니터링 시스템

HaptiTalk 마이크로서비스 아키텍처를 위한 모니터링 시스템 구성입니다.

## 구성 요소

### 1. ELK 스택 (로그 모니터링)

[ELK 스택 설정 및 사용 방법](./elk/README.md)

- Elasticsearch: 로그 데이터 저장 및 검색
- Logstash: 로그 수집 및 처리
- Kibana: 로그 시각화 및 대시보드
- Filebeat: 서비스에서 로그 수집

### 주요 기능

- 마이크로서비스 로그 중앙 집중화
- 로그 기반 알림 및 대시보드
- 인덱스 수명 주기 관리
- 로그 레벨 및 서비스별 필터링

### 사용 방법

```bash
# ELK 스택 시작
cd elk
./start-monitoring.sh

# ELK 스택 중지
./stop-monitoring.sh
```

## 모니터링 접속 정보

- **Kibana**: http://localhost:5601 - 로그 분석 및 대시보드
- **Elasticsearch**: http://localhost:9200 - 로그 데이터 API
- **Logstash**: http://localhost:9600 - 로그 수집 상태 
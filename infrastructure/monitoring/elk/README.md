# HaptiTalk 모니터링 스택 (ELK)

HaptiTalk 애플리케이션의 로그 수집, 분석 및 모니터링을 위한 ELK(Elasticsearch, Logstash, Kibana) 스택 설정입니다.

## 구성 요소

- **Elasticsearch**: 로그 데이터 저장 및 검색 엔진
- **Logstash**: 로그 데이터 수집 및 변환 파이프라인
- **Kibana**: 로그 데이터 시각화 및 분석 대시보드
- **Filebeat**: 로그 데이터 수집 에이전트

## 설치 및 실행

### 사전 요구사항

- Docker 및 Docker Compose 설치
- 최소 4GB 이상의 RAM (ELK 스택 실행을 위해)

### 환경 설정

1. .env.example을 .env로 복사합니다:
   ```bash
   cp .env.example .env
   ```

2. .env 파일에서 보안 키 값과 필요한 포트를 변경합니다:
   ```
   # 보안 키 설정
   KIBANA_REPORTING_KEY=<강력한 랜덤 값>
   KIBANA_SECURITY_KEY=<강력한 랜덤 값>
   
   # 포트 설정 (충돌 시 변경)
   ELASTICSEARCH_PORT=9200
   KIBANA_PORT=5601
   LOGSTASH_TCP_PORT=5000
   ```

### 스택 실행

제공된 스크립트를 사용하여 쉽게 실행할 수 있습니다:

```bash
# 실행 권한 부여
chmod +x start-monitoring.sh
chmod +x stop-monitoring.sh

# 모니터링 스택 시작
./start-monitoring.sh
```

### 스택 중지

```bash
./stop-monitoring.sh
```

## 접속 정보

- **Kibana**: http://localhost:5601
- **Elasticsearch**: http://localhost:9200
- **Logstash**: http://localhost:9600

## 로그 수집

filebeat.yml 파일은 다음 서비스의 로그를 수집하도록 구성되어 있습니다:

- auth-service
- user-service
- realtime-service
- session-service
- feedback-service

## 자동 설정

시스템은 자동으로 다음 설정을 수행합니다:

1. **인덱스 수명 주기 관리 (ILM)**: 로그 데이터는 자동으로 관리됩니다:
   - Hot 단계: 최근 1일 데이터 (5GB 이하)
   - Warm 단계: 2일 이후 데이터 (최적화)
   - Cold 단계: 7일 이후 데이터 (압축)
   - Delete 단계: 30일 이후 데이터 (삭제)

2. **기본 대시보드**: 설치 시 자동으로 기본 대시보드가 생성됩니다:
   - 로그 레벨별 분석
   - 서비스별 로그 분석
   - 상세 로그 목록

## 문제 해결

### 포트 충돌

기본 포트 설정은 .env 파일에서 정의됩니다:
```
ELASTICSEARCH_PORT=9200
KIBANA_PORT=5601
LOGSTASH_BEATS_PORT=5044
LOGSTASH_TCP_PORT=5000
LOGSTASH_API_PORT=9600
```

포트 충돌이 발생하면 .env 파일에서 포트 값을 변경하세요.

### 용량 문제

Elasticsearch가 충분한 디스크 공간을 사용할 수 있도록 설정되어 있는지 확인하세요. 오래된 로그를 주기적으로 정리하거나 인덱스 수명 주기 관리(ILM) 설정을 조정하여 디스크 공간을 효율적으로 관리할 수 있습니다.

### 메모리 부족

기본 메모리 설정은 개발 환경에 맞게 조정되어 있습니다. 프로덕션 환경에서는 .env 파일의 자바 힙 메모리 설정을 시스템 리소스에 맞게 조절하세요:

```
ES_JAVA_OPTS=-Xms1g -Xmx1g
LS_JAVA_OPTS=-Xmx512m -Xms512m
```

### 로그가 표시되지 않음

로그가 표시되지 않는 경우 다음을 확인하세요:

1. Filebeat 설정이 올바른지 확인합니다:
   ```bash
   docker logs haptitalk-filebeat
   ```

2. 로그 디렉토리가 존재하고 적절한 권한이 있는지 확인합니다:
   ```bash
   ls -la /var/log/api
   ```

3. Logstash 파이프라인이 올바르게 실행되고 있는지 확인합니다:
   ```bash
   docker logs haptitalk-logstash
   ``` 
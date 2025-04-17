#!/bin/bash

# 환경 변수 설정 확인
if [ ! -f .env ]; then
  echo "환경 변수 파일(.env)이 없습니다. 예시 파일을 복사합니다."
  cp .env.example .env
  echo "환경 변수 파일이 생성되었습니다. 필요한 경우 편집하세요."
fi

# 권한 설정
echo "권한 설정 중..."
chmod +x elasticsearch/setup-ilm.sh
chmod +x kibana/setup-dashboards.sh

# 모니터링 네트워크 생성 (없는 경우)
if ! docker network ls | grep -q haptitalk_monitor_network; then
  echo "모니터링 네트워크 생성 중..."
  docker network create haptitalk_monitor_network
fi

# 도커 컴포즈 시작
echo "모니터링 스택 시작 중..."
if ! docker-compose up -d; then
  echo "=========================================================="
  echo "오류: 모니터링 스택 시작 중 문제가 발생했습니다."
  echo "포트 충돌이 발생한 경우 .env 파일에서 포트 설정을 변경하세요."
  echo "예시: LOGSTASH_TCP_PORT=5046"
  echo "=========================================================="
  exit 1
fi

echo "모니터링 스택이 시작되었습니다."
echo "Kibana: http://localhost:${KIBANA_PORT:-5601}"
echo "Elasticsearch: http://localhost:${ELASTICSEARCH_PORT:-9200}"
echo "Logstash API: http://localhost:${LOGSTASH_API_PORT:-9600}" 
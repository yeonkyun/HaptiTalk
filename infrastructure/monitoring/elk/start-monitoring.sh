#!/bin/bash

# 환경 변수 로드 (프로젝트 루트 .env 파일)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"

if [ -f "$PROJECT_ROOT/.env" ]; then
  echo "✅ 프로젝트 루트 환경 변수 로드 중..."
  source "$PROJECT_ROOT/.env"
  export $(cat "$PROJECT_ROOT/.env" | grep -v '#' | xargs)
elif [ -f .env ]; then
  echo "✅ 로컬 ELK 환경 변수 로드 중..."
  source .env
elif [ -f .env.example ]; then
  echo "환경 변수 파일(.env)이 없습니다. 예시 파일을 복사합니다."
  cp .env.example .env
  source .env
  echo "환경 변수 파일이 생성되었습니다. 필요한 경우 편집하세요."
else
  echo "⚠️ 환경 변수 파일이 없습니다. 기본 설정을 사용합니다."
fi

# 권한 설정
echo "권한 설정 중..."
chmod +x elasticsearch/setup-ilm.sh
chmod +x kibana/setup-dashboards.sh
chmod +x setup-filebeat-permissions.sh

# 로그 디렉토리가 없는 경우 생성
echo "로그 디렉토리 확인 중..."
if [ "$(uname)" == "Darwin" ]; then
  # macOS에서는 관리자 권한으로 실행하도록 안내
  echo "macOS에서는 sudo 권한으로 로그 디렉토리를 생성해야 할 수 있습니다."
  echo "필요한 경우 별도로 setup-filebeat-permissions.sh 스크립트를 sudo로 실행하세요."
else
  # Linux 환경에서는 스크립트 실행 시도
  sudo ./setup-filebeat-permissions.sh || true
fi

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

# Elasticsearch ILM 정책 설정
echo "Elasticsearch ILM 정책 설정을 위해 대기 중..."
sleep 20 # Elasticsearch가 완전히 시작될 때까지 대기

echo "Elasticsearch ILM 정책 설정 중..."
docker exec haptitalk-elasticsearch /usr/share/elasticsearch/setup-ilm.sh

echo "모니터링 스택이 시작되었습니다."
echo "Kibana: http://localhost:${KIBANA_PORT:-5601}"
echo "Elasticsearch: http://localhost:${ELASTICSEARCH_PORT:-9200}"
echo "Logstash API: http://localhost:${LOGSTASH_API_PORT:-9600}" 
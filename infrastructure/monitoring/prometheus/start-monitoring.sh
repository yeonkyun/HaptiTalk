#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd "$SCRIPT_DIR"

echo "📊 HaptiTalk Prometheus/Grafana 모니터링 시스템 시작 중..."

# 필요한 디렉토리 생성
mkdir -p ./config

# 환경 변수 로드 (프로젝트 루트 .env 파일)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../" && pwd)"
if [ -f "$PROJECT_ROOT/.env" ]; then
  echo "✅ 프로젝트 루트 환경 변수 로드 중..."
  source "$PROJECT_ROOT/.env"
  export $(cat "$PROJECT_ROOT/.env" | grep -v '#' | xargs)
else
  echo "⚠️ .env 파일이 없습니다. 기본 설정을 사용합니다."
fi

# 환경 변수 값 교체
if [ -f ./config/prometheus.yml ]; then
  echo "✅ Prometheus 설정 파일 변수 교체 중..."
  envsubst < ./config/prometheus.yml > ./config/prometheus.yml.tmp
  mv ./config/prometheus.yml.tmp ./config/prometheus.yml
fi

# 대시보드 디렉토리 생성
mkdir -p ../grafana/provisioning/dashboards/json

# Grafana 대시보드에 데이터소스 UID 설정
if [ -f ../grafana/provisioning/dashboards/json/nodejs-services-dashboard.json ]; then
  echo "✅ Grafana 대시보드 데이터소스 UID 업데이트 중..."
  sed -i.bak "s/\"uid\": \"PBFA97CFB590B2093\"/\"uid\": \"${PROMETHEUS_DATASOURCE_UID}\"/g" \
      ../grafana/provisioning/dashboards/json/nodejs-services-dashboard.json
  rm -f ../grafana/provisioning/dashboards/json/nodejs-services-dashboard.json.bak
fi

# 권한 설정
chmod +x ./stop-monitoring.sh

# Docker Compose 실행
docker-compose up -d

echo "✅ HaptiTalk Prometheus/Grafana 모니터링 시스템이 시작되었습니다."
echo "📊 Prometheus 대시보드: http://localhost:${PROMETHEUS_PORT}"
echo "📊 Grafana 대시보드: http://localhost:${GRAFANA_PORT} (기본 계정: ${GRAFANA_ADMIN_USER}/${GRAFANA_ADMIN_PASSWORD})"
echo "🔍 Node Exporter 메트릭: http://localhost:${NODE_EXPORTER_PORT}/metrics" 
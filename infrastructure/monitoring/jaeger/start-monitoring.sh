#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
cd "$SCRIPT_DIR"

# 환경 변수 파일이 있으면 로드
if [ -f .env ]; then
  echo "Loading environment variables from .env file"
  set -a
  source .env
  set +a
fi

# 네트워크 확인 및 생성
if ! docker network ls | grep -q haptitalk_network; then
  echo "Creating haptitalk_network"
  docker network create haptitalk_network
fi

# Jaeger 및 OpenTelemetry Collector 실행
echo "Starting Jaeger and OpenTelemetry Collector"
if ! docker-compose up -d; then
  echo "Failed to start Jaeger monitoring"
  exit 1
fi

# 서비스 상태 확인
echo "Checking service status"
sleep 5

if docker ps | grep -q haptitalk-jaeger; then
  echo "✅ Jaeger is running"
else
  echo "❌ Jaeger failed to start"
  exit 1
fi

if docker ps | grep -q haptitalk-otel-collector; then
  echo "✅ OpenTelemetry Collector is running"
else
  echo "❌ OpenTelemetry Collector failed to start"
  exit 1
fi

echo "Jaeger UI is available at: http://localhost:${JAEGER_UI_PORT:-16686}"
echo "OpenTelemetry Collector is available at: http://localhost:${OTEL_COLLECTOR_PORT:-4317} (gRPC)"
echo "OpenTelemetry Collector HTTP is available at: http://localhost:${OTEL_COLLECTOR_HTTP_PORT:-4318} (HTTP)"
echo "Prometheus metrics endpoint: http://localhost:${OTEL_COLLECTOR_PROM_PORT:-8889}/metrics"
echo "zPages dashboard: http://localhost:${OTEL_COLLECTOR_ZPAGES_PORT:-55679}"
echo ""
echo "Jaeger monitoring has been successfully started" 
#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
cd "$SCRIPT_DIR"

echo "📊 HaptiTalk Prometheus/Grafana 모니터링 시스템 중지 중..."
docker-compose down

echo "✅ HaptiTalk Prometheus/Grafana 모니터링 시스템이 중지되었습니다." 
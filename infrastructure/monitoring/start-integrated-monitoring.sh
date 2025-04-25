#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}HaptiTalk 통합 모니터링 시스템 시작 중...${NC}"

# 현재 디렉토리 저장
CURRENT_DIR=$(pwd)

# ELK 스택 시작
echo -e "${GREEN}ELK 스택 시작 중...${NC}"
cd "$CURRENT_DIR/elk"
./start-monitoring.sh

# 잠시 대기
sleep 5

# Jaeger 시작
echo -e "${GREEN}Jaeger 분산 트레이싱 시작 중...${NC}"
cd "$CURRENT_DIR/jaeger"
./start-monitoring.sh

# 잠시 대기
sleep 5

# Prometheus 및 Grafana 시작
echo -e "${GREEN}Prometheus/Grafana 시작 중...${NC}"
cd "$CURRENT_DIR/prometheus"
./start-monitoring.sh

# 원래 디렉토리로 복귀
cd "$CURRENT_DIR"

echo -e "${GREEN}모든 모니터링 시스템이 성공적으로 시작되었습니다.${NC}"
echo -e "접속 정보:"
echo -e "${YELLOW}Grafana:${NC} http://localhost:\${GRAFANA_PORT:-3333} (기본 계정: admin/admin)"
echo -e "${YELLOW}Prometheus:${NC} http://localhost:\${PROMETHEUS_PORT:-9090}"
echo -e "${YELLOW}Kibana:${NC} http://localhost:\${KIBANA_PORT:-5601}"
echo -e "${YELLOW}Jaeger UI:${NC} http://localhost:\${JAEGER_UI_PORT:-16686}"
echo -e "${YELLOW}Elasticsearch:${NC} http://localhost:\${ELASTICSEARCH_PORT:-9200}"

echo -e "${GREEN}통합 대시보드는 Grafana에서 'Main Dashboard - System Overview'에서 확인하실 수 있습니다.${NC}"
echo -e "${YELLOW}참고: 시스템이 완전히 시작되는 데 몇 분 정도 소요될 수 있습니다.${NC}" 
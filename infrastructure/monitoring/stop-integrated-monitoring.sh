#!/bin/bash

# 색상 정의
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}HaptiTalk 통합 모니터링 시스템 중지 중...${NC}"

# 현재 디렉토리 저장
CURRENT_DIR=$(pwd)

# Prometheus 및 Grafana 중지
echo -e "${GREEN}Prometheus/Grafana 중지 중...${NC}"
cd "$CURRENT_DIR/prometheus"
./stop-monitoring.sh

# Jaeger 중지
echo -e "${GREEN}Jaeger 분산 트레이싱 중지 중...${NC}"
cd "$CURRENT_DIR/jaeger"
./stop-monitoring.sh

# ELK 스택 중지
echo -e "${GREEN}ELK 스택 중지 중...${NC}"
cd "$CURRENT_DIR/elk"
./stop-monitoring.sh

# 원래 디렉토리로 복귀
cd "$CURRENT_DIR"

echo -e "${GREEN}모든 모니터링 시스템이 성공적으로 중지되었습니다.${NC}" 
#!/bin/bash

# 라즈베리파이 도커 컨테이너 문제 해결 스크립트
# 작성자: 최태산
# 날짜: 2025-05-25
# 위치: infrastructure/deployment/fix-raspberry-pi-containers.sh

set -e

echo "🔧 라즈베리파이 도커 컨테이너 문제 해결 시작..."

# 1. 문제가 있는 컨테이너들 중지
echo "📦 문제가 있는 컨테이너들 중지 중..."
docker-compose -f docker-compose.prod.yml stop filebeat kong || true

# 2. 중복 컨테이너 제거
echo "🗑️ 중복 컨테이너 제거 중..."
docker rm -f zealous_heisenberg || true

# 3. Swap 메모리 확장 (현재 200MB → 2GB)
echo "💾 Swap 메모리 확장 중..."
sudo swapoff /var/swap || true
sudo dd if=/dev/zero of=/var/swap bs=1M count=2048
sudo mkswap /var/swap
sudo swapon /var/swap
echo "✅ Swap 메모리가 2GB로 확장되었습니다."

# 4. Docker 로그 정리 (디스크 공간 확보)
echo "🧹 Docker 로그 정리 중..."
docker system prune -f
docker volume prune -f

# 5. 수정된 설정으로 컨테이너 재시작
echo "🚀 수정된 설정으로 컨테이너 재시작 중..."
docker-compose -f docker-compose.prod.yml up -d --no-deps filebeat kong

# 6. 컨테이너 상태 확인
echo "📊 컨테이너 상태 확인 중..."
sleep 10
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 7. 메모리 사용량 확인
echo "💻 시스템 리소스 사용량:"
free -h
echo ""
df -h /

# 8. Kong 헬스체크 확인
echo "🏥 Kong 헬스체크 확인 중..."
sleep 5
curl -f http://localhost:8001/status || echo "⚠️ Kong 헬스체크 실패"

echo "✅ 라즈베리파이 컨테이너 문제 해결 완료!"
echo ""
echo "📋 다음 단계:"
echo "1. 5분 후 'docker ps' 명령으로 모든 컨테이너가 정상 실행되는지 확인"
echo "2. Filebeat 로그 확인: docker logs haptitalk-filebeat"
echo "3. Kong 로그 확인: docker logs haptitalk-kong"
echo "4. 시스템 리소스 모니터링: watch 'free -h && echo && docker stats --no-stream'" 
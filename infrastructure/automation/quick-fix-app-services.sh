#!/bin/bash
set -e

echo "===== 라즈베리파이 애플리케이션 서비스 빠른 복구 ====="
echo "실행 시간: $(date)"

# 작업 디렉토리로 이동
cd /home/${USER}/haptitalk

# 환경 변수 로드
if [ -f ".env" ]; then
    source .env
    echo "✅ 환경 변수 로드 완료"
else
    echo "❌ .env 파일이 없습니다!"
    exit 1
fi

echo "==== 1단계: 현재 상태 확인 ===="
echo "실행 중인 컨테이너:"
docker ps --format "table {{.Names}}\t{{.Status}}"

echo ""
echo "==== 2단계: 실패한 애플리케이션 서비스 찾기 ===="
FAILED_APPS=()
APP_SERVICES=("auth-service" "session-service" "user-service" "feedback-service" "report-service" "realtime-service")

for service in "${APP_SERVICES[@]}"; do
    if ! docker ps | grep -q "haptitalk-$service.*Up"; then
        echo "❌ $service: 실행 중이 아님"
        FAILED_APPS+=("$service")
    else
        echo "✅ $service: 정상 실행 중"
    fi
done

if [ ${#FAILED_APPS[@]} -eq 0 ]; then
    echo "🎉 모든 애플리케이션 서비스가 정상입니다!"
    exit 0
fi

echo ""
echo "실패한 서비스: ${FAILED_APPS[*]}"

echo ""
echo "==== 3단계: 실패한 서비스 복구 ===="

for service in "${FAILED_APPS[@]}"; do
    echo "🔄 $service 복구 중..."
    
    # 기존 컨테이너 정리
    docker-compose -f docker-compose.prod.yml stop "$service" 2>/dev/null || true
    docker-compose -f docker-compose.prod.yml rm -f "$service" 2>/dev/null || true
    
    # 서비스 재시작
    if docker-compose -f docker-compose.prod.yml up -d "$service"; then
        echo "✅ $service 재시작 성공"
        sleep 5
        
        # 상태 확인
        if docker ps | grep -q "haptitalk-$service.*Up"; then
            echo "✅ $service 정상 실행 중"
        else
            echo "⚠️ $service 시작했지만 상태 불안정"
            echo "로그 확인:"
            docker-compose -f docker-compose.prod.yml logs --tail=10 "$service"
        fi
    else
        echo "❌ $service 재시작 실패"
        echo "로그 확인:"
        docker-compose -f docker-compose.prod.yml logs --tail=10 "$service"
    fi
    
    echo ""
done

echo "==== 4단계: 최종 상태 확인 ===="
echo "전체 컨테이너 상태:"
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "애플리케이션 서비스 상태:"
for service in "${APP_SERVICES[@]}"; do
    if docker ps | grep -q "haptitalk-$service.*Up"; then
        echo "✅ $service: 정상"
    else
        echo "❌ $service: 실패"
    fi
done

echo ""
echo "===== 복구 완료 =====" 
#!/bin/bash

# HaptiTalk Docker 로그 자동 정리 스크립트
# 이 스크립트는 cron으로 주기적 실행을 권장합니다
# 
# === Cron 설정 예시 ===
# 매일 새벽 2시 실행:
# 0 2 * * * /home/tae4an/haptitalk/infrastructure/automation/docker-log-cleanup.sh >> /home/tae4an/haptitalk/logs/cron-docker-cleanup.log 2>&1
#
# 매주 일요일 새벽 3시 실행:
# 0 3 * * 0 /home/tae4an/haptitalk/infrastructure/automation/docker-log-cleanup.sh >> /home/tae4an/haptitalk/logs/cron-docker-cleanup.log 2>&1
#
# === 수동 실행 ===
# cd /home/tae4an/haptitalk && ./infrastructure/automation/docker-log-cleanup.sh
#
# === 라즈베리파이 Cron 설정 방법 ===
# 1. crontab -e
# 2. 위의 예시 중 하나를 복사해서 붙여넣기
# 3. 저장 후 종료
# 4. sudo systemctl restart cron  (필요시)

set -e

LOG_FILE="/home/${USER}/haptitalk/logs/docker-cleanup_$(date +%Y%m%d_%H%M%S).log"
mkdir -p "/home/${USER}/haptitalk/logs"

echo "===== Docker 로그 정리 시작: $(date) =====" | tee -a "$LOG_FILE"

# 1. Docker 시스템 정보 확인
echo "=== Docker 시스템 정보 ===" | tee -a "$LOG_FILE"
docker system df | tee -a "$LOG_FILE"

# 2. 디스크 사용량 확인 (정리 전)
echo "=== 정리 전 디스크 사용량 ===" | tee -a "$LOG_FILE"
df -h | tee -a "$LOG_FILE"

# 3. 컨테이너 로그 크기 확인 및 정리
echo "=== 컨테이너 로그 정리 ===" | tee -a "$LOG_FILE"
cd /home/${USER}/haptitalk

# 각 컨테이너의 로그 크기 확인
echo "정리 전 컨테이너 로그 크기:" | tee -a "$LOG_FILE"
for container in $(docker ps -q); do
    container_name=$(docker inspect --format='{{.Name}}' $container | sed 's/\///')
    log_path="/var/lib/docker/containers/$container/$container-json.log"
    if [ -f "$log_path" ]; then
        log_size=$(sudo du -h "$log_path" 2>/dev/null | cut -f1)
        echo "$container_name: $log_size" | tee -a "$LOG_FILE"
    fi
done

# 4. Docker 시스템 정리
echo "=== Docker 시스템 정리 시작 ===" | tee -a "$LOG_FILE"

# 사용하지 않는 이미지 정리
echo "사용하지 않는 이미지 정리..." | tee -a "$LOG_FILE"
REMOVED_IMAGES=$(docker image prune -f 2>&1 | grep "Total reclaimed space" || echo "정리할 이미지 없음")
echo "$REMOVED_IMAGES" | tee -a "$LOG_FILE"

# 사용하지 않는 컨테이너 정리
echo "사용하지 않는 컨테이너 정리..." | tee -a "$LOG_FILE"
REMOVED_CONTAINERS=$(docker container prune -f 2>&1 | grep "Total reclaimed space" || echo "정리할 컨테이너 없음")
echo "$REMOVED_CONTAINERS" | tee -a "$LOG_FILE"

# 사용하지 않는 네트워크 정리
echo "사용하지 않는 네트워크 정리..." | tee -a "$LOG_FILE"
REMOVED_NETWORKS=$(docker network prune -f 2>&1 | grep "Total reclaimed space" || echo "정리할 네트워크 없음")
echo "$REMOVED_NETWORKS" | tee -a "$LOG_FILE"

# 빌드 캐시 정리 (주의: 개발 환경에서는 제외)
echo "빌드 캐시 정리..." | tee -a "$LOG_FILE"
REMOVED_BUILD_CACHE=$(docker builder prune -f 2>&1 | grep "Total reclaimed space" || echo "정리할 빌드 캐시 없음")
echo "$REMOVED_BUILD_CACHE" | tee -a "$LOG_FILE"

# 5. 로그 로테이션 (Docker가 자동으로 관리하지만 추가 보험)
echo "=== 로그 로테이션 확인 ===" | tee -a "$LOG_FILE"
for container in $(docker ps -q); do
    container_name=$(docker inspect --format='{{.Name}}' $container | sed 's/\///')
    log_path="/var/lib/docker/containers/$container/$container-json.log"
    if [ -f "$log_path" ]; then
        log_size_mb=$(sudo du -m "$log_path" 2>/dev/null | cut -f1)
        # 50MB 초과 시 경고 (Docker 로그 제한이 제대로 작동하지 않는 경우)
        if [ "$log_size_mb" -gt 50 ]; then
            echo "경고: $container_name 로그가 ${log_size_mb}MB로 제한을 초과했습니다!" | tee -a "$LOG_FILE"
        fi
    fi
done

# 6. 정리 후 상태 확인
echo "=== 정리 후 상태 ===" | tee -a "$LOG_FILE"
docker system df | tee -a "$LOG_FILE"

echo "=== 정리 후 디스크 사용량 ===" | tee -a "$LOG_FILE"
df -h | tee -a "$LOG_FILE"

# 7. 결과 요약
echo "=== 정리 결과 요약 ===" | tee -a "$LOG_FILE"
echo "이미지 정리: $REMOVED_IMAGES" | tee -a "$LOG_FILE"
echo "컨테이너 정리: $REMOVED_CONTAINERS" | tee -a "$LOG_FILE"
echo "네트워크 정리: $REMOVED_NETWORKS" | tee -a "$LOG_FILE"
echo "빌드 캐시 정리: $REMOVED_BUILD_CACHE" | tee -a "$LOG_FILE"

# 8. 로그 파일 정리 (30일 이상 된 정리 로그 삭제)
echo "=== 이전 정리 로그 정리 ===" | tee -a "$LOG_FILE"
find "/home/${USER}/haptitalk/logs" -name "docker-cleanup_*.log" -mtime +30 -delete 2>/dev/null || true
echo "30일 이상 된 정리 로그 파일 삭제 완료" | tee -a "$LOG_FILE"

echo "===== Docker 로그 정리 완료: $(date) =====" | tee -a "$LOG_FILE"

# 디스크 사용률이 80% 이상이면 알림 (선택사항)
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 80 ]; then
    echo "⚠️ 경고: 디스크 사용률이 ${DISK_USAGE}%입니다. 추가 정리가 필요할 수 있습니다." | tee -a "$LOG_FILE"
fi 
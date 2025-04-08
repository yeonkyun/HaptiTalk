#!/bin/sh

# Redis 초기화 스크립트
# Redis 서버 시작 후 필요한 초기 설정을 진행합니다.

# Redis 비밀번호 설정
REDIS_AUTH="-a ${REDIS_PASSWORD}"

# 앱 설정 캐싱
redis-cli ${REDIS_AUTH} SET "app:settings:theme" "dark"
redis-cli ${REDIS_AUTH} SET "app:settings:language" "ko"
redis-cli ${REDIS_AUTH} SET "app:settings:notifications" "true"
redis-cli ${REDIS_AUTH} SET "app:settings:haptic" "true"
redis-cli ${REDIS_AUTH} SET "app:settings:sound" "true"

# 햅틱 패턴 캐싱
redis-cli ${REDIS_AUTH} SET "haptic:pattern:tap" "100"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:double_tap" "100,200,100"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:long_press" "300"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:success" "100,50,200"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:error" "300,100,300"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:warning" "200,100,200"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:notification" "100,50,100"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:keyboard" "50"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:scroll" "30"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:impact_light" "50"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:impact_medium" "100"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:impact_heavy" "150"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:rigid" "75"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:soft" "50"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:selection" "50"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:slider_tick" "30"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:edge" "100"
redis-cli ${REDIS_AUTH} SET "haptic:pattern:toggle" "50"

# 실시간 채널 설정
redis-cli ${REDIS_AUTH} SET "realtime:channel:haptic" "haptic_events"
redis-cli ${REDIS_AUTH} SET "realtime:channel:chat" "chat_events"

# 설정 완료 표시
redis-cli ${REDIS_AUTH} SET "system:initialized" "true"

echo "Redis initialization completed"
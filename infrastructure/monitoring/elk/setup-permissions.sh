#!/bin/bash

# 실행 권한 부여
chmod +x elasticsearch/setup-ilm.sh

# 로그 디렉토리 생성 (없는 경우)
mkdir -p /var/log/api/auth-service
mkdir -p /var/log/api/user-service
mkdir -p /var/log/api/realtime-service
mkdir -p /var/log/api/session-service
mkdir -p /var/log/api/feedback-service

# 로그 디렉토리 권한 설정
sudo chmod -R 755 /var/log/api

echo "권한 설정이 완료되었습니다." 
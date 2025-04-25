#!/bin/bash

# 로그 디렉토리 생성
mkdir -p /var/log/api/auth-service
mkdir -p /var/log/api/user-service
mkdir -p /var/log/api/realtime-service
mkdir -p /var/log/api/session-service
mkdir -p /var/log/api/feedback-service
mkdir -p /var/log/filebeat

# 권한 설정
chmod -R 755 /var/log/api
chmod -R 755 /var/log/filebeat

# 소유권 설정 (Docker를 사용할 경우 1000:1000은 많은 컨테이너에서 사용하는 filebeat 사용자 ID)
chown -R 1000:1000 /var/log/api
chown -R 1000:1000 /var/log/filebeat

echo "Filebeat 권한 설정이 완료되었습니다." 
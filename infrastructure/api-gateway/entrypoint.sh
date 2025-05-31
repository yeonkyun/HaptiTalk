#!/bin/bash
set -e

# 템플릿 파일을 복사하고 환경 변수 치환
cp /tmp/kong.yml.template /tmp/kong.yml

echo "Kong 설정 파일에서 환경 변수 치환"

# JWT 관련 환경 변수 치환
envsubst < /tmp/kong.yml.template > /tmp/kong.yml

echo "환경 변수 치환 완료"

# Kong 시작
echo "Kong 서비스 시작"
exec /docker-entrypoint.sh kong docker-start 
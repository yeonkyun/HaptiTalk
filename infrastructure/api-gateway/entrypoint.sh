#!/bin/bash

echo "Kong 환경변수 치환 시작..."

# 환경변수 확인
if [ -z "$JWT_APP_KEY_ID" ] || [ -z "$JWT_ACCESS_SECRET" ]; then
    echo "필수 환경변수가 설정되지 않았습니다"
    echo "JWT_APP_KEY_ID: ${JWT_APP_KEY_ID:-'NOT SET'}"
    echo "JWT_ACCESS_SECRET: ${JWT_ACCESS_SECRET:-'NOT SET'}"
    exit 1
fi

echo "환경변수 확인 완료"
echo "JWT_APP_KEY_ID: ${JWT_APP_KEY_ID:0:10}..."
echo "JWT_ACCESS_SECRET: ${JWT_ACCESS_SECRET:0:10}..."

# 템플릿 파일에서 환경변수 치환 (임시 파일 사용)
echo "Kong 설정 파일 생성 중..."
TEMP_FILE="/tmp/kong.yml"
sed "s/\${JWT_APP_KEY_ID}/$JWT_APP_KEY_ID/g; s/\${JWT_ACCESS_SECRET}/$JWT_ACCESS_SECRET/g" \
    /usr/local/kong/declarative/kong.yml.template > $TEMP_FILE

if [ $? -eq 0 ]; then
    echo "Kong 설정 파일 생성 완료"
    echo "생성된 JWT 소비자 설정:"
    grep -A 5 "jwt_secrets:" $TEMP_FILE
    
    # 환경변수로 Kong이 읽을 수 있도록 설정
    export KONG_DECLARATIVE_CONFIG=$TEMP_FILE
    echo "Kong 설정 파일 경로 설정: $KONG_DECLARATIVE_CONFIG"
else
    echo "Kong 설정 파일 생성 실패"
    exit 1
fi

echo "환경변수 치환 완료!"

# Kong 시작 (올바른 명령어 사용)
echo "Kong 시작..."
exec /docker-entrypoint.sh kong docker-start 
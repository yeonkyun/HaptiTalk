#!/bin/bash
set -e

# 환경 변수 값 가져오기 (기본값 설정)
USERNAME=${API_DOCS_USERNAME:-apidocs}
PASSWORD=${API_DOCS_PASSWORD:-haptitalk-docs}

# 템플릿 파일을 복사하고 환경 변수 치환
cp /tmp/kong.yml.template /tmp/kong.yml

echo "Kong 설정 파일에서 환경 변수 치환"
echo "Username: $USERNAME, Password: [PROTECTED]"

# 환경 변수로 치환
sed "s/\"\${API_DOCS_USERNAME:-apidocs}\"/\"$USERNAME\"/g" /tmp/kong.yml > /tmp/kong.yml.new
cat /tmp/kong.yml.new > /tmp/kong.yml

sed "s/\"\${API_DOCS_PASSWORD:-haptitalk-docs}\"/\"$PASSWORD\"/g" /tmp/kong.yml > /tmp/kong.yml.new
cat /tmp/kong.yml.new > /tmp/kong.yml

echo "환경 변수 치환 결과 확인"
grep -A 3 basicauth_credentials /tmp/kong.yml

# Kong 시작
echo "Kong 서비스 시작"
exec /docker-entrypoint.sh kong docker-start 
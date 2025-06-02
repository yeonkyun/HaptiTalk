#!/bin/bash

# Docker 리소스 정리 스크립트
# 주기적으로 실행하여 Docker 리소스를 정리합니다.

echo -e "\033[1;34m======= Docker 시스템 정리 시작 =======\033[0m"

# 현재 상태 확인
echo -e "\033[1;33m현재 Docker 시스템 상태:\033[0m"
docker system df

# 중지된 컨테이너 정리
echo -e "\n\033[1;33m중지된 컨테이너 정리 중...\033[0m"
docker container prune -f

# 사용하지 않는 이미지 정리
echo -e "\n\033[1;33m사용하지 않는 이미지 정리 중...\033[0m"
docker image prune -a -f

# 사용하지 않는 볼륨 정리
echo -e "\n\033[1;33m사용하지 않는 볼륨 정리 중...\033[0m"
docker volume prune -f

# 네트워크 정리
echo -e "\n\033[1;33m사용하지 않는 네트워크 정리 중...\033[0m"
docker network prune -f

# 빌드 캐시 정리
echo -e "\n\033[1;33m빌드 캐시 정리 중...\033[0m"
docker builder prune -a -f

# 정리 후 상태 확인
echo -e "\n\033[1;33m정리 후 Docker 시스템 상태:\033[0m"
docker system df

echo -e "\n\033[1;34m======= Docker 시스템 정리 완료 =======\033[0m"
echo -e "\033[1;32mDocker 정리가 성공적으로 완료되었습니다.\033[0m" 
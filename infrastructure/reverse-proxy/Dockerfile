FROM nginx:1.25-alpine

# 기본 Nginx 설정 파일 제거
RUN rm -f /etc/nginx/conf.d/default.conf

# 사용자 설정 파일 복사
COPY nginx.conf /etc/nginx/nginx.conf

# 디렉토리 생성 (로그, 캐시 등)
RUN mkdir -p /var/cache/nginx /var/log/nginx

# 상태 확인용 빈 파일 생성
RUN touch /var/run/nginx.pid

# 포트 노출
EXPOSE 80 443

# Nginx 실행
CMD ["nginx", "-g", "daemon off;"]
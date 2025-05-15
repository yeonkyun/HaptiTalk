FROM node:18-alpine

WORKDIR /app

# 패키지 파일 복사
COPY package*.json ./

# 종속성 설치
RUN npm install && \
    npm install morgan prom-client

# 소스 코드 복사
COPY . .

# 헬스체크 및 시작 스크립트
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:${PORT:-3004}/health || exit 1

# 시작 명령어
CMD ["node", "src/app.js"]
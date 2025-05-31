FROM node:18-alpine

WORKDIR /app

# Node.js가 /app/api 디렉토리에서도 모듈을 찾도록 NODE_PATH 설정
ENV NODE_PATH=/app/api

# 1. user-service의 package.json 복사 및 메인 의존성 설치
COPY api/user-service/package*.json ./
RUN npm install --production # --production 플래그를 사용하여 개발 의존성은 제외할 수 있습니다.

# 2. 공유 모듈 코드 복사
COPY api/shared /app/api/shared

# 3. 공유 모듈 (kafka-client) 의존성 설치
#    주의: 공유 모듈이 여러 개이고 각자 package.json을 가진다면, 각 공유 모듈마다 이 단계를 반복하거나 스크립트로 처리해야 합니다.
#    여기서는 kafka-client만 있다고 가정합니다.
WORKDIR /app/api/shared/kafka-client  # kafka-client 디렉토리로 이동
RUN npm install --production          # kafka-client의 의존성 설치

# 4. 다시 user-service의 작업 디렉토리로 돌아옴
WORKDIR /app

# 5. user-service 소스 코드 복사
COPY api/user-service .

# 헬스체크 및 시작 스크립트
HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
  CMD wget -qO- http://localhost:${PORT:-3004}/health || exit 1

# 포트 설정
EXPOSE ${PORT}

# 시작 명령어
CMD ["npm", "start"]
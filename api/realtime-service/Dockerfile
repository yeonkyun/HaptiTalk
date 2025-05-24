FROM node:18-alpine

# 작업 디렉토리 설정
WORKDIR /app

# 의존성 파일 복사
COPY package*.json ./

# 의존성 설치
RUN npm install

# 공유 모듈 복사 (먼저)
COPY ../shared /app/api/shared

# 앱 소스 복사
COPY . .

# 포트 설정
EXPOSE ${PORT}

# 실행 명령
CMD ["npm", "start"]
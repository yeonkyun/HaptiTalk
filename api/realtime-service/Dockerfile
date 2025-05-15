FROM node:18-alpine

# 작업 디렉토리 설정
WORKDIR /app

# 의존성 파일 복사
COPY package*.json ./

# 의존성 설치
RUN npm install

# 앱 소스 복사
COPY . .

# shared 디렉토리 생성 (볼륨 마운트용)
RUN mkdir -p /app/api/shared

# 포트 설정
EXPOSE ${PORT}

# 실행 명령
CMD ["npm", "start"]
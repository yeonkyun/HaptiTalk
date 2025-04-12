# Node.js 18 LTS 버전을 베이스 이미지로 사용
FROM node:18-alpine

# 작업 디렉토리 설정
WORKDIR /app

# 패키지 파일 복사
COPY package*.json ./

# 의존성 설치
RUN npm install

# 소스 코드 복사
COPY . .

# 3002 포트 노출
EXPOSE 3002

# 애플리케이션 실행
CMD ["node", "src/app.js"]
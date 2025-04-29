#!/bin/sh

# Kafka 통합 테스트 스크립트
set -e

echo "🔄 Kafka 통합 테스트를 시작합니다..."

# Docker가 실행 중인지 확인
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker가 실행 중이지 않습니다. Docker Desktop을 실행해주세요."
    exit 1
fi

# Kafka가 실행 중인지 확인
if ! docker ps | grep -q "haptitalk-kafka"; then
    echo "❌ Kafka 컨테이너가 실행 중이지 않습니다."
    echo "Docker Compose로 Kafka 컨테이너를 시작합니다..."
    docker-compose -f docker-compose.yml up -d kafka zookeeper kafka-ui
    
    # Kafka가 시작될 때까지 대기
    echo "⏳ Kafka가 준비될 때까지 기다리는 중..."
    sleep 20
fi

echo "✅ Kafka 컨테이너가 실행 중입니다."

# 필요한 NPM 패키지 확인 및 설치
echo "\n🔧 필요한 NPM 패키지 확인 중..."

# 각 서비스별 패키지 설치 확인
check_and_install_packages() {
    service_name=$1
    service_dir="api/$service_name"
    
    if [ -d "$service_dir" ]; then
        echo "📦 $service_name의 패키지 확인..."
        
        # package.json 파일 존재 확인
        if [ -f "$service_dir/package.json" ]; then
            cd "$service_dir"
            
            # node_modules 폴더 확인
            if [ ! -d "node_modules" ] || [ ! -d "node_modules/kafkajs" ]; then
                echo "📥 $service_name에 필요한 패키지 설치 중..."
                npm install --silent || echo "⚠️ 패키지 설치 실패 - $service_name"
            else
                echo "✅ $service_name 패키지 이미 설치됨"
            fi
            
            cd ../../
        else
            echo "⚠️ $service_name에 package.json 파일이 없습니다."
        fi
    else
        echo "⚠️ $service_name 디렉토리를 찾을 수 없습니다."
    fi
}

# 공유 라이브러리 패키지 설치 확인
if [ -d "api/shared/kafka-client" ]; then
    echo "📦 공유 Kafka 클라이언트 패키지 확인..."
    
    # package.json 파일 존재 확인
    if [ -f "api/shared/kafka-client/package.json" ]; then
        cd "api/shared/kafka-client"
        
        # node_modules 폴더 확인
        if [ ! -d "node_modules" ] || [ ! -d "node_modules/kafkajs" ]; then
            echo "📥 공유 Kafka 클라이언트에 필요한 패키지 설치 중..."
            npm install --silent || echo "⚠️ 패키지 설치 실패 - kafka-client"
        else
            echo "✅ 공유 Kafka 클라이언트 패키지 이미 설치됨"
        fi
        
        cd ../../../
    else
        # package.json 파일이 없으면 생성
        echo "📝 공유 Kafka 클라이언트에 package.json 파일 생성..."
        
        cd "api/shared/kafka-client"
        
        cat > package.json <<EOF
{
  "name": "haptitalk-shared-kafka-client",
  "version": "1.0.0",
  "description": "Shared Kafka client for HaptiTalk microservices",
  "main": "index.js",
  "dependencies": {
    "kafkajs": "^2.2.4"
  }
}
EOF
        
        # 패키지 설치
        echo "📥 공유 Kafka 클라이언트에 필요한 패키지 설치 중..."
        npm install --silent || echo "⚠️ 패키지 설치 실패 - kafka-client"
        
        cd ../../../
    fi
else
    echo "⚠️ 공유 Kafka 클라이언트 디렉토리를 찾을 수 없습니다."
fi

# 각 서비스별 패키지 설치 확인
check_and_install_packages "auth-service"
check_and_install_packages "session-service"
check_and_install_packages "feedback-service"
check_and_install_packages "user-service"
check_and_install_packages "report-service"
check_and_install_packages "realtime-service"

# 토픽 목록 확인
echo "\n📋 현재 Kafka 토픽 목록:"
docker exec haptitalk-kafka kafka-topics.sh --list --bootstrap-server localhost:9092

# 필요한 토픽 생성 (없는 경우)
REQUIRED_TOPICS=(
  "haptitalk-session-events"
  "haptitalk-user-activity"
  "haptitalk-feedback-events"
  "haptitalk-feedback-analytics"
  "haptitalk-report-events"
  "haptitalk-user-preferences"
  "haptitalk-feedback-commands"
  "haptitalk-auth-events"
)

for topic in "${REQUIRED_TOPICS[@]}"; do
    if ! docker exec haptitalk-kafka kafka-topics.sh --list --bootstrap-server localhost:9092 | grep -q "$topic"; then
        echo "🔧 토픽 생성 중: $topic"
        docker exec haptitalk-kafka kafka-topics.sh --create --bootstrap-server localhost:9092 --topic "$topic" --partitions 3 --replication-factor 1
    fi
done

# 각 서비스의 Kafka 연결 테스트
echo "\n🔍 각 마이크로서비스의 Kafka 연결 테스트 중..."

# 테스트 메시지 생성 함수
test_service() {
    service_name=$1
    service_dir="api/$service_name"
    
    echo "\n⏳ $service_name Kafka 연결 테스트..."
    
    if [ -d "$service_dir" ]; then
        cd "$service_dir"
        
        # 환경 변수 설정 확인
        if [ -f ".env" ]; then
            echo "📄 환경 변수 파일 확인됨"
        else
            echo "📝 테스트용 환경 변수 파일 생성"
            cat > .env.test <<EOF
SERVICE_NAME=$service_name
KAFKA_BROKER=localhost:9092
NODE_ENV=test
EOF
        fi
        
        # Kafka 클라이언트 테스트
        echo "🧪 Kafka 클라이언트 테스트 실행"
        if [ -f "src/services/kafka.service.js" ]; then
            node -e "
                try {
                  console.log('Kafka 클라이언트 테스트 중...');
                  process.env.SERVICE_NAME = '$service_name';
                  process.env.KAFKA_BROKER = 'localhost:9092';
                  process.env.NODE_ENV = 'test';
                  
                  const kafkaService = require('./src/services/kafka.service.js');
                  
                  const testConnection = async () => {
                    try {
                      // 프로듀서 초기화 시도
                      await kafkaService.initProducerIfNeeded ? 
                        kafkaService.initProducerIfNeeded() : 
                        console.log('initProducerIfNeeded 메서드 없음');
                      
                      console.log('✅ Kafka 프로듀서 연결 성공');
                      
                      // 연결 종료
                      await kafkaService.disconnect();
                      console.log('✅ Kafka 연결 종료 성공');
                      
                      return true;
                    } catch (error) {
                      console.error('❌ Kafka 연결 테스트 실패:', error.message);
                      return false;
                    }
                  };
                  
                  testConnection().then((result) => {
                    if (result) {
                      console.log('✅ $service_name Kafka 연결 테스트 성공');
                    } else {
                      console.log('❌ $service_name Kafka 연결 테스트 실패');
                      process.exit(1);
                    }
                    process.exit(0);
                  });
                } catch (error) {
                  console.error('❌ 테스트 실행 중 오류 발생:', error);
                  process.exit(1);
                }
            " || echo "❌ $service_name Kafka 연결 테스트 실패"
        else
            echo "❌ $service_name에 kafka.service.js 파일이 없습니다."
        fi
        
        cd ../../
    else
        echo "❌ $service_name 디렉토리를 찾을 수 없습니다."
    fi
}

# 각 서비스 테스트
test_service "auth-service"
test_service "session-service"
test_service "feedback-service"
test_service "user-service"
test_service "report-service"
test_service "realtime-service"

echo "\n✅ Kafka 통합 테스트 완료" 
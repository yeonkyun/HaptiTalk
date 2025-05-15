# 공유 Kafka 클라이언트

다양한 마이크로서비스에서 쉽게 사용할 수 있는 Kafka 클라이언트 라이브러리입니다.

## 기능

- 환경에 따른 자동 설정 (Docker/로컬)
- 프로듀서/컨슈머 지원
- 에러 처리 및 로깅
- 유연한 설정

## 사용 방법

### 설치

```bash
# 이 디렉토리를 각 마이크로서비스의 package.json에 추가
npm install --save ../shared/kafka-client
```

### 프로듀서 사용 예시

```javascript
const { createKafkaClient } = require('../../shared/kafka-client');
const logger = require('../utils/logger');

// 클라이언트 생성
const kafkaClient = createKafkaClient({
  clientId: 'user-service',
  logger
});

// 사용 예시
async function publishUserEvent(userId, eventType, data) {
  try {
    // 프로듀서 초기화
    await kafkaClient.initProducer();
    
    // 메시지 발행
    await kafkaClient.sendMessage(
      'haptitalk-user-events',
      { userId, eventType, data, timestamp: new Date().toISOString() },
      userId // 파티션 키로 userId 사용
    );
    
    return true;
  } catch (error) {
    logger.error('사용자 이벤트 발행 실패', { error });
    return false;
  }
}

// 서비스 종료 시 연결 종료
async function shutdown() {
  await kafkaClient.disconnect();
}
```

### 컨슈머 사용 예시

```javascript
const { createKafkaClient } = require('../../shared/kafka-client');
const logger = require('../utils/logger');

// 클라이언트 생성
const kafkaClient = createKafkaClient({
  clientId: 'notification-service',
  logger
});

// 메시지 핸들러
async function handleUserEvent({ topic, value, key }) {
  logger.info(`사용자 이벤트 수신: ${value.eventType}`, { userId: value.userId });
  
  // 이벤트 타입에 따른 처리
  switch(value.eventType) {
    case 'SIGNUP':
      await sendWelcomeNotification(value.userId);
      break;
    case 'PURCHASE':
      await sendPurchaseConfirmation(value.userId, value.data);
      break;
    // 추가 이벤트 처리...
  }
}

// 컨슈머 시작
async function startConsumer() {
  try {
    await kafkaClient.initConsumer(
      {
        groupId: 'notification-service-group',
        topics: ['haptitalk-user-events']
      },
      handleUserEvent
    );
    
    logger.info('Kafka 컨슈머 시작됨');
  } catch (error) {
    logger.error('Kafka 컨슈머 시작 실패', { error });
  }
}

// 시작
startConsumer();

// 서비스 종료 시 연결 종료
async function shutdown() {
  await kafkaClient.disconnect();
}
```

## Docker와 로컬 환경 간 전환

Docker Compose에서 실행 시 `KAFKA_BROKERS` 환경 변수를 `kafka:9092`로 설정합니다.
로컬 개발 환경에서는 `KAFKA_BROKERS`를 `localhost:9092`로 설정합니다.

### Docker Compose 설정 예시

```yaml
services:
  user-service:
    build:
      context: ./api/user-service
    environment:
      - SERVICE_NAME=user-service
      - KAFKA_BROKERS=kafka:9092
    # ...
```

### 로컬 테스트 실행

로컬에서 통합 테스트를 실행하려면 다음 스크립트를 사용합니다:

```bash
# 로컬 환경
KAFKA_BROKERS=localhost:9092 npx jest tests/integration/kafka.integration.test.js

# Docker 환경
DOCKER_ENV=true KAFKA_BROKERS=kafka:9092 npx jest tests/integration/kafka.integration.test.js
``` 
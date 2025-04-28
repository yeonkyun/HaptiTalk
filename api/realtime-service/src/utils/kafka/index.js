/**
 * Kafka 클라이언트 유틸리티
 * 
 * 이 모듈은 Kafka 브로커와의 연결 및 메시지 생산/소비를 관리합니다.
 */
const { Kafka } = require('kafkajs');
const logger = require('../logger');

// 환경 변수에서 Kafka 설정 로드
const brokers = (process.env.KAFKA_BROKERS || 'localhost:9092').split(',');
const clientId = process.env.SERVICE_NAME || 'realtime-service';

// Kafka 인스턴스 생성
const kafka = new Kafka({
  clientId,
  brokers,
  retry: {
    initialRetryTime: 100,
    retries: 8
  }
});

// 프로듀서 인스턴스
let producer = null;

// 컨슈머 인스턴스 맵
const consumers = new Map();

/**
 * Kafka 프로듀서 초기화
 */
const initProducer = async () => {
  try {
    logger.info('Kafka 프로듀서 초기화 중...', { component: 'kafka' });
    producer = kafka.producer();
    await producer.connect();
    logger.info('Kafka 프로듀서 초기화 완료', { component: 'kafka' });
    return producer;
  } catch (error) {
    logger.error('Kafka 프로듀서 초기화 실패', {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    throw error;
  }
};

/**
 * Kafka 컨슈머 초기화
 * @param {string} groupId 컨슈머 그룹 ID
 * @param {string[]} topics 구독할 토픽 배열
 * @param {Function} messageHandler 메시지 처리 콜백 함수
 * @param {Object} options 추가 옵션
 */
const initConsumer = async (groupId, topics, messageHandler, options = {}) => {
  if (consumers.has(groupId)) {
    logger.warn(`컨슈머 그룹 ${groupId}가 이미 존재합니다`, { component: 'kafka' });
    return consumers.get(groupId);
  }

  try {
    logger.info(`Kafka 컨슈머 초기화 중... (그룹: ${groupId})`, { component: 'kafka', topics });
    
    // 컨슈머 설정
    const consumerConfig = {
      groupId,
      sessionTimeout: 30000,
      heartbeatInterval: 10000,
      ...options
    };
    
    const consumer = kafka.consumer(consumerConfig);
    await consumer.connect();
    
    // 토픽 구독
    for (const topic of topics) {
      await consumer.subscribe({ topic, fromBeginning: options.fromBeginning || false });
    }
    
    // 메시지 처리 설정
    await consumer.run({
      partitionsConsumedConcurrently: options.concurrency || 1,
      eachMessage: async ({ topic, partition, message, heartbeat, pause }) => {
        try {
          // 메시지 파싱
          const value = message.value ? JSON.parse(message.value.toString()) : null;
          const key = message.key ? message.key.toString() : null;
          
          // 메시지 로깅 (민감 정보는 제외)
          logger.debug(`Kafka 메시지 수신: ${topic}`, {
            topic,
            partition,
            key,
            offset: message.offset,
            timestamp: message.timestamp,
            component: 'kafka'
          });
          
          // 메시지 핸들러 호출
          await messageHandler({ topic, key, value, headers: message.headers, partition, offset: message.offset });
        } catch (error) {
          logger.error(`Kafka 메시지 처리 오류: ${topic}`, {
            error: error.message,
            stack: error.stack,
            topic,
            component: 'kafka'
          });
        }
      }
    });
    
    // 컨슈머 맵에 저장
    consumers.set(groupId, consumer);
    
    logger.info(`Kafka 컨슈머 초기화 완료 (그룹: ${groupId})`, { component: 'kafka', topics });
    return consumer;
  } catch (error) {
    logger.error(`Kafka 컨슈머 초기화 실패 (그룹: ${groupId})`, {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    throw error;
  }
};

/**
 * 메시지 전송
 * @param {string} topic 토픽
 * @param {Object} message 전송할 메시지 객체
 * @param {string} key 메시지 키 (파티션 결정에 사용)
 * @param {Object} headers 메시지 헤더
 */
const sendMessage = async (topic, message, key = null, headers = {}) => {
  if (!producer) {
    throw new Error('Kafka 프로듀서가 초기화되지 않았습니다');
  }
  
  try {
    const messageValue = JSON.stringify(message);
    
    const record = {
      topic,
      messages: [
        {
          value: messageValue,
          headers
        }
      ]
    };
    
    if (key) {
      record.messages[0].key = key;
    }
    
    logger.debug(`Kafka 메시지 전송: ${topic}`, {
      topic,
      key,
      component: 'kafka'
    });
    
    await producer.send(record);
    return true;
  } catch (error) {
    logger.error(`Kafka 메시지 전송 실패: ${topic}`, {
      error: error.message,
      stack: error.stack,
      topic,
      component: 'kafka'
    });
    throw error;
  }
};

/**
 * 특정 컨슈머 중지
 * @param {string} groupId 중지할 컨슈머 그룹 ID
 */
const stopConsumer = async (groupId) => {
  if (!consumers.has(groupId)) {
    logger.warn(`컨슈머 그룹 ${groupId}가 존재하지 않습니다`, { component: 'kafka' });
    return false;
  }
  
  try {
    const consumer = consumers.get(groupId);
    await consumer.disconnect();
    consumers.delete(groupId);
    logger.info(`Kafka 컨슈머 중지 완료 (그룹: ${groupId})`, { component: 'kafka' });
    return true;
  } catch (error) {
    logger.error(`Kafka 컨슈머 중지 실패 (그룹: ${groupId})`, {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    throw error;
  }
};

/**
 * 모든 Kafka 연결 종료
 */
const disconnect = async () => {
  try {
    // 모든 컨슈머 종료
    const consumerGroupIds = Array.from(consumers.keys());
    for (const groupId of consumerGroupIds) {
      await stopConsumer(groupId);
    }
    
    // 프로듀서 종료
    if (producer) {
      await producer.disconnect();
      producer = null;
      logger.info('Kafka 프로듀서 연결 종료', { component: 'kafka' });
    }
    
    logger.info('모든 Kafka 연결이 종료되었습니다', { component: 'kafka' });
    return true;
  } catch (error) {
    logger.error('Kafka 연결 종료 실패', {
      error: error.message,
      stack: error.stack,
      component: 'kafka'
    });
    throw error;
  }
};

module.exports = {
  initProducer,
  initConsumer,
  sendMessage,
  stopConsumer,
  disconnect,
  kafka
};
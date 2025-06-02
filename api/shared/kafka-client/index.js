/**
 * HaptiTalk 공유 Kafka 클라이언트
 * 
 * 모든 마이크로서비스에서 재사용할 수 있는 Kafka 클라이언트입니다.
 * 환경 변수를 통해 설정할 수 있으며, Docker와 로컬 환경 모두 지원합니다.
 */
const { Kafka } = require('kafkajs');

/**
 * Kafka 클라이언트 생성자
 * @param {Object} options 설정 옵션
 * @param {string} options.clientId 클라이언트 ID
 * @param {string|string[]} options.brokers Kafka 브로커 주소들
 * @param {Object} options.logger 로거 인스턴스
 * @param {Object} options.ssl SSL 설정
 * @param {Object} options.retry 재시도 설정
 * @returns {Object} Kafka 클라이언트 인스턴스
 */
function createKafkaClient({
  clientId = process.env.SERVICE_NAME || 'microservice', 
  brokers = (process.env.KAFKA_BROKERS || 'localhost:9092').split(','),
  logger,
  ssl = undefined,
  retry = { initialRetryTime: 100, retries: 8 }
}) {
  // 환경 확인 로깅
  if (logger) {
    logger.info(`Kafka 설정: clientId=${clientId}, brokers=${brokers.join(',')}`, { component: 'kafka-client' });
  }

  // Kafka 인스턴스 생성
  const kafka = new Kafka({ clientId, brokers, ssl, retry });
  
  // 상태 변수
  let producer = null;
  let consumer = null;
  
  /**
   * 프로듀서 초기화
   * @returns {Object} 프로듀서 인스턴스
   */
  const initProducer = async () => {
    try {
      if (logger) logger.info('Kafka 프로듀서 초기화 중...', { component: 'kafka-client' });
      producer = kafka.producer();
      await producer.connect();
      if (logger) logger.info('Kafka 프로듀서 초기화 완료', { component: 'kafka-client' });
      return producer;
    } catch (error) {
      if (logger) {
        logger.error('Kafka 프로듀서 초기화 실패', {
          error: error.message,
          stack: error.stack,
          component: 'kafka-client'
        });
      }
      throw error;
    }
  };
  
  /**
   * 메시지 전송
   * @param {string} topic 토픽
   * @param {Object} message 메시지 객체
   * @param {string} key 메시지 키
   * @param {Object} headers 메시지 헤더
   * @returns {boolean} 성공 여부
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
      
      if (logger) {
        logger.debug(`Kafka 메시지 전송: ${topic}`, {
          topic,
          key,
          component: 'kafka-client'
        });
      }
      
      await producer.send(record);
      return true;
    } catch (error) {
      if (logger) {
        logger.error(`Kafka 메시지 전송 실패: ${topic}`, {
          error: error.message,
          stack: error.stack,
          topic,
          component: 'kafka-client'
        });
      }
      throw error;
    }
  };
  
  /**
   * 컨슈머 초기화 및 구독
   * @param {Object} options 컨슈머 옵션
   * @param {string} options.groupId 컨슈머 그룹 ID
   * @param {string[]} options.topics 구독할 토픽들
   * @param {function} onMessage 메시지 처리 콜백
   * @returns {Object} 컨슈머 인스턴스
   */
  const initConsumer = async ({ groupId, topics }, onMessage) => {
    try {
      if (logger) logger.info(`Kafka 컨슈머 초기화 중 (${groupId})...`, { component: 'kafka-client' });
      consumer = kafka.consumer({ groupId });
      await consumer.connect();
      
      // 토픽 구독
      for (const topic of topics) {
        await consumer.subscribe({ topic, fromBeginning: false });
      }
      
      // 메시지 처리 시작
      await consumer.run({
        eachMessage: async ({ topic, partition, message }) => {
          try {
            if (logger) {
              logger.debug(`메시지 수신: ${topic}`, { 
                topic, 
                partition,
                component: 'kafka-client'
              });
            }
            
            // 메시지 파싱
            const value = message.value ? JSON.parse(message.value.toString()) : null;
            const key = message.key ? message.key.toString() : null;
            
            // 콜백 호출
            if (onMessage) {
              await onMessage({ topic, value, key, headers: message.headers, partition });
            }
          } catch (error) {
            if (logger) {
              logger.error(`메시지 처리 실패: ${topic}`, {
                error: error.message,
                stack: error.stack,
                topic,
                component: 'kafka-client'
              });
            }
          }
        }
      });
      
      if (logger) logger.info(`Kafka 컨슈머 초기화 완료 (${groupId})`, { component: 'kafka-client' });
      return consumer;
    } catch (error) {
      if (logger) {
        logger.error(`Kafka 컨슈머 초기화 실패 (${groupId})`, {
          error: error.message,
          stack: error.stack,
          component: 'kafka-client'
        });
      }
      throw error;
    }
  };
  
  /**
   * 모든 연결 종료
   */
  const disconnect = async () => {
    try {
      if (producer) {
        await producer.disconnect();
        producer = null;
        if (logger) logger.info('Kafka 프로듀서 연결 종료', { component: 'kafka-client' });
      }
      
      if (consumer) {
        await consumer.disconnect();
        consumer = null;
        if (logger) logger.info('Kafka 컨슈머 연결 종료', { component: 'kafka-client' });
      }
      
      if (logger) logger.info('Kafka 연결 종료 완료', { component: 'kafka-client' });
      return true;
    } catch (error) {
      if (logger) {
        logger.error('Kafka 연결 종료 실패', {
          error: error.message,
          stack: error.stack,
          component: 'kafka-client'
        });
      }
      throw error;
    }
  };
  
  // 인터페이스 반환
  return {
    kafka,
    initProducer,
    sendMessage,
    initConsumer,
    disconnect
  };
}

module.exports = { createKafkaClient }; 
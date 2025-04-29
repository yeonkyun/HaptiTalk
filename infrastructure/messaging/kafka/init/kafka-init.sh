#!/bin/bash
# kafka-init.sh

# 스크립트가 에러 발생시 즉시 종료하도록 설정
set -e

# Kafka가 준비될 때까지 대기
echo "Waiting for Kafka to be ready..."
kafka-topics.sh --bootstrap-server kafka:9092 --list > /dev/null 2>&1
status=$?
attempt_counter=0
max_attempts=30

while [ $status -ne 0 ] && [ $attempt_counter -lt $max_attempts ]; do
  sleep 5
  attempt_counter=$(($attempt_counter+1))
  echo "Waiting for Kafka (attempt: $attempt_counter)..."
  kafka-topics.sh --bootstrap-server kafka:9092 --list > /dev/null 2>&1
  status=$?
done

if [ $status -ne 0 ]; then
  echo "Error: Failed to connect to Kafka after $max_attempts attempts!"
  exit 1
fi

echo "Kafka is ready! Creating topics..."

# 기본 토픽 생성
echo "Creating session events topic..."
kafka-topics.sh --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic ${KAFKA_TOPIC_SESSION_EVENTS} \
  --partitions 3 \
  --replication-factor 1 \
  --config retention.ms=604800000 \
  --config segment.bytes=1073741824

echo "Creating analysis results topic..."
kafka-topics.sh --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic ${KAFKA_TOPIC_ANALYSIS_RESULTS} \
  --partitions 3 \
  --replication-factor 1 \
  --config retention.ms=604800000 \
  --config segment.bytes=1073741824

echo "Creating feedback commands topic..."
kafka-topics.sh --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic ${KAFKA_TOPIC_FEEDBACK_COMMANDS} \
  --partitions 3 \
  --replication-factor 1 \
  --config retention.ms=259200000 \
  --config segment.bytes=1073741824

echo "Creating user activity topic..."
kafka-topics.sh --bootstrap-server kafka:9092 --create --if-not-exists \
  --topic ${KAFKA_TOPIC_USER_ACTIVITY} \
  --partitions 3 \
  --replication-factor 1 \
  --config retention.ms=2592000000 \
  --config segment.bytes=1073741824

echo "All topics created successfully!"
echo "Listing all topics:"
kafka-topics.sh --bootstrap-server kafka:9092 --list

echo "Kafka initialization completed successfully!"
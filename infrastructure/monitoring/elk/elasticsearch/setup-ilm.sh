#!/bin/sh

# ILM 정책 생성을 위한 스크립트

# Elasticsearch 연결 정보
ES_HOST="elasticsearch:9200"
ES_USER="${ELASTIC_USERNAME:-}"
ES_PASS="${ELASTIC_PASSWORD:-}"

AUTH=""
if [ -n "$ES_USER" ] && [ -n "$ES_PASS" ]; then
  AUTH="-u $ES_USER:$ES_PASS"
fi

echo "Elasticsearch ILM 정책 설정을 시작합니다..."

# Elasticsearch가 준비될 때까지 대기
echo "Elasticsearch 연결 확인 중..."
until $(curl --output /dev/null --silent --head --fail $AUTH http://$ES_HOST); do
  echo "Elasticsearch 준비 대기 중..."
  sleep 5
done
echo "Elasticsearch 사용 가능"

# ILM 정책 생성: 개발 환경용 짧은 보관 정책 (2일 후 삭제)
echo "개발 환경용 ILM 정책 생성 중 (2일 보관)..."
curl -X PUT $AUTH "http://$ES_HOST/_ilm/policy/logs-dev-policy" -H 'Content-Type: application/json' -d'
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_age": "1d",
            "max_size": "1gb"
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "delete": {
        "min_age": "2d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'

# filebeat 인덱스 템플릿에 ILM 정책 연결
echo "filebeat 인덱스 템플릿에 ILM 정책 연결 중..."
curl -X PUT $AUTH "http://$ES_HOST/_template/filebeat" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["filebeat-*"],
  "settings": {
    "index.lifecycle.name": "logs-dev-policy",
    "index.lifecycle.rollover_alias": "filebeat"
  }
}'

# logstash 인덱스 템플릿에 ILM 정책 연결
echo "logstash 인덱스 템플릿에 ILM 정책 연결 중..."
curl -X PUT $AUTH "http://$ES_HOST/_template/logstash" -H 'Content-Type: application/json' -d'
{
  "index_patterns": ["logstash-*"],
  "settings": {
    "index.lifecycle.name": "logs-dev-policy",
    "index.lifecycle.rollover_alias": "logstash"
  }
}'

# 오래된 인덱스 강제 삭제 (7일 이상)
echo "7일 이상 된 인덱스 삭제 중..."
curl -X POST $AUTH "http://$ES_HOST/_delete_by_query" -H 'Content-Type: application/json' -d'
{
  "query": {
    "range": {
      "@timestamp": {
        "lt": "now-7d/d"
      }
    }
  }
}'

echo "Elasticsearch ILM 정책 설정이 완료되었습니다." 
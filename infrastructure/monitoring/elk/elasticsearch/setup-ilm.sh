#!/bin/bash

# Elasticsearch가 응답할 때까지 대기
wait_for_elasticsearch() {
  echo "Elasticsearch가 준비될 때까지 대기 중..."
  until $(curl --output /dev/null --silent --head --fail http://elasticsearch:9200); do
    printf '.'
    sleep 5
  done
  echo "Elasticsearch 준비 완료"
}

# ILM 정책 생성
create_ilm_policy() {
  echo "ILM 정책 생성 중..."
  curl -X PUT "http://elasticsearch:9200/_ilm/policy/logs-lifecycle-policy" -H 'Content-Type: application/json' -d @/usr/share/elasticsearch/lifecycle-policy.json
  echo
}

# 인덱스 템플릿 생성
create_index_template() {
  echo "인덱스 템플릿 생성 중..."
  curl -X PUT "http://elasticsearch:9200/_template/logs-template" -H 'Content-Type: application/json' -d '{
    "index_patterns": ["haptitalk-logs-*"],
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0,
      "index.lifecycle.name": "logs-lifecycle-policy",
      "index.lifecycle.rollover_alias": "haptitalk-logs"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "service": { "type": "keyword" },
        "log_level": { "type": "keyword" },
        "log_message": { "type": "text" },
        "tags": { "type": "keyword" }
      }
    }
  }'
  echo
}

# 초기 인덱스 생성
create_initial_index() {
  echo "초기 인덱스 생성 중..."
  curl -X PUT "http://elasticsearch:9200/haptitalk-logs-000001" -H 'Content-Type: application/json' -d '{
    "aliases": {
      "haptitalk-logs": {
        "is_write_index": true
      }
    }
  }'
  echo
}

# 메인 실행
main() {
  wait_for_elasticsearch
  create_ilm_policy
  create_index_template
  create_initial_index
  echo "로그 인덱스 설정이 완료되었습니다."
}

main 
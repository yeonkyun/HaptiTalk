#!/bin/bash

# ILM 정책 생성을 위한 스크립트

# Elasticsearch 연결 정보
ES_HOST="elasticsearch:9200"
ES_USER="${ELASTIC_USERNAME:-elastic}"
ES_PASS="${ELASTIC_PASSWORD:-changeme}"

# 스크립트 시작
echo "Elasticsearch ILM 정책 설정을 시작합니다..."

# Elasticsearch가 준비될 때까지 대기
echo "Elasticsearch 연결 확인 중..."
until curl -s -u "$ES_USER:$ES_PASS" "http://$ES_HOST/_cluster/health?wait_for_status=yellow" > /dev/null; do
    echo "Elasticsearch 준비 대기 중..."
    sleep 5
done
echo "Elasticsearch 사용 가능"

# ILM 정책 생성
echo "로그 ILM 정책 생성 중..."
curl -X PUT -s -u "$ES_USER:$ES_PASS" "http://$ES_HOST/_ilm/policy/logs-policy" -H 'Content-Type: application/json' -d '
{
  "policy": {
    "phases": {
      "hot": {
        "min_age": "0ms",
        "actions": {
          "rollover": {
            "max_size": "10gb",
            "max_age": "7d",
            "max_docs": 50000000
          },
          "set_priority": {
            "priority": 100
          }
        }
      },
      "warm": {
        "min_age": "30d",
        "actions": {
          "shrink": {
            "number_of_shards": 1
          },
          "forcemerge": {
            "max_num_segments": 1
          },
          "set_priority": {
            "priority": 50
          }
        }
      },
      "cold": {
        "min_age": "60d",
        "actions": {
          "set_priority": {
            "priority": 0
          },
          "freeze": {}
        }
      },
      "delete": {
        "min_age": "90d",
        "actions": {
          "delete": {}
        }
      }
    }
  }
}'

echo "인덱스 템플릿 생성 중..."
curl -X PUT -s -u "$ES_USER:$ES_PASS" "http://$ES_HOST/_index_template/logs-template" -H 'Content-Type: application/json' -d '
{
  "index_patterns": ["logs-*"],
  "template": {
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 1,
      "index.lifecycle.name": "logs-policy",
      "index.lifecycle.rollover_alias": "logs"
    },
    "mappings": {
      "properties": {
        "@timestamp": { "type": "date" },
        "timestamp": { "type": "date" },
        "message": { "type": "text" },
        "service": { "type": "keyword" },
        "level": { "type": "keyword" },
        "host": { "type": "keyword" }
      }
    }
  }
}'

# 초기 인덱스 생성
echo "초기 인덱스 생성 중..."
curl -X PUT -s -u "$ES_USER:$ES_PASS" "http://$ES_HOST/logs-000001" -H 'Content-Type: application/json' -d '
{
  "aliases": {
    "logs": {
      "is_write_index": true
    }
  }
}'

echo "ILM 정책 및 템플릿 설정이 완료되었습니다." 
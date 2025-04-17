#!/bin/bash

# Kibana가 응답할 때까지 대기
wait_for_kibana() {
  echo "Kibana가 준비될 때까지 대기 중..."
  until $(curl --output /dev/null --silent --head --fail http://kibana:5601/api/status); do
    printf '.'
    sleep 5
  done
  echo "Kibana 준비 완료"
}

# Kibana 대시보드 가져오기
import_dashboards() {
  echo "대시보드 가져오기 중..."
  curl -X POST "http://kibana:5601/api/saved_objects/_import" \
    -H "kbn-xsrf: true" \
    --form file=@/usr/share/kibana/dashboards/logs-dashboard.ndjson
  echo
}

# 메인 실행
main() {
  wait_for_kibana
  import_dashboards
  echo "대시보드 설정이 완료되었습니다."
}

main 
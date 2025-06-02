#!/bin/bash
set -e

# 라즈베리파이 포트 충돌 해결 스크립트
echo "===== HaptiTalk 포트 충돌 해결 스크립트 ====="
echo "실행 시간: $(date)"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 로그 함수
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 작업 디렉토리 설정
HAPTITALK_DIR="/home/${USER}/haptitalk"
cd "$HAPTITALK_DIR"

log_info "작업 디렉토리: $HAPTITALK_DIR"

# 1. 현재 포트 사용 상황 확인
log_info "==== 1단계: 포트 사용 상황 확인 ===="

CONFLICT_PORTS=(4317 4318 4319 4320 8889 55679)
CONFLICTED_PORTS=()

for port in "${CONFLICT_PORTS[@]}"; do
    if netstat -tulpn 2>/dev/null | grep -q ":$port "; then
        PROCESS_INFO=$(netstat -tulpn 2>/dev/null | grep ":$port " | head -1)
        log_warn "포트 $port 이미 사용 중: $PROCESS_INFO"
        CONFLICTED_PORTS+=($port)
    else
        log_info "포트 $port 사용 가능"
    fi
done

# 2. Docker 컨테이너 상태 확인
log_info "==== 2단계: Docker 컨테이너 상태 확인 ===="

# HaptiTalk 관련 컨테이너 중지
log_info "HaptiTalk 관련 컨테이너 중지 중..."
docker-compose -f docker-compose.prod.yml stop otel-collector jaeger || log_warn "일부 컨테이너 중지 실패"

# 중지된 컨테이너 제거
log_info "중지된 컨테이너 제거 중..."
docker-compose -f docker-compose.prod.yml rm -f otel-collector jaeger || log_warn "일부 컨테이너 제거 실패"

# 3. 포트를 사용하는 다른 프로세스 확인 및 정리
log_info "==== 3단계: 포트 사용 프로세스 정리 ===="

for port in "${CONFLICTED_PORTS[@]}"; do
    log_info "포트 $port 사용 프로세스 확인 중..."
    
    # 프로세스 ID 찾기
    PIDS=$(lsof -ti:$port 2>/dev/null || true)
    
    if [[ -n "$PIDS" ]]; then
        for pid in $PIDS; do
            PROCESS_NAME=$(ps -p $pid -o comm= 2>/dev/null || echo "Unknown")
            PROCESS_CMD=$(ps -p $pid -o args= 2>/dev/null || echo "Unknown")
            
            log_warn "포트 $port에서 실행 중인 프로세스: PID=$pid, NAME=$PROCESS_NAME"
            log_info "명령어: $PROCESS_CMD"
            
            # Docker 컨테이너인지 확인
            if echo "$PROCESS_CMD" | grep -q "docker\|containerd"; then
                log_info "Docker 관련 프로세스 감지, 컨테이너 정리 진행..."
                
                # 관련 컨테이너 찾아서 중지
                CONTAINERS=$(docker ps --format "{{.Names}}" | grep -E "(otel|jaeger|telemetry)" || true)
                if [[ -n "$CONTAINERS" ]]; then
                    log_info "관련 컨테이너 중지: $CONTAINERS"
                    echo "$CONTAINERS" | xargs -r docker stop
                    echo "$CONTAINERS" | xargs -r docker rm -f
                fi
            else
                # 일반 프로세스인 경우 사용자에게 확인
                read -p "포트 $port를 사용하는 프로세스 $PROCESS_NAME (PID: $pid)을 종료하시겠습니까? [y/N]: " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    log_info "프로세스 $pid 종료 중..."
                    kill -TERM $pid 2>/dev/null || kill -KILL $pid 2>/dev/null || log_error "프로세스 종료 실패"
                    sleep 2
                else
                    log_warn "프로세스를 종료하지 않았습니다. 포트 충돌이 계속될 수 있습니다."
                fi
            fi
        done
    else
        log_success "포트 $port는 현재 사용 중이지 않습니다."
    fi
done

# 4. Docker 네트워크 정리
log_info "==== 4단계: Docker 네트워크 정리 ===="

log_info "사용하지 않는 Docker 리소스 정리 중..."
docker system prune -f --volumes || log_warn "Docker 시스템 정리 중 오류 발생"

# 네트워크 재생성
log_info "HaptiTalk 네트워크 재생성 중..."
docker network rm haptitalk_network 2>/dev/null || log_info "기존 네트워크가 없거나 제거 실패"
docker network create haptitalk_network || log_warn "네트워크 생성 실패"

# 5. 환경 변수 확인 및 수정
log_info "==== 5단계: 환경 변수 확인 ===="

if [[ -f ".env" ]]; then
    log_info ".env 파일에서 포트 설정 확인 중..."
    
    # OTEL Collector 포트 설정 확인
    if ! grep -q "OTEL_COLLECTOR_HTTP_PORT" .env; then
        log_info "OTEL_COLLECTOR_HTTP_PORT 환경 변수 추가 중..."
        echo "OTEL_COLLECTOR_HTTP_PORT=4319" >> .env
    fi
    
    if ! grep -q "OTEL_COLLECTOR_PORT" .env; then
        log_info "OTEL_COLLECTOR_PORT 환경 변수 추가 중..."
        echo "OTEL_COLLECTOR_PORT=4320" >> .env  # gRPC 포트는 4320으로 변경
    fi
    
    if ! grep -q "OTEL_COLLECTOR_PROM_PORT" .env; then
        log_info "OTEL_COLLECTOR_PROM_PORT 환경 변수 추가 중..."
        echo "OTEL_COLLECTOR_PROM_PORT=8889" >> .env
    fi
    
    if ! grep -q "OTEL_COLLECTOR_ZPAGES_PORT" .env; then
        log_info "OTEL_COLLECTOR_ZPAGES_PORT 환경 변수 추가 중..."
        echo "OTEL_COLLECTOR_ZPAGES_PORT=55679" >> .env
    fi
    
    log_success "환경 변수 설정 완료"
else
    log_error ".env 파일이 없습니다!"
    exit 1
fi

# 6. 포트 충돌 해결 후 재확인
log_info "==== 6단계: 포트 충돌 해결 후 재확인 ===="

sleep 5  # 프로세스 종료 대기

for port in "${CONFLICT_PORTS[@]}"; do
    if netstat -tulpn 2>/dev/null | grep -q ":$port "; then
        PROCESS_INFO=$(netstat -tulpn 2>/dev/null | grep ":$port " | head -1)
        log_error "포트 $port 여전히 사용 중: $PROCESS_INFO"
    else
        log_success "포트 $port 사용 가능"
    fi
done

# 7. OTEL Collector와 Jaeger 개별 시작
log_info "==== 7단계: OTEL Collector와 Jaeger 개별 시작 ===="

# 환경 변수 로드
source .env

log_info "Jaeger 먼저 시작..."
docker-compose -f docker-compose.prod.yml up -d jaeger

log_info "Jaeger 시작 대기 (30초)..."
sleep 30

# Jaeger 상태 확인
if curl -f http://localhost:16686 >/dev/null 2>&1; then
    log_success "Jaeger가 성공적으로 시작되었습니다."
else
    log_warn "Jaeger가 아직 준비되지 않았을 수 있습니다."
fi

log_info "OTEL Collector 시작..."
docker-compose -f docker-compose.prod.yml up -d otel-collector

log_info "OTEL Collector 시작 대기 (20초)..."
sleep 20

# 8. 최종 상태 확인
log_info "==== 8단계: 최종 상태 확인 ===="

log_info "컨테이너 상태:"
docker-compose -f docker-compose.prod.yml ps jaeger otel-collector

log_info "포트 사용 상황:"
for port in "${CONFLICT_PORTS[@]}"; do
    if netstat -tulpn 2>/dev/null | grep -q ":$port "; then
        PROCESS_INFO=$(netstat -tulpn 2>/dev/null | grep ":$port " | head -1)
        log_info "포트 $port: $PROCESS_INFO"
    else
        log_warn "포트 $port: 사용되지 않음"
    fi
done

# 9. 헬스체크
log_info "==== 9단계: 헬스체크 ===="

# OTEL Collector 헬스체크
if curl -f http://localhost:55679/debug/servicez >/dev/null 2>&1; then
    log_success "OTEL Collector 헬스체크 통과"
else
    log_warn "OTEL Collector 헬스체크 실패"
fi

# Jaeger 헬스체크
if curl -f http://localhost:16686 >/dev/null 2>&1; then
    log_success "Jaeger 헬스체크 통과"
else
    log_warn "Jaeger 헬스체크 실패"
fi

log_success "===== 포트 충돌 해결 완료 ====="
echo "결과 요약:"
echo "- 충돌된 포트들이 정리되었습니다."
echo "- OTEL Collector와 Jaeger가 다시 시작되었습니다."
echo "- 필요한 경우 전체 스택을 다시 시작하세요: docker-compose -f docker-compose.prod.yml up -d"
echo ""
echo "문제가 지속되면 다음 명령어로 전체 재시작을 시도하세요:"
echo "docker-compose -f docker-compose.prod.yml down --remove-orphans"
echo "docker-compose -f docker-compose.prod.yml up -d" 
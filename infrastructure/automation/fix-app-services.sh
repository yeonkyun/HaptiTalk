#!/bin/bash
set -e

# 라즈베리파이 애플리케이션 서비스 복구 스크립트
echo "===== HaptiTalk 애플리케이션 서비스 복구 스크립트 ====="
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

# 1. 현재 상태 확인
log_info "==== 1단계: 현재 상태 확인 ===="

if [ ! -f "docker-compose.prod.yml" ]; then
    log_error "docker-compose.prod.yml 파일이 없습니다!"
    exit 1
fi

if [ ! -f ".env" ]; then
    log_error ".env 파일이 없습니다!"
    exit 1
fi

# 환경 변수 로드
source .env

log_info "환경 변수 로드 완료"
log_info "POSTGRES_USER: ${POSTGRES_USER:+설정됨}"
log_info "REDIS_PASSWORD: ${REDIS_PASSWORD:+설정됨}"

# 2. 인프라 서비스 상태 확인
log_info "==== 2단계: 인프라 서비스 상태 확인 ===="

INFRA_SERVICES=("postgres" "redis" "mongodb" "kafka" "kong")
FAILED_INFRA=()

for service in "${INFRA_SERVICES[@]}"; do
    if docker-compose -f docker-compose.prod.yml ps "$service" | grep -q "Up"; then
        log_success "$service: 정상 실행 중"
    else
        log_warn "$service: 실행 중이 아님"
        FAILED_INFRA+=("$service")
    fi
done

# 인프라 서비스가 실패한 경우 먼저 복구
if [ ${#FAILED_INFRA[@]} -gt 0 ]; then
    log_warn "실패한 인프라 서비스: ${FAILED_INFRA[*]}"
    log_info "인프라 서비스를 먼저 복구합니다..."
    
    for service in "${FAILED_INFRA[@]}"; do
        log_info "$service 재시작 중..."
        docker-compose -f docker-compose.prod.yml stop "$service" || true
        docker-compose -f docker-compose.prod.yml rm -f "$service" || true
        docker-compose -f docker-compose.prod.yml up -d "$service"
        sleep 10
    done
    
    log_info "인프라 서비스 복구 대기 중 (30초)..."
    sleep 30
fi

# 3. GitHub Container Registry 로그인
log_info "==== 3단계: GitHub Container Registry 인증 ===="

if [ -n "${GHCR_PAT:-}" ]; then
    echo "$GHCR_PAT" | docker login ghcr.io -u "${GITHUB_REPOSITORY_OWNER:-}" --password-stdin
    log_success "GitHub Container Registry 로그인 성공"
else
    log_warn "GHCR_PAT 환경 변수가 설정되지 않았습니다. 공개 이미지만 사용합니다."
fi

# 4. 애플리케이션 서비스 개별 복구
log_info "==== 4단계: 애플리케이션 서비스 개별 복구 ===="

APP_SERVICES=("auth-service" "session-service" "user-service" "feedback-service" "report-service" "realtime-service")
SUCCESSFUL_SERVICES=()
FAILED_SERVICES=()

for service in "${APP_SERVICES[@]}"; do
    log_info "=== $service 복구 시작 ==="
    
    # 기존 컨테이너 정리
    log_info "$service 기존 컨테이너 정리 중..."
    docker-compose -f docker-compose.prod.yml stop "$service" 2>/dev/null || true
    docker-compose -f docker-compose.prod.yml rm -f "$service" 2>/dev/null || true
    
    # 이미지 pull 시도
    IMAGE_NAME="ghcr.io/${GITHUB_REPOSITORY_OWNER:-}/haptitalk-${service}:${IMAGE_TAG:-latest}"
    log_info "$service 이미지 pull 시도: $IMAGE_NAME"
    
    if docker pull "$IMAGE_NAME" 2>/dev/null; then
        log_success "$service 이미지 pull 성공"
    else
        log_warn "$service 이미지 pull 실패, 기존 이미지 사용"
    fi
    
    # 서비스 시작
    log_info "$service 시작 중..."
    if docker-compose -f docker-compose.prod.yml up -d "$service"; then
        log_success "$service 시작 성공"
        SUCCESSFUL_SERVICES+=("$service")
        
        # 잠시 대기 후 상태 확인
        sleep 10
        
        if docker-compose -f docker-compose.prod.yml ps "$service" | grep -q "Up"; then
            log_success "$service 정상 실행 중"
        else
            log_warn "$service 시작했지만 상태 불안정"
            
            # 로그 확인
            echo "=== $service 로그 ==="
            docker-compose -f docker-compose.prod.yml logs --tail=20 "$service" || echo "로그 확인 실패"
        fi
    else
        log_error "$service 시작 실패"
        FAILED_SERVICES+=("$service")
        
        # 실패 로그 확인
        echo "=== $service 실패 로그 ==="
        docker-compose -f docker-compose.prod.yml logs --tail=20 "$service" || echo "로그 확인 실패"
    fi
    
    echo "" # 빈 줄로 구분
done

# 5. 결과 요약
log_info "==== 5단계: 복구 결과 요약 ===="

log_info "성공한 서비스 (${#SUCCESSFUL_SERVICES[@]}개): ${SUCCESSFUL_SERVICES[*]}"
log_error "실패한 서비스 (${#FAILED_SERVICES[@]}개): ${FAILED_SERVICES[*]}"

# 6. 최종 상태 확인
log_info "==== 6단계: 최종 상태 확인 ===="

echo "=== 전체 컨테이너 상태 ==="
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "=== 실행 중인 컨테이너 ==="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# 7. 헬스체크
log_info "==== 7단계: 헬스체크 ===="

for service in "${SUCCESSFUL_SERVICES[@]}"; do
    # 기본 포트 설정
    case $service in
        "auth-service") PORT="${AUTH_SERVICE_PORT:-3000}" ;;
        "session-service") PORT="${SESSION_SERVICE_PORT:-3002}" ;;
        "user-service") PORT="${USER_SERVICE_PORT:-3004}" ;;
        "feedback-service") PORT="${FEEDBACK_SERVICE_PORT:-3003}" ;;
        "report-service") PORT="${REPORT_SERVICE_PORT:-3005}" ;;
        "realtime-service") PORT="${REALTIME_SERVICE_PORT:-3001}" ;;
        *) PORT="3000" ;;
    esac
    
    # 헬스체크 시도 (5초 타임아웃)
    if timeout 5 curl -f "http://localhost:$PORT/health" >/dev/null 2>&1; then
        log_success "$service 헬스체크 통과 (포트 $PORT)"
    else
        log_warn "$service 헬스체크 실패 (포트 $PORT)"
    fi
done

log_success "===== 애플리케이션 서비스 복구 완료 ====="
echo ""
echo "결과 요약:"
echo "- 성공한 서비스: ${SUCCESSFUL_SERVICES[*]}"
echo "- 실패한 서비스: ${FAILED_SERVICES[*]}"
echo ""
echo "필요한 경우 다음 명령어로 전체 재시작:"
echo "docker-compose -f docker-compose.prod.yml down --remove-orphans"
echo "docker-compose -f docker-compose.prod.yml up -d" 
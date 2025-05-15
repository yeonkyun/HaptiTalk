# HaptiTalk Resilience Framework

## 개요

HaptiTalk 마이크로서비스 아키텍처의 회복성(Resilience)을 강화하기 위한 종합 프레임워크입니다. 이 프레임워크는 다음의 패턴을 구현합니다:

- Circuit Breaker (회로 차단기)
- Retry Policy (재시도 정책)
- Timeout Policy (타임아웃 정책)
- Fallback Policy (폴백 정책)  
- Bulkhead Policy (격벽 정책)

## 주요 기능

### 1. Circuit Breaker Pattern
외부 서비스 장애 시 장애 전파를 방지합니다.

```javascript
const circuitBreaker = new CircuitBreaker({
    failureThreshold: 5,    // 실패 임계값
    resetTimeout: 60000,    // 재시도 대기 시간 (1분)
    halfOpenMaxCalls: 3     // Half-open 상태에서 최대 호출 수
});
```

### 2. Retry Policy
일시적 장애에 대해 자동 재시도를 수행합니다.

```javascript
const retryPolicy = new RetryPolicy({
    maxRetries: 3,          // 최대 재시도 횟수
    initialDelay: 100,      // 초기 지연 시간 (ms)
    maxDelay: 3000,         // 최대 지연 시간 (ms)
    backoffMultiplier: 2    // 지수 백오프 배수
});
```

### 3. Timeout Policy
작업에 시간 제한을 설정합니다.

```javascript
const timeoutPolicy = new TimeoutPolicy({
    defaultTimeout: 5000,   // 기본 타임아웃 (5초)
    timeouts: {
        database: 3000,     // 데이터베이스 작업 (3초)
        redis: 1000,        // Redis 작업 (1초)
        external: 10000     // 외부 API 호출 (10초)
    }
});
```

### 4. Fallback Policy
실패 시 대체 값이나 동작을 제공합니다.

```javascript
const fallbackPolicy = new FallbackPolicy({
    errorThreshold: 3,      // 에러 임계값
    errorWindow: 60000,     // 에러 추적 시간 윈도우
    fallbackHandlers: new Map() // 폴백 핸들러 맵
});
```

### 5. Bulkhead Policy
리소스 격리를 통해 장애 격리를 구현합니다.

```javascript
const bulkheadPolicy = new BulkheadPolicy({
    maxConcurrentCalls: 10, // 최대 동시 호출 수
    queueCapacity: 5,       // 대기열 크기
    timeout: 2000          // 대기열 타임아웃
});
```

## 사용 예시

### 1. 통합 회복성 정책 사용

```javascript
const { ResiliencePolicy } = require('./shared/resilience');
const { getServiceConfig } = require('./shared/resilience/config/resilience.config');

// 서비스별 회복성 정책 생성
const authResilience = new ResiliencePolicy({
    ...getServiceConfig('auth'),
    logger
});

// 회복성 정책 적용
const result = await authResilience.execute(
    async () => {
        // 위험한 작업 (예: 외부 서비스 호출)
        return await axios.get('http://user-service/api/v1/users');
    },
    {
        fallbackKey: 'getUserProfile',
        service: 'user',
        operation: 'getUserProfile'
    }
);
```

### 2. Axios 어댑터 사용

```javascript
const { createServiceClient } = require('./shared/resilience/adapters/axiosAdapter');

// 회복성이 적용된 서비스 클라이언트 생성
const userServiceClient = createServiceClient('user', 'http://user-service:3004', {
    logger,
    headers: {
        'X-Service-Name': 'auth-service'
    }
});

// 자동으로 회복성 정책이 적용됨
const userData = await userServiceClient.get('/api/v1/users/123');
```

### 3. 폴백 핸들러 등록

```javascript
authResilience.registerFallback('getUserProfile', async (error) => {
    // Redis 캐시에서 사용자 프로필 조회
    return {
        id: '12345',
        name: 'Cached User',
        email: 'cached@example.com',
        _isFallback: true
    };
});
```

## 서비스별 설정

각 서비스는 특성에 맞는 회복성 설정을 가지고 있습니다:

### Auth Service
- 높은 가용성이 필요한 인증 서비스
- 짧은 타임아웃 (5초)
- 중간 수준의 재시도 (3회)

### Realtime Service
- 실시간 통신을 위한 낮은 지연 시간 요구
- 짧은 타임아웃 (3초)
- 최소한의 재시도 (2회)

### Session Service  
- 세션 데이터 일관성 중시
- 중간 타임아웃 (8초)
- 표준 재시도 정책

### Report Service
- 보고서 생성은 시간이 오래 걸림
- 긴 타임아웃 (15초)
- 더 많은 재시도 시도 (4회)

## 모니터링

### 1. 회복성 메트릭

Prometheus 메트릭이 자동으로 수집됩니다:

```
# Circuit Breaker 상태
circuit_breaker_state{service="auth", operation="getUserProfile"}

# 재시도 시도 횟수
retry_attempts_total{service="auth", operation="getUserProfile"}

# 타임아웃 발생 수
operation_timeouts_total{service="auth", operation="getUserProfile"}

# 폴백 실행 수
fallback_executions_total{service="auth", operation="getUserProfile"}

# Bulkhead 거부 수
bulkhead_rejections_total{service="auth", operation="getUserProfile"}
```

### 2. 상태 체크 엔드포인트

```
GET /resilience/metrics
```

응답 예시:
```json
{
  "auth": {
    "policy": "auth-service",
    "healthy": true,
    "executions": {
      "totalExecutions": 1000,
      "successfulExecutions": 980,
      "failedExecutions": 20,
      "fallbackExecutions": 15
    },
    "circuitBreaker": {
      "state": "CLOSED",
      "failureCount": 0
    },
    "bulkhead": {
      "activeCalls": 3,
      "queueLength": 0
    }
  }
}
```

## 환경별 설정

### Development
- 더 관대한 설정 (더 많은 재시도, 더 긴 타임아웃)
- 디버깅을 위한 상세 로깅

### Production
- 더 엄격한 설정 (빠른 실패, 짧은 타임아웃)
- 성능 최적화된 설정

## 주의사항

1. **적절한 타임아웃 설정**: 너무 짧으면 불필요한 실패, 너무 길면 응답 지연
2. **폴백 전략 설계**: 캐시된 데이터 사용 또는 기본값 반환 고려
3. **메트릭 모니터링**: 회복성 정책의 효과성을 지속적으로 평가
4. **에러 처리**: 회복성 정책 실패 시에도 graceful한 에러 처리 필요

## 확장 포인트

1. **커스텀 정책 추가**: 새로운 회복성 패턴 구현 가능
2. **동적 설정 변경**: 런타임에 정책 파라미터 조정 가능  
3. **이벤트 훅**: 각 정책의 이벤트에 커스텀 로직 추가 가능
4. **메트릭 확장**: 비즈니스 메트릭과 통합 가능

## 참고 자료

- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [Retry Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/retry)
- [Bulkhead Pattern](https://docs.microsoft.com/en-us/azure/architecture/patterns/bulkhead)
- [Fallback Pattern](https://microservices.io/patterns/reliability/fallback.html)

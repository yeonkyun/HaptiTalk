# HaptiTalk API 문서 시스템

HaptiTalk 마이크로서비스 아키텍처의 통합 API 문서 시스템입니다. 이 시스템은 Kong API Gateway와 정적 웹 서비스를 활용하여 모든 마이크로서비스의 API 문서를 단일 인터페이스로 통합합니다.

## 개요

이 시스템은 다음과 같은 구성요소로 이루어져 있습니다:

- **Kong API Gateway**: 모든 API 요청의 진입점으로, API 문서 경로 라우팅 제공
- **정적 웹 서비스(static-web)**: Swagger UI와 API 스펙 파일 호스팅
- **Swagger UI**: API 문서 시각화 인터페이스
- **마이크로서비스별 OpenAPI 스펙 파일**: 각 서비스의 API 정의

## 접근 방법

API 문서는 다음 URL을 통해 접근할 수 있습니다:

```
http://localhost:8000/api-docs/
```

**인증 정보**:
- 사용자명: `apidocs` (기본값, 환경 변수 `API_DOCS_USERNAME`으로 변경 가능)
- 비밀번호: `haptitalk-docs-password` (기본값, 환경 변수 `API_DOCS_PASSWORD`로 변경 가능)

특정 서비스의 API 문서에 직접 접근하려면:

```
http://localhost:8000/api-docs/?service={service-name}
```

예: `http://localhost:8000/api-docs/?service=auth-service`

## 디렉토리 구조

```
infrastructure/
└── static-web/
    └── html/
        ├── api-docs/         # API 문서 UI
        │   ├── index.html    # 통합 문서 인터페이스
        │   ├── swagger-ui.css
        │   ├── swagger-ui-bundle.js
        │   └── swagger-ui-standalone-preset.js
        └── swagger-specs/    # API 스펙 파일
            ├── auth-service.json
            ├── user-service.json
            ├── session-service.json
            ├── feedback-service.json
            ├── realtime-service.json
            └── report-service.json
```

## 새 마이크로서비스 API 문서 추가 방법

1. OpenAPI 3.0 형식의 JSON 스펙 파일을 `infrastructure/static-web/html/swagger-specs/` 디렉토리에 추가
2. `infrastructure/static-web/html/api-docs/index.html` 파일의 `serviceSpecs` 객체와 select 요소에 새 서비스 정보 추가
3. Kong API Gateway 설정(`infrastructure/api-gateway/kong.yml`)에 새 서비스 라우팅 추가
4. 변경사항 적용을 위해 서비스 재시작: `docker-compose restart kong static-web`

## 주의사항

- API 스펙 파일은 항상 최신 상태를 유지해야 합니다
- Kong API Gateway가 실행 중이어야 API 문서에 접근할 수 있습니다
- 서비스 간 전환 시 브라우저 캐시로 인한 지연이 발생할 수 있습니다

## 문제 해결

일반적인 문제 및 해결 방법:

1. API 문서에 접근할 수 없는 경우:
   - Kong API Gateway와 static-web 서비스가 실행 중인지 확인
   - `docker-compose ps` 명령으로 컨테이너 상태 확인
   - Kong 로그 확인: `docker logs haptitalk-kong`
   - 인증 정보가 올바른지 확인 (기본 사용자명: `apidocs`, 기본 비밀번호: `haptitalk-docs-password`)

2. API 스펙 파일이 로드되지 않는 경우:
   - 파일 경로와 이름이 올바른지 확인
   - 파일 형식이 유효한 JSON인지 확인
   - 브라우저 개발자 도구에서 네트워크 요청 확인

3. CSP 관련 오류가 발생하는 경우:
   - Kong API Gateway의 CSP 헤더 설정 확인
   - 외부 리소스 의존성 최소화 

4. 인증 오류 (401 Unauthorized)가 발생하는 경우:
   - Kong 설정파일의 환경 변수 치환이 제대로 되었는지 확인
   - 컨테이너 재시작 후 로그 확인: `docker-compose restart kong && docker logs haptitalk-kong`
   - entrypoint.sh 스크립트가 실행 권한을 가지고 있는지 확인: `chmod +x infrastructure/api-gateway/entrypoint.sh`

## 환경 변수 설정

API 문서 접근 인증 정보는 다음 환경 변수를 통해 변경할 수 있습니다:

```
# .env 파일 또는 환경 변수로 설정
API_DOCS_USERNAME=원하는_사용자명
API_DOCS_PASSWORD=원하는_비밀번호
```

환경 변수 설정 후에는 Kong 서비스를 재시작해야 합니다:

```
docker-compose restart kong
``` 
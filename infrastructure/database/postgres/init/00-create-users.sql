-- PostgreSQL 사용자 및 권한 설정
-- 이 파일은 컨테이너 시작 시 자동으로 실행됩니다.

-- 기본 사용자에게 모든 권한 부여 (간단한 해결책)
-- 모든 서비스가 POSTGRES_USER로 연결하도록 함

-- 향후 생성될 스키마들에 대한 권한 설정
GRANT USAGE ON SCHEMA public TO PUBLIC;
GRANT CREATE ON SCHEMA public TO PUBLIC;

-- 모든 테이블에 대한 권한 부여
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO PUBLIC;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO PUBLIC;

-- 앞으로 생성될 테이블에 대한 기본 권한 설정
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO PUBLIC;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO PUBLIC;

-- 로그인 시도에 대한 디버그 정보
\echo 'PostgreSQL 사용자 권한 설정이 완료되었습니다.'
\echo '모든 서비스는 POSTGRES_USER 계정으로 데이터베이스에 접근할 수 있습니다.' 
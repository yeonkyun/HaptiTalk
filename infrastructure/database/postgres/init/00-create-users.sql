-- PostgreSQL 사용자 및 권한 설정
-- 이 파일은 컨테이너 시작 시 자동으로 실행됩니다.

-- 기본 데이터베이스 생성 (POSTGRES_DB가 자동 생성되지 않는 경우 대비)
-- PostgreSQL 컨테이너는 POSTGRES_DB 환경변수로 지정된 DB를 자동 생성해야 하지만
-- 때로는 수동으로 생성해야 할 수 있음

-- 일반적인 데이터베이스 이름들을 생성 (함수 밖에서 직접 실행)
-- haptitalk 데이터베이스 생성 (존재하지 않는 경우)
SELECT 'CREATE DATABASE haptitalk'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'haptitalk')\gexec

-- haptitalk_prod 데이터베이스 생성 (존재하지 않는 경우)  
SELECT 'CREATE DATABASE haptitalk_prod'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'haptitalk_prod')\gexec

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
\echo 'haptitalk 및 haptitalk_prod 데이터베이스가 생성되었습니다.' 
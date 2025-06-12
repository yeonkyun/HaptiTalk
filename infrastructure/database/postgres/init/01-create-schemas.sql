-- 스키마 생성
CREATE SCHEMA IF NOT EXISTS auth;
CREATE SCHEMA IF NOT EXISTS users;
CREATE SCHEMA IF NOT EXISTS config;
CREATE SCHEMA IF NOT EXISTS session;

COMMENT ON SCHEMA auth IS '인증 관련 테이블을 포함하는 스키마';
COMMENT ON SCHEMA users IS '사용자 데이터 관련 테이블을 포함하는 스키마';
COMMENT ON SCHEMA config IS '시스템 설정 관련 테이블을 포함하는 스키마';
COMMENT ON SCHEMA session IS '세션 데이터 관련 테이블을 포함하는 스키마';
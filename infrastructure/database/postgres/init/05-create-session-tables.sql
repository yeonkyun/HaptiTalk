-- 세션 관련 테이블 (session 스키마)
CREATE TABLE IF NOT EXISTS session.sessions (
    id UUID PRIMARY KEY,
    user_id UUID NOT NULL,
    title VARCHAR(100) NOT NULL,
    type VARCHAR(50) NOT NULL CHECK (type IN ('dating', 'interview', 'business', 'presentation')),
    status VARCHAR(50) NOT NULL DEFAULT 'created' CHECK (status IN ('created', 'active', 'paused', 'ended')),
    start_time TIMESTAMP WITH TIME ZONE,
    end_time TIMESTAMP WITH TIME ZONE,
    duration INTEGER,
    settings JSONB NOT NULL DEFAULT '{}',
    metadata JSONB NOT NULL DEFAULT '{}',
    summary JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS sessions_user_id_idx ON session.sessions (user_id);
CREATE INDEX IF NOT EXISTS sessions_type_idx ON session.sessions (type);
CREATE INDEX IF NOT EXISTS sessions_status_idx ON session.sessions (status);

-- 업데이트 트리거 생성 (updated_at 자동 갱신)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_session_updated_at BEFORE UPDATE
    ON session.sessions FOR EACH ROW EXECUTE FUNCTION 
    update_updated_at_column(); 
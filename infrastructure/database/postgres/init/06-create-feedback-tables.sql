-- 피드백 관련 테이블 생성 스크립트

-- 사용자 피드백 설정 테이블
CREATE TABLE IF NOT EXISTS public.user_feedback_settings (
    user_id UUID PRIMARY KEY,
    haptic_strength INTEGER NOT NULL DEFAULT 5 CHECK (haptic_strength BETWEEN 1 AND 10),
    active_patterns TEXT[] NOT NULL DEFAULT '{}',
    priority_threshold VARCHAR(10) NOT NULL DEFAULT 'medium' CHECK (priority_threshold IN ('low', 'medium', 'high')),
    minimum_interval_seconds INTEGER NOT NULL DEFAULT 10 CHECK (minimum_interval_seconds BETWEEN 1 AND 60),
    feedback_frequency VARCHAR(10) NOT NULL DEFAULT 'medium' CHECK (feedback_frequency IN ('low', 'medium', 'high')),
    mode_settings JSONB,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- 햅틱 패턴 정의 테이블 (config 스키마에 생성)
CREATE TABLE IF NOT EXISTS config.haptic_patterns (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    pattern_data JSONB NOT NULL,
    category VARCHAR(50) NOT NULL,
    intensity_default INTEGER NOT NULL DEFAULT 5 CHECK (intensity_default BETWEEN 1 AND 10),
    duration_ms INTEGER NOT NULL DEFAULT 300,
    version INTEGER NOT NULL DEFAULT 1,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_user_feedback_settings_user_id ON public.user_feedback_settings (user_id);
CREATE INDEX IF NOT EXISTS idx_haptic_patterns_category ON config.haptic_patterns (category);
CREATE INDEX IF NOT EXISTS idx_haptic_patterns_active ON config.haptic_patterns (is_active);

-- 업데이트 트리거 함수 (이미 존재하지 않는 경우에만 생성)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 사용자 피드백 설정 업데이트 트리거
CREATE TRIGGER IF NOT EXISTS update_user_feedback_settings_updated_at 
    BEFORE UPDATE ON public.user_feedback_settings 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 햅틱 패턴 업데이트 트리거  
CREATE TRIGGER IF NOT EXISTS update_haptic_patterns_updated_at 
    BEFORE UPDATE ON config.haptic_patterns 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 기본 햅틱 패턴 데이터 삽입
INSERT INTO config.haptic_patterns (id, name, description, pattern_data, category, intensity_default, duration_ms)
VALUES
('S1', '속도 조절', '말하기 속도가 너무 빠를 때', 
 '{"vibrations": [{"duration": 100, "intensity": 5}, {"duration": 0, "intensity": 0, "interval": 100}, {"duration": 100, "intensity": 5}, {"duration": 0, "intensity": 0, "interval": 100}, {"duration": 100, "intensity": 5}], "total_duration": 500}', 
 'pace', 5, 500),
('S2', '속도 늦추기', '말하기 속도를 늦춰야 할 때', 
 '{"vibrations": [{"duration": 300, "intensity": 3}, {"duration": 0, "intensity": 0, "interval": 200}, {"duration": 300, "intensity": 3}], "total_duration": 800}', 
 'pace', 3, 800),
('L1', '경청 강화', '더 적극적인 경청이 필요할 때', 
 '{"vibrations": [{"duration": 200, "intensity": 4}, {"duration": 0, "intensity": 0, "interval": 150}, {"duration": 200, "intensity": 7}, {"duration": 0, "intensity": 0, "interval": 150}, {"duration": 200, "intensity": 10}], "total_duration": 850}', 
 'listening', 5, 850),
('L2', '질문 유도', '상대방에게 질문을 유도할 때', 
 '{"vibrations": [{"duration": 150, "intensity": 6}, {"duration": 0, "intensity": 0, "interval": 100}, {"duration": 150, "intensity": 4}, {"duration": 0, "intensity": 0, "interval": 100}, {"duration": 150, "intensity": 8}], "total_duration": 650}', 
 'listening', 6, 650),
('L3', '공감 표현', '공감을 표현해야 할 때', 
 '{"vibrations": [{"duration": 400, "intensity": 6}], "total_duration": 400}', 
 'listening', 6, 400),
('F1', '주제 전환', '주제 전환이 필요하거나 추천할 때', 
 '{"vibrations": [{"duration": 400, "intensity": 7}], "total_duration": 400}', 
 'flow', 7, 400),
('F2', '대화 주도', '대화를 주도해야 할 때', 
 '{"vibrations": [{"duration": 250, "intensity": 8}, {"duration": 0, "intensity": 0, "interval": 150}, {"duration": 250, "intensity": 5}], "total_duration": 650}', 
 'flow', 7, 650),
('F3', '마무리 유도', '대화를 마무리할 때', 
 '{"vibrations": [{"duration": 500, "intensity": 4}], "total_duration": 500}', 
 'flow', 4, 500),
('F4', '침묵 깨기', '침묵을 깨야 할 때', 
 '{"vibrations": [{"duration": 100, "intensity": 7}, {"duration": 0, "intensity": 0, "interval": 50}, {"duration": 100, "intensity": 7}, {"duration": 0, "intensity": 0, "interval": 50}, {"duration": 100, "intensity": 7}], "total_duration": 400}', 
 'flow', 7, 400),
('R1', '호감도 상승', '상대방의 호감도가 상승했을 때', 
 '{"vibrations": [{"duration": 200, "intensity": 4}, {"duration": 0, "intensity": 0, "interval": 50}, {"duration": 200, "intensity": 7}, {"duration": 0, "intensity": 0, "interval": 50}, {"duration": 200, "intensity": 10}], "total_duration": 700}', 
 'reaction', 5, 700),
('R2', '긍정 신호', '상대방의 긍정적 반응이 감지될 때', 
 '{"vibrations": [{"duration": 150, "intensity": 8}, {"duration": 0, "intensity": 0, "interval": 100}, {"duration": 150, "intensity": 6}], "total_duration": 400}', 
 'reaction', 7, 400),
('R3', '주의 신호', '상대방의 관심이 떨어질 때', 
 '{"vibrations": [{"duration": 300, "intensity": 9}], "total_duration": 300}', 
 'reaction', 9, 300),
('A1', '음성 크기 조절', '목소리를 크게 해야 할 때', 
 '{"vibrations": [{"duration": 200, "intensity": 8}, {"duration": 0, "intensity": 0, "interval": 100}, {"duration": 200, "intensity": 8}], "total_duration": 500}', 
 'audio', 8, 500),
('A2', '발음 개선', '발음을 명확히 해야 할 때', 
 '{"vibrations": [{"duration": 100, "intensity": 5}, {"duration": 0, "intensity": 0, "interval": 50}, {"duration": 100, "intensity": 5}, {"duration": 0, "intensity": 0, "interval": 50}, {"duration": 100, "intensity": 5}, {"duration": 0, "intensity": 0, "interval": 50}, {"duration": 100, "intensity": 5}], "total_duration": 550}', 
 'audio', 5, 550)
ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    description = EXCLUDED.description,
    pattern_data = EXCLUDED.pattern_data,
    category = EXCLUDED.category,
    intensity_default = EXCLUDED.intensity_default,
    duration_ms = EXCLUDED.duration_ms,
    updated_at = now(); 
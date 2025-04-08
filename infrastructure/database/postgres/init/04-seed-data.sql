-- 기본 설정값 추가
INSERT INTO config.app_settings (key, value, description, is_public) 
VALUES 
('app_name', 'HaptiTalk', '앱 이름', true),
('default_haptic_strength', '5', '기본 햅틱 강도 (1-10)', true),
('analysis_default_level', 'standard', '기본 분석 수준 (basic, standard, advanced)', true),
('default_audio_retention_days', '7', '오디오 기본 보관 일수', true),
('max_session_duration_minutes', '120', '최대 세션 지속 시간(분)', false)
ON CONFLICT (key) DO NOTHING;

-- 기본 햅틱 패턴 추가
INSERT INTO config.haptic_patterns (id, name, description, pattern_data, category, intensity_default, duration_ms)
VALUES
('S1', '속도 조절', '말하기 속도가 너무 빠를 때', 
 '{"vibrations": [{"duration": 100, "intensity": 5}, {"duration": 0, "intensity": 0, "interval": 100}, {"duration": 100, "intensity": 5}, {"duration": 0, "intensity": 0, "interval": 100}, {"duration": 100, "intensity": 5}], "total_duration": 500}', 
 'pace', 5, 500),
('L1', '경청 강화', '더 적극적인 경청이 필요할 때', 
 '{"vibrations": [{"duration": 200, "intensity": 4}, {"duration": 0, "intensity": 0, "interval": 150}, {"duration": 200, "intensity": 7}, {"duration": 0, "intensity": 0, "interval": 150}, {"duration": 200, "intensity": 10}], "total_duration": 850}', 
 'listening', 5, 850),
('F1', '주제 전환', '주제 전환이 필요하거나 추천할 때', 
 '{"vibrations": [{"duration": 400, "intensity": 7}], "total_duration": 400}', 
 'flow', 7, 400),
('R1', '호감도 상승', '상대방의 호감도가 상승했을 때', 
 '{"vibrations": [{"duration": 200, "intensity": 4}, {"duration": 0, "intensity": 0, "interval": 50}, {"duration": 200, "intensity": 7}, {"duration": 0, "intensity": 0, "interval": 50}, {"duration": 200, "intensity": 10}], "total_duration": 700}', 
 'reaction', 5, 700)
ON CONFLICT (id) DO NOTHING;

-- 테스트 사용자 추가 (비밀번호: test1234)
INSERT INTO auth.users (id, email, password_hash, salt, is_verified)
VALUES 
('11111111-1111-1111-1111-111111111111', 'test@example.com', 
 '$2b$10$8KHMBx4NaZrv7NzRTRNFR.XqYEjWUW3q8QZ9yJQBTK4DxZZ3vXn1G', 
 '$2b$10$8KHMBx4NaZrv7NzRTRNFR.', true)
ON CONFLICT (id) DO NOTHING;

-- 테스트 사용자 프로필 추가
INSERT INTO users.profiles (id, username, first_name, last_name)
VALUES 
('11111111-1111-1111-1111-111111111111', 'testuser', '홍', '길동')
ON CONFLICT (id) DO NOTHING;

-- 테스트 사용자 설정 추가
INSERT INTO users.settings (id)
VALUES 
('11111111-1111-1111-1111-111111111111')
ON CONFLICT (id) DO NOTHING;
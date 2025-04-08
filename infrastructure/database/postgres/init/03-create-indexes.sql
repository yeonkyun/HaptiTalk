-- 인덱스 생성
CREATE INDEX IF NOT EXISTS idx_devices_user_id ON users.devices(user_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_devices_user_device ON users.devices(user_id, device_token);

CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON users.sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_type ON users.sessions(user_id, session_type);
CREATE INDEX IF NOT EXISTS idx_sessions_start_time ON users.sessions(start_time);

CREATE UNIQUE INDEX IF NOT EXISTS idx_app_settings_key ON config.app_settings(key);
CREATE INDEX IF NOT EXISTS idx_haptic_patterns_category ON config.haptic_patterns(category);
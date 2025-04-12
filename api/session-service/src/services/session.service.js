const {Session, SESSION_TYPES, SESSION_STATUS, getDefaultSettings} = require('../models/session.model');
const {redisUtils, CHANNELS} = require('../config/redis');
const logger = require('../utils/logger');
const {Op} = require('sequelize');

/**
 * 세션 서비스 클래스
 * 세션 생성, 관리, 조회, 종료 등의 비즈니스 로직을 처리
 */
class SessionService {
    /**
     * 새 세션 생성
     * @param {Object} sessionData 세션 생성 데이터
     * @returns {Promise<Object>} 생성된 세션 객체
     */
    async createSession(sessionData) {
        const {user_id, title, type, custom_settings = {}} = sessionData;

        // 세션 타입 유효성 검사
        if (!Object.values(SESSION_TYPES).includes(type)) {
            throw new Error(`Invalid session type: ${type}`);
        }

        // 기본 설정 가져오기
        const defaultSettings = getDefaultSettings(type);

        // 사용자 커스텀 설정과 기본 설정 병합
        const mergedSettings = this.mergeSettings(defaultSettings, custom_settings);

        try {
            // 세션 레코드 생성
            const session = await Session.create({
                user_id,
                title,
                type,
                status: SESSION_STATUS.CREATED,
                settings: mergedSettings,
                metadata: {
                    device_info: sessionData.device_info || {},
                    location: sessionData.location || null,
                    participants: sessionData.participants || [],
                    tags: sessionData.tags || [],
                }
            });

            // Redis에 세션 구성 캐싱
            await redisUtils.set(
                redisUtils.keys.sessionConfig(session.id),
                {
                    id: session.id,
                    user_id: session.user_id,
                    type: session.type,
                    settings: session.settings
                },
                86400 // 24시간 TTL
            );

            // 세션 상태 Redis에 저장
            await redisUtils.set(
                redisUtils.keys.sessionStatus(session.id),
                {
                    status: SESSION_STATUS.CREATED,
                    start_time: null,
                    last_activity: new Date().toISOString()
                },
                86400 // 24시간 TTL
            );

            // 사용자의 세션 목록에 추가
            await redisUtils.addToList(
                redisUtils.keys.userSessions(user_id),
                {
                    id: session.id,
                    title: session.title,
                    type: session.type,
                    created_at: session.created_at
                }
            );

            // 세션 생성 이벤트 발행
            await redisUtils.publish(CHANNELS.SESSION_CREATED, {
                session_id: session.id,
                user_id: session.user_id,
                type: session.type,
                timestamp: new Date().toISOString()
            });

            logger.info(`Session created: ${session.id} for user ${user_id}`);
            return session;
        } catch (error) {
            logger.error('Error creating session:', error);
            throw error;
        }
    }

    /**
     * 세션 정보 조회
     * @param {string} sessionId 세션 ID
     * @returns {Promise<Object>} 세션 객체
     */
    async getSession(sessionId) {
        try {
            // 먼저 Redis에서 세션 구성 확인
            const cachedConfig = await redisUtils.get(redisUtils.keys.sessionConfig(sessionId));
            const cachedStatus = await redisUtils.get(redisUtils.keys.sessionStatus(sessionId));

            // 캐시에 있으면 데이터베이스 조회와 함께 통합하여 반환
            if (cachedConfig && cachedStatus) {
                const dbSession = await Session.findByPk(sessionId);

                if (!dbSession) {
                    throw new Error(`Session not found: ${sessionId}`);
                }

                return {
                    ...dbSession.get({plain: true}),
                    cached_status: cachedStatus
                };
            }

            // 캐시에 없으면 데이터베이스에서만 조회
            const session = await Session.findByPk(sessionId);

            if (!session) {
                throw new Error(`Session not found: ${sessionId}`);
            }

            return session;
        } catch (error) {
            logger.error(`Error getting session ${sessionId}:`, error);
            throw error;
        }
    }

    /**
     * 사용자의 세션 목록 조회
     * @param {string} userId 사용자 ID
     * @param {Object} options 조회 옵션 (필터 등)
     * @returns {Promise<Array>} 세션 객체 배열
     */
    async getUserSessions(userId, options = {}) {
        const {status, type, limit = 10, offset = 0, sort = 'created_at', order = 'DESC'} = options;

        // 기본 조건: 사용자 ID 필터
        const where = {user_id: userId};

        // 상태 필터 적용
        if (status) {
            where.status = status;
        }

        // 타입 필터 적용
        if (type) {
            where.type = type;
        }

        try {
            // 데이터베이스에서 세션 목록 조회
            const sessions = await Session.findAndCountAll({
                where,
                limit,
                offset,
                order: [[sort, order]],
                attributes: [
                    'id', 'title', 'type', 'status', 'start_time', 'end_time',
                    'duration', 'created_at', 'updated_at'
                ]
            });

            return sessions;
        } catch (error) {
            logger.error(`Error getting sessions for user ${userId}:`, error);
            throw error;
        }
    }

    /**
     * 세션 업데이트
     * @param {string} sessionId 세션 ID
     * @param {Object} updateData 업데이트할 데이터
     * @returns {Promise<Object>} 업데이트된 세션 객체
     */
    async updateSession(sessionId, updateData) {
        try {
            const session = await Session.findByPk(sessionId);

            if (!session) {
                throw new Error(`Session not found: ${sessionId}`);
            }

            // 업데이트 가능한 필드 목록
            const updatableFields = ['title', 'status', 'metadata'];
            const updates = {};

            // 업데이트 가능한 필드만 필터링
            Object.keys(updateData).forEach(key => {
                if (updatableFields.includes(key)) {
                    updates[key] = updateData[key];
                }
            });

            // 설정 업데이트 특별 처리
            if (updateData.settings) {
                updates.settings = this.mergeSettings(session.settings, updateData.settings);
            }

            // 세션 업데이트
            await session.update(updates);

            // Redis 캐시 업데이트
            if (updateData.settings) {
                const cachedConfig = await redisUtils.get(redisUtils.keys.sessionConfig(sessionId));
                if (cachedConfig) {
                    await redisUtils.set(
                        redisUtils.keys.sessionConfig(sessionId),
                        {
                            ...cachedConfig,
                            settings: updates.settings
                        },
                        86400 // 24시간 TTL
                    );
                }
            }

            // 상태 업데이트 시 Redis 상태 캐시 업데이트
            if (updateData.status) {
                const cachedStatus = await redisUtils.get(redisUtils.keys.sessionStatus(sessionId));
                if (cachedStatus) {
                    await redisUtils.set(
                        redisUtils.keys.sessionStatus(sessionId),
                        {
                            ...cachedStatus,
                            status: updateData.status,
                            last_activity: new Date().toISOString()
                        },
                        86400 // 24시간 TTL
                    );
                }

                // 상태 변경에 따른 추가 처리
                switch (updateData.status) {
                    case SESSION_STATUS.ACTIVE:
                        // 세션 시작 처리
                        if (!session.start_time) {
                            await session.update({start_time: new Date()});
                        }
                        break;

                    case SESSION_STATUS.ENDED:
                        // 세션 종료 처리
                        if (!session.end_time) {
                            const endTime = new Date();
                            const duration = session.start_time
                                ? Math.floor((endTime - new Date(session.start_time)) / 1000)
                                : 0;

                            await session.update({
                                end_time: endTime,
                                duration
                            });
                        }
                        break;
                }
            }

            // 세션 업데이트 이벤트 발행
            await redisUtils.publish(CHANNELS.SESSION_UPDATED, {
                session_id: session.id,
                user_id: session.user_id,
                type: session.type,
                status: session.status,
                timestamp: new Date().toISOString()
            });

            logger.info(`Session updated: ${sessionId}`);
            return session;
        } catch (error) {
            logger.error(`Error updating session ${sessionId}:`, error);
            throw error;
        }
    }

    /**
     * 세션 종료
     * @param {string} sessionId 세션 ID
     * @param {Object} summaryData 세션 요약 데이터 (선택)
     * @returns {Promise<Object>} 종료된 세션 객체
     */
    async endSession(sessionId, summaryData = null) {
        try {
            const session = await Session.findByPk(sessionId);

            if (!session) {
                throw new Error(`Session not found: ${sessionId}`);
            }

            // 이미 종료된 세션인지 확인
            if (session.status === SESSION_STATUS.ENDED) {
                return session;
            }

            const endTime = new Date();
            const duration = session.start_time
                ? Math.floor((endTime - new Date(session.start_time)) / 1000)
                : 0;

            // 세션 업데이트
            const updates = {
                status: SESSION_STATUS.ENDED,
                end_time: endTime,
                duration
            };

            // 요약 데이터가 있으면 추가
            if (summaryData) {
                updates.summary = summaryData;
            }

            await session.update(updates);

            // Redis 캐시 업데이트
            const cachedStatus = await redisUtils.get(redisUtils.keys.sessionStatus(sessionId));
            if (cachedStatus) {
                await redisUtils.set(
                    redisUtils.keys.sessionStatus(sessionId),
                    {
                        status: SESSION_STATUS.ENDED,
                        end_time: endTime.toISOString(),
                        duration,
                        last_activity: new Date().toISOString()
                    },
                    86400 // 24시간 TTL
                );
            }

            // 세션 종료 이벤트 발행
            await redisUtils.publish(CHANNELS.SESSION_ENDED, {
                session_id: session.id,
                user_id: session.user_id,
                type: session.type,
                duration,
                timestamp: new Date().toISOString()
            });

            logger.info(`Session ended: ${sessionId}, duration: ${duration}s`);
            return session;
        } catch (error) {
            logger.error(`Error ending session ${sessionId}:`, error);
            throw error;
        }
    }

    /**
     * 세션 요약 데이터 업데이트
     * @param {string} sessionId 세션 ID
     * @param {Object} summaryData 세션 요약 데이터
     * @returns {Promise<Object>} 업데이트된 세션 객체
     */
    async updateSessionSummary(sessionId, summaryData) {
        try {
            const session = await Session.findByPk(sessionId);

            if (!session) {
                throw new Error(`Session not found: ${sessionId}`);
            }

            await session.update({summary: summaryData});
            logger.info(`Session summary updated: ${sessionId}`);
            return session;
        } catch (error) {
            logger.error(`Error updating session summary ${sessionId}:`, error);
            throw error;
        }
    }

    /**
     * 발표 타이머 설정
     * @param {string} sessionId 세션 ID
     * @param {Object} timerSettings 타이머 설정
     * @returns {Promise<Object>} 설정된 타이머 정보
     */
    async setupPresentationTimer(sessionId, timerSettings) {
        try {
            const session = await this.getSession(sessionId);

            if (session.type !== SESSION_TYPES.PRESENTATION) {
                throw new Error(`Session is not a presentation type: ${sessionId}`);
            }

            // 타이머 설정 업데이트
            const settings = session.settings;

            if (!settings.presentation_specific) {
                settings.presentation_specific = {};
            }

            if (!settings.presentation_specific.timer) {
                settings.presentation_specific.timer = {};
            }

            // 타이머 설정 병합
            const currentTimer = settings.presentation_specific.timer;
            const newTimer = {
                ...currentTimer,
                ...timerSettings,
                enabled: true
            };

            settings.presentation_specific.timer = newTimer;

            // 세션 설정 업데이트
            await this.updateSession(sessionId, {settings});

            // Redis에 타이머 정보 저장
            const timerData = {
                duration_seconds: (newTimer.duration_minutes || 10) * 60,
                alerts: newTimer.alerts || {
                    halfway: true,
                    five_minutes: true,
                    two_minutes: true,
                    thirty_seconds: true
                },
                start_time: null,
                end_time: null,
                status: 'ready'
            };

            await redisUtils.set(
                redisUtils.keys.sessionTimer(sessionId),
                timerData,
                86400 // 24시간 TTL
            );

            return timerData;
        } catch (error) {
            logger.error(`Error setting up presentation timer for session ${sessionId}:`, error);
            throw error;
        }
    }

    /**
     * 설정 병합 유틸리티 함수
     * @param {Object} baseSettings 기본 설정
     * @param {Object} customSettings 사용자 커스텀 설정
     * @returns {Object} 병합된 설정
     */
    mergeSettings(baseSettings, customSettings) {
        // 깊은 복사로 기본 설정 복제
        const mergedSettings = JSON.parse(JSON.stringify(baseSettings));

        // 커스텀 설정을 재귀적으로 병합
        const recursiveMerge = (target, source) => {
            for (const key in source) {
                if (source[key] !== null && typeof source[key] === 'object' && !Array.isArray(source[key])) {
                    // 대상이 객체가 아니면 객체로 초기화
                    if (!target[key] || typeof target[key] !== 'object') {
                        target[key] = {};
                    }
                    recursiveMerge(target[key], source[key]);
                } else {
                    // 객체가 아닌 경우 직접 값 할당
                    target[key] = source[key];
                }
            }
        };

        recursiveMerge(mergedSettings, customSettings);
        return mergedSettings;
    }
}

// SessionService 인스턴스 생성 및 export
const sessionService = new SessionService();
module.exports = sessionService;
const logger = require('../utils/logger');
const sessionApiService = require('./session-api.service');
const { sessionServiceClient, withRedisResilience } = require('../utils/serviceClient');

/**
 * 세션 캐시 유효 시간 (초)
 */
const SESSION_CACHE_EXPIRY = 60; // 1분

/**
 * 세션 유효성 검증
 * @param {string} sessionId - 세션 ID
 * @param {string} userId - 사용자 ID
 * @param {Redis} redisClient - Redis 클라이언트
 * @returns {Promise<boolean>} - 세션 유효성 여부
 */
const validateSession = async (sessionId, userId, redisClient) => {
    try {
        // 1. 먼저 Redis 캐시에서 세션 정보 확인 (회복성 패턴 적용)
        const sessionKey = `session:${sessionId}`;
        const sessionData = await withRedisResilience(
            async () => redisClient.get(sessionKey),
            { operationName: 'get_session_cache' }
        ).catch(error => {
            logger.warn('Redis 조회 실패, 계속 진행', { error: error.message });
            return null;
        });

        // 2. 캐시에 세션이 있으면 캐시 데이터로 유효성 검증
        if (sessionData) {
            const session = JSON.parse(sessionData);
            const isValid = session.status === 'active' && 
                           (session.user_id === userId || session.participants?.includes(userId));
            
            if (isValid) {
                logger.info(`세션 유효성 검증 성공 (캐시): ${sessionId}`, {
                    userId,
                    sessionStatus: session.status,
                    source: 'cache'
                });
            } else {
                logger.warn(`세션 유효성 검증 실패 (캐시): ${sessionId}`, {
                    userId,
                    sessionStatus: session.status,
                    reason: 'invalid_status_or_not_participant'
                });
            }
            
            return isValid;
        }

        // 3. 캐시에 없으면 세션 서비스 API 호출
        logger.debug(`세션 캐시 미스 - API 호출: ${sessionId}`);
        const isValid = await sessionApiService.validateSession(sessionId, userId);
        
        if (isValid) {
            logger.info(`세션 유효성 검증 성공 (API): ${sessionId}`, {
                userId,
                source: 'api'
            });
        } else {
            logger.warn(`세션 유효성 검증 실패 (API): ${sessionId}`, {
                userId,
                source: 'api'
            });
        }

        return isValid;

    } catch (error) {
        logger.error(`세션 유효성 검증 오류: ${sessionId}`, {
            userId,
            error: error.message
        });
        return false;
    }
};

/**
 * 세션 현재 상태 조회
 * @param {string} sessionId - 세션 ID
 * @param {Redis} redisClient - Redis 클라이언트
 * @returns {Promise<Object>} - 세션 상태 정보
 */
const getSessionStatus = async (sessionId, redisClient) => {
    try {
        let shouldUseApi = false;
        let session = null;
        let participants = [];
        let analysis = null;
        
        // 1. Redis에서 세션 기본 정보 조회 (회복성 패턴 적용)
        const sessionKey = `session:${sessionId}`;
        const sessionData = await withRedisResilience(
            async () => redisClient.get(sessionKey),
            { operationName: 'get_session_status' }
        ).catch(error => {
            logger.warn('Redis 세션 조회 실패', { error: error.message });
            shouldUseApi = true;
            return null;
        });
        
        if (sessionData) {
            try {
                session = JSON.parse(sessionData);
            } catch (e) {
                logger.error(`Redis 세션 데이터 파싱 오류: ${e.message}`);
                shouldUseApi = true;
            }
        } else {
            shouldUseApi = true;
        }
        
        // 2. API를 통해 최신 세션 정보 조회 (Redis에 없는 경우)
        if (shouldUseApi) {
            try {
                const sessionInfo = await sessionServiceClient.get(`/api/v1/sessions/${sessionId}/status`, {
                    resilienceOptions: {
                        fallbackKey: 'getSessionStatus',
                        service: 'session',
                        operation: 'getSessionStatus'
                    }
                });
                
                // API 응답 데이터 사용
                session = {
                    status: sessionInfo.status,
                    start_time: sessionInfo.startTime,
                    session_type: sessionInfo.sessionType
                };
                
                participants = sessionInfo.participants || [];
                analysis = sessionInfo.latestAnalysis;
                
                // Redis에 최신 정보 캐싱 (회복성 패턴 적용)
                await withRedisResilience(
                    async () => redisClient.set(sessionKey, JSON.stringify(session), 'EX', SESSION_CACHE_EXPIRY),
                    { operationName: 'cache_session_status' }
                ).catch(error => {
                    logger.warn('세션 상태 캐싱 실패', { error: error.message });
                });
                
                for (const participant of participants) {
                    const participantKey = `session:${sessionId}:participant:${participant.user_id}`;
                    await withRedisResilience(
                        async () => redisClient.set(participantKey, JSON.stringify(participant), 'EX', SESSION_CACHE_EXPIRY),
                        { operationName: 'cache_participant' }
                    ).catch(error => {
                        logger.warn('참가자 캐싱 실패', { error: error.message });
                    });
                }
                
                logger.debug(`세션 ${sessionId} 상태 정보를 Redis에 캐싱했습니다`);
                
                return {
                    sessionId,
                    status: session.status,
                    startTime: session.start_time,
                    sessionType: session.session_type,
                    participants,
                    participantsCount: participants.length,
                    latestAnalysis: analysis
                };
            } catch (apiError) {
                logger.error(`세션 상태 API 조회 오류: ${apiError.message}`);
                // API 조회 실패 시, Redis 정보만으로 최선을 다해 응답
                if (!session) {
                    throw new Error('세션을 찾을 수 없습니다');
                }
            }
        }
        
        // 3. Redis에서 참가자 목록 조회 (API 조회에 실패했거나 Redis 정보를 주로 사용하는 경우)
        if (participants.length === 0) {
            const participantPattern = `session:${sessionId}:participant:*`;
            const participantKeys = await withRedisResilience(
                async () => redisClient.keys(participantPattern),
                { operationName: 'get_participant_keys' }
            ).catch(error => {
                logger.warn('참가자 키 조회 실패', { error: error.message });
                return [];
            });
            
            for (const key of participantKeys) {
                const participantData = await withRedisResilience(
                    async () => redisClient.get(key),
                    { operationName: 'get_participant_data' }
                ).catch(error => {
                    logger.warn('참가자 데이터 조회 실패', { error: error.message });
                    return null;
                });
                
                if (participantData) {
                    try {
                        participants.push(JSON.parse(participantData));
                    } catch (e) {
                        logger.error(`참가자 데이터 파싱 오류: ${e.message}`);
                    }
                }
            }
        }
        
        // 4. Redis에서 최신 분석 결과 조회
        if (!analysis) {
            const analysisKey = `analysis:latest:${sessionId}`;
            const analysisData = await withRedisResilience(
                async () => redisClient.get(analysisKey),
                { operationName: 'get_latest_analysis' }
            ).catch(error => {
                logger.warn('분석 데이터 조회 실패', { error: error.message });
                return null;
            });
            
            if (analysisData) {
                try {
                    analysis = JSON.parse(analysisData);
                } catch (e) {
                    logger.error(`분석 데이터 파싱 오류: ${e.message}`);
                }
            }
        }
        
        return {
            sessionId,
            status: session.status,
            startTime: session.start_time,
            sessionType: session.session_type,
            participants,
            participantsCount: participants.length,
            latestAnalysis: analysis
        };
    } catch (error) {
        logger.error(`세션 상태 조회 오류: ${error.message}`);
        throw error;
    }
};

/**
 * 실시간 세션 참가자 추가
 * @param {string} sessionId - 세션 ID
 * @param {string} userId - 사용자 ID
 * @param {Object} connectionInfo - 연결 정보
 * @param {Redis} redisClient - Redis 클라이언트
 * @returns {Promise<boolean>} - 참가자 추가 성공 여부
 */
const addParticipant = async (sessionId, userId, connectionInfo, redisClient) => {
    try {
        // 1. 세션 유효성 먼저 검증
        const isValidSession = await validateSession(sessionId, userId, redisClient);
        if (!isValidSession) {
            logger.warn(`참가자 추가 실패 - 유효하지 않은 세션: ${sessionId}`, {
                userId
            });
            return false;
        }

        // 2. Redis에 참가자 정보 저장
        const participantKey = `session:${sessionId}:participants`;
        const participantData = {
            userId,
            joinedAt: new Date().toISOString(),
            connectionInfo,
            isActive: true
        };

        await withRedisResilience(
            async () => redisClient.hset(participantKey, userId, JSON.stringify(participantData)),
            { operationName: 'add_participant' }
        );

        // 3. 세션 서비스에 참가자 추가 알림
        try {
            await sessionApiService.addParticipant(sessionId, userId);
            logger.info(`참가자 추가 성공: ${sessionId}`, {
                userId,
                participantCount: await getParticipantCount(sessionId, redisClient)
            });
        } catch (apiError) {
            logger.warn('세션 서비스 참가자 추가 알림 실패', {
                sessionId,
                userId,
                error: apiError.message
            });
        }

        return true;

    } catch (error) {
        logger.error(`참가자 추가 오류: ${sessionId}`, {
            userId,
            error: error.message
        });
        return false;
    }
};

/**
 * 실시간 세션 참가자 제거
 * @param {string} sessionId - 세션 ID
 * @param {string} userId - 사용자 ID
 * @param {Redis} redisClient - Redis 클라이언트
 * @returns {Promise<boolean>} - 참가자 제거 성공 여부
 */
const removeParticipant = async (sessionId, userId, redisClient) => {
    try {
        // 1. Redis에서 참가자 정보 제거
        const participantKey = `session:${sessionId}:participants`;
        const removed = await withRedisResilience(
            async () => redisClient.hdel(participantKey, userId),
            { operationName: 'remove_participant' }
        );

        if (removed) {
            logger.info(`참가자 제거 성공: ${sessionId}`, {
                userId,
                remainingParticipants: await getParticipantCount(sessionId, redisClient)
            });
        } else {
            logger.warn(`참가자 제거 실패 - 존재하지 않는 참가자: ${sessionId}`, {
                userId
            });
        }

        // 2. 세션 서비스에 참가자 제거 알림
        try {
            await sessionApiService.removeParticipant(sessionId, userId);
        } catch (apiError) {
            logger.warn('세션 서비스 참가자 제거 알림 실패', {
                sessionId,
                userId,
                error: apiError.message
            });
        }

        return !!removed;

    } catch (error) {
        logger.error(`참가자 제거 오류: ${sessionId}`, {
            userId,
            error: error.message
        });
        return false;
    }
};

module.exports = {validateSession, getSessionStatus, addParticipant, removeParticipant};

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

        if (sessionData) {
            const session = JSON.parse(sessionData);

            // 세션 상태 확인
            if (session.status !== 'active') {
                logger.warn(`활성 상태가 아닌 세션: ${sessionId}, 현재 상태: ${session.status}`);
                return false;
            }

            // 사용자가 세션 소유자인 경우
            if (session.user_id === userId) {
                return true;
            }

            // 초대된 참가자 확인 (회복성 패턴 적용)
            const participantKey = `session:${sessionId}:participant:${userId}`;
            const participantData = await withRedisResilience(
                async () => redisClient.get(participantKey),
                { operationName: 'get_participant_cache' }
            ).catch(error => {
                logger.warn('참가자 정보 Redis 조회 실패', { error: error.message });
                return null;
            });
            
            if (participantData) {
                return true;
            }
        }

        // 2. Redis에 없는 경우 세션 서비스 API를 통해 검증 (회복성 패턴 적용)
        logger.info(`Redis에 세션 ${sessionId} 정보가 없어 API 호출로 검증합니다`);
        
        const isValid = await sessionServiceClient.get(`/api/v1/sessions/${sessionId}/validate/${userId}`, {
            resilienceOptions: {
                fallbackKey: 'validateSession',
                service: 'session',
                operation: 'validateSession'
            }
        }).catch(error => {
            logger.error('세션 검증 API 호출 실패', { error: error.message });
            return false;
        });
        
        if (isValid) {
            // API 검증 결과가 유효할 경우, Redis에 세션 정보 캐싱
            try {
                const sessionInfo = await sessionServiceClient.get(`/api/v1/sessions/${sessionId}`, {
                    resilienceOptions: {
                        fallbackKey: 'getSession',
                        service: 'session',
                        operation: 'getSession'
                    }
                });

                await withRedisResilience(
                    async () => redisClient.set(sessionKey, JSON.stringify({
                        status: sessionInfo.status,
                        user_id: sessionInfo.user_id,
                        session_type: sessionInfo.type,
                        start_time: sessionInfo.created_at
                    }), 'EX', SESSION_CACHE_EXPIRY),
                    { operationName: 'cache_session_info' }
                ).catch(error => {
                    logger.warn('세션 정보 캐싱 실패', { error: error.message });
                });
                
                if (sessionInfo.participants) {
                    // 참가자 정보도 캐싱
                    for (const participant of sessionInfo.participants) {
                        const participantKey = `session:${sessionId}:participant:${participant.user_id}`;
                        await withRedisResilience(
                            async () => redisClient.set(participantKey, JSON.stringify(participant), 'EX', SESSION_CACHE_EXPIRY),
                            { operationName: 'cache_participant_info' }
                        ).catch(error => {
                            logger.warn('참가자 정보 캐싱 실패', { error: error.message });
                        });
                    }
                }
                
                logger.debug(`세션 ${sessionId} 정보를 Redis에 캐싱했습니다`);
            } catch (cacheError) {
                logger.error(`세션 정보 캐싱 오류: ${cacheError.message}`);
                // 캐싱 실패는 무시하고 계속 진행
            }
        }
        
        return isValid;
    } catch (error) {
        logger.error(`세션 검증 오류: ${error.message}`);
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

module.exports = {validateSession, getSessionStatus};

const {redisUtils} = require('../config/redis');
const logger = require('../utils/logger');

/**
 * 타이머 서비스 클래스
 * 발표 타이머 관리 기능 제공
 */
class TimerService {
    /**
     * 타이머 시작
     * @param {string} sessionId 세션 ID
     * @returns {Promise<Object>} 타이머 정보
     */
    async startTimer(sessionId) {
        try {
            // Redis에서 타이머 설정 가져오기
            const timerData = await redisUtils.get(redisUtils.keys.sessionTimer(sessionId));

            if (!timerData) {
                throw new Error(`Timer not found for session: ${sessionId}`);
            }

            // 이미 시작된 타이머인지 확인
            if (timerData.status === 'running') {
                return timerData;
            }

            // 타이머 시작 시간 및 예상 종료 시간 설정
            const startTime = new Date();
            const endTime = new Date(startTime.getTime() + (timerData.duration_seconds * 1000));

            const updatedTimerData = {
                ...timerData,
                start_time: startTime.toISOString(),
                end_time: endTime.toISOString(),
                status: 'running',
                alerts_triggered: {} // 알림 트리거 상태 초기화
            };

            // Redis에 업데이트된 타이머 정보 저장
            await redisUtils.set(
                redisUtils.keys.sessionTimer(sessionId),
                updatedTimerData,
                86400 // 24시간 TTL
            );

            logger.info(`Timer started for session ${sessionId}, duration: ${timerData.duration_seconds}s`);
            return updatedTimerData;
        } catch (error) {
            logger.error(`Error starting timer for session ${sessionId}:`, error);
            throw error;
        }
    }

    /**
     * 타이머 일시 중지
     * @param {string} sessionId 세션 ID
     * @returns {Promise<Object>} 타이머 정보
     */
    async pauseTimer(sessionId) {
        try {
            // Redis에서 타이머 설정 가져오기
            const timerData = await redisUtils.get(redisUtils.keys.sessionTimer(sessionId));

            if (!timerData) {
                throw new Error(`Timer not found for session: ${sessionId}`);
            }

            // 실행 중인 타이머가 아니면 에러
            if (timerData.status !== 'running') {
                throw new Error('Timer is not running');
            }

            // 경과 시간 계산
            const startTime = new Date(timerData.start_time);
            const now = new Date();
            const elapsedSeconds = Math.floor((now - startTime) / 1000);
            const remainingSeconds = timerData.duration_seconds - elapsedSeconds;

            const updatedTimerData = {
                ...timerData,
                status: 'paused',
                remaining_seconds: remainingSeconds > 0 ? remainingSeconds : 0,
                paused_at: now.toISOString()
            };

            // Redis에 업데이트된 타이머 정보 저장
            await redisUtils.set(
                redisUtils.keys.sessionTimer(sessionId),
                updatedTimerData,
                86400 // 24시간 TTL
            );

            logger.info(`Timer paused for session ${sessionId}, remaining: ${remainingSeconds}s`);
            return updatedTimerData;
        } catch (error) {
            logger.error(`Error pausing timer for session ${sessionId}:`, error);
            throw error;
        }
    }

    /**
     * 타이머 재개
     * @param {string} sessionId 세션 ID
     * @returns {Promise<Object>} 타이머 정보
     */
    async resumeTimer(sessionId) {
        try {
            // Redis에서 타이머 설정 가져오기
            const timerData = await redisUtils.get(redisUtils.keys.sessionTimer(sessionId));

            if (!timerData) {
                throw new Error(`Timer not found for session: ${sessionId}`);
            }

            // 일시 중지된 타이머가 아니면 에러
            if (timerData.status !== 'paused') {
                throw new Error('Timer is not paused');
            }

            // 새로운 종료 시간 계산
            const now = new Date();
            const endTime = new Date(now.getTime() + (timerData.remaining_seconds * 1000));

            const updatedTimerData = {
                ...timerData,
                start_time: now.toISOString(),
                end_time: endTime.toISOString(),
                status: 'running',
                remaining_seconds: undefined,
                paused_at: undefined
            };

            // Redis에 업데이트된 타이머 정보 저장
            await redisUtils.set(
                redisUtils.keys.sessionTimer(sessionId),
                updatedTimerData,
                86400 // 24시간 TTL
            );

            logger.info(`Timer resumed for session ${sessionId}`);
            return updatedTimerData;
        } catch (error) {
            logger.error(`Error resuming timer for session ${sessionId}:`, error);
            throw error;
        }
    }

    /**
     * 타이머 리셋
     * @param {string} sessionId 세션 ID
     * @returns {Promise<Object>} 타이머 정보
     */
    async resetTimer(sessionId) {
        try {
            // Redis에서 타이머 설정 가져오기
            const timerData = await redisUtils.get(redisUtils.keys.sessionTimer(sessionId));

            if (!timerData) {
                throw new Error(`Timer not found for session: ${sessionId}`);
            }

            // 기본 타이머 설정으로 리셋
            const resetTimerData = {
                duration_seconds: timerData.duration_seconds,
                alerts: timerData.alerts,
                start_time: null,
                end_time: null,
                status: 'ready',
                alerts_triggered: {}
            };

            // Redis에 업데이트된 타이머 정보 저장
            await redisUtils.set(
                redisUtils.keys.sessionTimer(sessionId),
                resetTimerData,
                86400 // 24시간 TTL
            );

            logger.info(`Timer reset for session ${sessionId}`);
            return resetTimerData;
        } catch (error) {
            logger.error(`Error resetting timer for session ${sessionId}:`, error);
            throw error;
        }
    }

    /**
     * 타이머 상태 조회
     * @param {string} sessionId 세션 ID
     * @returns {Promise<Object>} 타이머 정보 및 현재 상태
     */
    async getTimerStatus(sessionId) {
        try {
            // Redis에서 타이머 설정 가져오기
            const timerData = await redisUtils.get(redisUtils.keys.sessionTimer(sessionId));

            if (!timerData) {
                throw new Error(`Timer not found for session: ${sessionId}`);
            }

            // 실행 중인 타이머인 경우 남은 시간 계산
            if (timerData.status === 'running') {
                const now = new Date();
                const endTime = new Date(timerData.end_time);

                // 남은 시간 (초)
                const remainingSeconds = Math.max(0, Math.floor((endTime - now) / 1000));

                // 진행률 (%)
                const totalSeconds = timerData.duration_seconds;
                const elapsedSeconds = totalSeconds - remainingSeconds;
                const progressPercent = Math.min(100, Math.floor((elapsedSeconds / totalSeconds) * 100));

                // 알림 포인트 확인 및 업데이트
                const alerts = timerData.alerts || {};
                const alertsTriggered = timerData.alerts_triggered || {};

                // 절반 지점 알림
                if (alerts.halfway && !alertsTriggered.halfway && progressPercent >= 50) {
                    alertsTriggered.halfway = true;
                }

                // 5분 남음 알림
                if (alerts.five_minutes && !alertsTriggered.five_minutes && remainingSeconds <= 300) {
                    alertsTriggered.five_minutes = true;
                }

                // 2분 남음 알림
                if (alerts.two_minutes && !alertsTriggered.two_minutes && remainingSeconds <= 120) {
                    alertsTriggered.two_minutes = true;
                }

                // 30초 남음 알림
                if (alerts.thirty_seconds && !alertsTriggered.thirty_seconds && remainingSeconds <= 30) {
                    alertsTriggered.thirty_seconds = true;
                }

                // 타이머 종료 체크
                let status = timerData.status;
                if (remainingSeconds === 0) {
                    status = 'ended';
                    alertsTriggered.ended = true;
                }

                // 알림 트리거가 업데이트되었으면 Redis 업데이트
                if (JSON.stringify(alertsTriggered) !== JSON.stringify(timerData.alerts_triggered)) {
                    const updatedTimerData = {
                        ...timerData,
                        alerts_triggered: alertsTriggered,
                        status
                    };

                    await redisUtils.set(
                        redisUtils.keys.sessionTimer(sessionId),
                        updatedTimerData,
                        86400 // 24시간 TTL
                    );
                }

                // 상태 반환
                return {
                    ...timerData,
                    remaining_seconds: remainingSeconds,
                    progress_percent: progressPercent,
                    elapsed_seconds: elapsedSeconds,
                    alerts_triggered: alertsTriggered,
                    status
                };
            }

            // 일시 중지 상태이면 남은 시간 정보 추가
            if (timerData.status === 'paused') {
                const totalSeconds = timerData.duration_seconds;
                const remainingSeconds = timerData.remaining_seconds || 0;
                const elapsedSeconds = totalSeconds - remainingSeconds;
                const progressPercent = Math.min(100, Math.floor((elapsedSeconds / totalSeconds) * 100));

                return {
                    ...timerData,
                    progress_percent: progressPercent,
                    elapsed_seconds: elapsedSeconds
                };
            }

            // 그 외의 상태는 그대로 반환
            return timerData;
        } catch (error) {
            logger.error(`Error getting timer status for session ${sessionId}:`, error);
            throw error;
        }
    }
}

module.exports = new TimerService();
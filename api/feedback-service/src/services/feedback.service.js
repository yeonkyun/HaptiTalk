const HapticPattern = require('../models/pattern.model');
const { getUserSettings } = require('./setting.service');
const { saveFeedbackHistory } = require('./mongodb.service');
const { getSessionAnalytics } = require('./mongodb.service');
const Redis = require('ioredis');
const logger = require('../utils/logger');

// Redis 클라이언트 초기화
const redisClient = new Redis({
    host: process.env.REDIS_HOST || 'redis',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD
});

/**
 * 실시간 피드백 생성
 */
const generateFeedback = async (params) => {
    const { userId, sessionId, context, deviceId, timestamp } = params;

    try {
        // 1. 사용자 피드백 설정 조회
        const userSettings = await getUserSettings(userId);

        // 2. 피드백 생성 전 이전 피드백과의 간격 확인
        const shouldSendFeedback = await checkFeedbackInterval(userId, userSettings.minimum_interval_seconds);
        if (!shouldSendFeedback) {
            return null; // 최소 간격이 지나지 않았으면 피드백 생성하지 않음
        }

        // 3. 세션 분석 데이터 조회 (컨텍스트 개선)
        const sessionAnalytics = await getSessionAnalytics(sessionId);
        const enhancedContext = enhanceContext(context, sessionAnalytics);

        // 4. 피드백 결정 (가장 적절한 햅틱 패턴 선택)
        const feedbackDecision = decideFeedback(enhancedContext, userSettings);
        if (!feedbackDecision) {
            return null; // 적절한 피드백이 없음
        }

        // 5. 햅틱 패턴 데이터 조회
        const pattern = await HapticPattern.findByPk(feedbackDecision.patternId);
        if (!pattern || !pattern.is_active) {
            return null; // 패턴이 없거나 비활성화됨
        }

        // 6. 햅틱 데이터 구성
        const hapticData = {
            pattern: pattern.pattern_data,
            intensity: userSettings.haptic_strength,
            duration_ms: pattern.duration_ms
        };

        // 7. 피드백 데이터 구성
        const feedback = {
            id: generateUniqueId(),
            type: feedbackDecision.type,
            pattern_id: pattern.id,
            priority: feedbackDecision.priority,
            haptic_data: hapticData,
            message: feedbackDecision.message,
            visual_cue: feedbackDecision.visualCue
        };

        // 8. 피드백 이력 저장 (비동기)
        const feedbackHistoryData = {
            sessionId,
            userId,
            device_id: deviceId,
            pattern_id: pattern.id,
            feedback_type: feedbackDecision.type,
            intensity: userSettings.haptic_strength,
            trigger: feedbackDecision.trigger,
            delivery: {
                sent: true,
                received: false
            },
            context: enhancedContext,
            timestamp
        };

        saveFeedbackHistory(feedbackHistoryData)
            .then(id => {
                feedback.history_id = id;
            })
            .catch(err => {
                logger.error('Error saving feedback history:', err);
            });

        // 9. 마지막 피드백 시간 업데이트 (Redis)
        await redisClient.set(`feedback:last:${userId}`, new Date().toISOString());

        return feedback;
    } catch (error) {
        logger.error('Error in generateFeedback:', error);
        throw error;
    }
};

/**
 * 피드백 간격 체크
 */
const checkFeedbackInterval = async (userId, minimumIntervalSeconds) => {
    try {
        const lastFeedbackTime = await redisClient.get(`feedback:last:${userId}`);
        if (!lastFeedbackTime) {
            return true; // 이전 피드백이 없으면 즉시 전송 가능
        }

        const now = new Date();
        const last = new Date(lastFeedbackTime);
        const diffSeconds = (now - last) / 1000;

        return diffSeconds >= minimumIntervalSeconds;
    } catch (error) {
        logger.error(`Error in checkFeedbackInterval for userId ${userId}:`, error);
        return true; // 오류 발생 시 기본적으로 피드백 허용
    }
};

/**
 * 컨텍스트 개선
 */
const enhanceContext = (context, sessionAnalytics) => {
    const enhancedContext = { ...context };

    if (sessionAnalytics) {
        // 세션 분석 데이터로 컨텍스트 보강
        // 예: 장기적인 트렌드, 이전 감정 상태 등
    }

    return enhancedContext;
};

/**
 * 피드백 결정 알고리즘
 */
const decideFeedback = (context, userSettings) => {
    // 각 피드백 유형에 대한 점수 계산
    const scores = {
        speaking_pace: calculateSpeakingPaceScore(context),
        volume: calculateVolumeScore(context),
        interest_level: calculateInterestScore(context),
        silence: calculateSilenceScore(context)
    };

    // 가장 높은 점수의 피드백 유형 선택
    let maxType = null;
    let maxScore = 0;

    for (const [type, score] of Object.entries(scores)) {
        if (score.score > maxScore) {
            maxScore = score.score;
            maxType = type;
        }
    }

    // 임계값 이상인 경우만 피드백 전송
    if (maxScore < 0.5) {
        return null;
    }

    // 피드백 유형별 설정 및 메시지
    const feedbackConfig = {
        speaking_pace: {
            patternId: 'S1',
            priority: 'high',
            message: '말하기 속도가 빠릅니다. 조금 천천히 말해보세요.',
            visualCue: 'speed_warning',
            trigger: {
                type: 'analysis_result',
                value: 'speaking_pace_too_fast',
                confidence: maxScore
            }
        },
        volume: {
            patternId: 'S2',
            priority: 'medium',
            message: context.current_volume > 70 ? '목소리가 큽니다. 조금 낮추어 보세요.' : '목소리가 작습니다. 조금 크게 말해보세요.',
            visualCue: 'volume_warning',
            trigger: {
                type: 'analysis_result',
                value: context.current_volume > 70 ? 'volume_too_high' : 'volume_too_low',
                confidence: maxScore
            }
        },
        interest_level: {
            patternId: context.interest_level > 0.7 ? 'R1' : 'R2',
            priority: 'medium',
            message: context.interest_level > 0.7 ? '상대방이 관심을 보입니다.' : '상대방의 관심도가 낮아지고 있습니다.',
            visualCue: context.interest_level > 0.7 ? 'interest_high' : 'interest_low',
            trigger: {
                type: 'analysis_result',
                value: context.interest_level > 0.7 ? 'interest_increase' : 'interest_decrease',
                confidence: maxScore
            }
        },
        silence: {
            patternId: 'F2',
            priority: 'high',
            message: '침묵이 길어지고 있습니다. 새로운 주제를 시작해보세요.',
            visualCue: 'silence_warning',
            trigger: {
                type: 'analysis_result',
                value: 'silence_too_long',
                confidence: maxScore
            }
        }
    };

    // 선택된 피드백 유형의 설정 반환
    return maxType ? { type: maxType, ...feedbackConfig[maxType] } : null;
};

/**
 * 말하기 속도 점수 계산
 */
const calculateSpeakingPaceScore = (context) => {
    const { current_speaking_pace } = context;

    // 말하기 속도가 너무 빠르면 높은 점수
    if (current_speaking_pace > 4.0) {
        return {
            score: (current_speaking_pace - 4.0) * 0.5,
            data: { threshold: 4.0, value: current_speaking_pace }
        };
    }

    return { score: 0, data: null };
};

/**
 * 음량 점수 계산
 */
const calculateVolumeScore = (context) => {
    const { current_volume } = context;

    // 음량이 너무 크거나 작으면 높은 점수
    if (current_volume > 80) {
        return {
            score: (current_volume - 80) * 0.05,
            data: { threshold: 80, value: current_volume, type: 'high' }
        };
    } else if (current_volume < 40) {
        return {
            score: (40 - current_volume) * 0.05,
            data: { threshold: 40, value: current_volume, type: 'low' }
        };
    }

    return { score: 0, data: null };
};

/**
 * 관심도 점수 계산
 */
const calculateInterestScore = (context) => {
    const { interest_level, previous_interest_level } = context;

    // 관심도가 크게 변했을 때 높은 점수
    if (previous_interest_level && Math.abs(interest_level - previous_interest_level) > 0.2) {
        return {
            score: Math.abs(interest_level - previous_interest_level),
            data: { current: interest_level, previous: previous_interest_level }
        };
    }

    return { score: 0, data: null };
};

/**
 * 침묵 점수 계산
 */
const calculateSilenceScore = (context) => {
    const { silence_duration } = context;

    // 침묵이 길수록 높은 점수
    if (silence_duration > 5) {
        return {
            score: (silence_duration - 5) * 0.1,
            data: { threshold: 5, value: silence_duration }
        };
    }

    return { score: 0, data: null };
};

/**
 * 유니크 ID 생성
 */
const generateUniqueId = () => {
    return 'f' + Math.random().toString(36).substr(2, 9);
};

/**
 * 피드백 수신 확인
 */
const acknowledgeFeedback = async (feedbackId, data) => {
    try {
        // MongoDB에서 피드백 이력 업데이트
        const collection = getCollection('hapticFeedbacks');
        await collection.updateOne(
            { _id: feedbackId },
            {
                $set: {
                    'delivery.received': true,
                    'delivery.receivedAt': data.receivedAt
                }
            }
        );

        return true;
    } catch (error) {
        logger.error(`Error in acknowledgeFeedback for id ${feedbackId}:`, error);
        throw error;
    }
};

module.exports = {
    generateFeedback,
    acknowledgeFeedback
};
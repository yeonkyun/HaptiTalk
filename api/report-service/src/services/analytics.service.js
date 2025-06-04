const { getDb } = require('../config/mongodb');
const logger = require('../utils/logger');

// NaN과 Infinity 값을 안전한 값으로 변환하는 함수
const sanitizeValue = (value, defaultValue = 0) => {
    if (value === null || value === undefined || Number.isNaN(value) || !Number.isFinite(value)) {
        return defaultValue;
    }
    return value;
};

// 객체의 모든 숫자 값을 안전하게 변환하는 함수
const sanitizeData = (obj) => {
    if (obj === null || obj === undefined) return null;
    if (typeof obj === 'number') {
        return sanitizeValue(obj);
    }
    if (Array.isArray(obj)) {
        return obj.map(sanitizeData);
    }
    if (typeof obj === 'object') {
        const sanitized = {};
        for (const [key, value] of Object.entries(obj)) {
            sanitized[key] = sanitizeData(value);
        }
        return sanitized;
    }
    return obj;
};

/**
 * 세그먼트 데이터를 MongoDB에 저장
 */
const saveSegment = async (segmentData) => {
    try {
        const db = await getDb();
        const collection = db.collection('sessionSegments');

        // 중복 체크를 위한 upsert 사용
        const result = await collection.replaceOne(
            { 
                sessionId: segmentData.sessionId, 
                segmentIndex: segmentData.segmentIndex 
            },
            {
                ...segmentData,
                createdAt: new Date(),
                updatedAt: new Date()
            },
            { upsert: true }
        );

        logger.info(`세그먼트 저장 완료: sessionId=${segmentData.sessionId}, segmentIndex=${segmentData.segmentIndex}, upserted=${result.upsertedCount > 0}`);

        return result;

    } catch (error) {
        logger.error(`세그먼트 저장 실패: ${error.message}`, { segmentData, error: error.stack });
        throw error;
    }
};

/**
 * 세션의 모든 세그먼트 조회
 */
const getSegmentsBySession = async (sessionId, userId) => {
    try {
        const db = await getDb();
        const collection = db.collection('sessionSegments');

        const segments = await collection
            .find({ 
                sessionId: sessionId,
                userId: userId 
            })
            .sort({ segmentIndex: 1 })
            .toArray();

        logger.info(`세그먼트 조회 완료: sessionId=${sessionId}, count=${segments.length}`);

        return segments;

    } catch (error) {
        logger.error(`세그먼트 조회 실패: ${error.message}`, { sessionId, userId, error: error.stack });
        throw error;
    }
};

/**
 * 세그먼트 데이터 업데이트
 */
const updateSegment = async (sessionId, segmentIndex, userId, updateData) => {
    try {
        const db = await getDb();
        const collection = db.collection('sessionSegments');

        const result = await collection.updateOne(
            { 
                sessionId: sessionId,
                segmentIndex: segmentIndex,
                userId: userId
            },
            { 
                $set: {
                    ...updateData,
                    updatedAt: new Date()
                }
            }
        );

        logger.info(`세그먼트 업데이트 완료: sessionId=${sessionId}, segmentIndex=${segmentIndex}, modified=${result.modifiedCount}`);

        return result.modifiedCount > 0;

    } catch (error) {
        logger.error(`세그먼트 업데이트 실패: ${error.message}`, { sessionId, segmentIndex, userId, updateData, error: error.stack });
        throw error;
    }
};

/**
 * 모든 세그먼트를 종합하여 sessionAnalytics 생성
 */
const generateSessionAnalytics = async (sessionId, userId, sessionType, segments, totalDuration) => {
    try {
        logger.info(`sessionAnalytics 생성 시작: sessionId=${sessionId}, userId=${userId}, sessionType=${sessionType}, segments=${segments.length}`);
        
        const db = await getDb();
        const collection = db.collection('sessionAnalytics');

        // 🔥 데이터 유효성 검사
        if (!Array.isArray(segments)) {
            logger.error(`잘못된 segments 데이터 타입: ${typeof segments}`);
            throw new Error('segments는 배열이어야 합니다');
        }

        if (segments.length === 0) {
            logger.warn(`세그먼트가 비어있음: sessionId=${sessionId}`);
            // 빈 세그먼트에 대한 기본 analytics 생성
            const emptyAnalytics = createEmptyAnalytics(sessionId, userId, sessionType, totalDuration);
            const result = await collection.replaceOne(
                { sessionId: sessionId },
                sanitizeData(emptyAnalytics),
                { upsert: true }
            );
            logger.info(`빈 sessionAnalytics 생성 완료: sessionId=${sessionId}`);
            return emptyAnalytics;
        }

        // 🔥 단계별 분석 진행 (에러 발생 지점 추적)
        let analytics;
        try {
            logger.info(`1단계: analyzeSegments 시작`);
            analytics = analyzeSegments(segments, sessionType, totalDuration);
            logger.info(`1단계: analyzeSegments 완료`);
        } catch (error) {
            logger.error(`analyzeSegments 실패: ${error.message}`, { sessionId, error: error.stack });
            throw new Error(`세그먼트 분석 중 오류: ${error.message}`);
        }

        // sessionAnalytics 컬렉션에 저장
        const sessionAnalytics = {
            sessionId: sessionId,
            userId: userId,
            sessionType: sessionType,
            createdAt: new Date(),
            summary: analytics.summary,
            statistics: analytics.statistics,
            timeline: analytics.timeline,
            suggestions: analytics.suggestions,
            specializedAnalysis: analytics.specializedAnalysis
        };

        try {
            logger.info(`2단계: sanitizeData 시작`);
            const sanitizedData = sanitizeData(sessionAnalytics);
            logger.info(`2단계: sanitizeData 완료`);

            logger.info(`3단계: MongoDB 저장 시작`);
            const result = await collection.replaceOne(
                { sessionId: sessionId },
                sanitizedData,
                { upsert: true }
            );
            logger.info(`3단계: MongoDB 저장 완료: sessionId=${sessionId}, upserted=${result.upsertedCount > 0}`);

        } catch (error) {
            logger.error(`데이터 정제 또는 MongoDB 저장 실패: ${error.message}`, { sessionId, error: error.stack });
            throw new Error(`데이터 저장 중 오류: ${error.message}`);
        }

        return sessionAnalytics;

    } catch (error) {
        logger.error(`sessionAnalytics 생성 실패: ${error.message}`, { sessionId, userId, sessionType, error: error.stack });
        throw error;
    }
};

/**
 * 빈 세그먼트를 위한 기본 analytics 생성
 */
const createEmptyAnalytics = (sessionId, userId, sessionType, totalDuration) => {
    return {
        sessionId: sessionId,
        userId: userId,
        sessionType: sessionType,
        createdAt: new Date(),
        summary: {
            duration: totalDuration || 0,
            totalSegments: 0,
            userSpeakingRatio: 0,
            averageSpeakingSpeed: 0,
            emotionScores: { positive: 0.5, neutral: 0.5, negative: 0 },
            keyInsights: ['세션 데이터가 충분하지 않습니다.'],
            wordsCount: 0
        },
        statistics: {
            question_answer_ratio: 0,
            interruptions: 0,
            silence_periods: [],
            habitual_phrases: [],
            speaking_rate_variance: 0
        },
        timeline: [],
        suggestions: ['더 많은 대화를 시도해보세요.', '마이크 상태를 확인해보세요.'],
        specializedAnalysis: {
            type: '기본 분석',
            communication_effectiveness: '데이터 부족',
            key_strengths: [],
            improvement_areas: ['더 긴 세션 진행']
        }
    };
};

/**
 * 세그먼트 데이터를 분석하여 종합 결과 생성
 */
const analyzeSegments = (segments, sessionType, totalDuration) => {
    try {
        logger.info(`analyzeSegments 시작: segments=${segments.length}, sessionType=${sessionType}`);
        
        const totalSegments = segments.length;
        const estimatedDuration = totalDuration || (totalSegments * 30); // 30초 단위

        // 1. 기본 통계 계산
        let statistics;
        try {
            logger.info(`1-1: calculateBasicStatistics 시작`);
            statistics = calculateBasicStatistics(segments);
            logger.info(`1-1: calculateBasicStatistics 완료`);
        } catch (error) {
            logger.error(`calculateBasicStatistics 실패: ${error.message}`);
            statistics = getDefaultStatistics();
        }

        // 2. 감정 분석
        let emotionAnalysis;
        try {
            logger.info(`1-2: analyzeEmotions 시작`);
            emotionAnalysis = analyzeEmotions(segments);
            logger.info(`1-2: analyzeEmotions 완료`);
        } catch (error) {
            logger.error(`analyzeEmotions 실패: ${error.message}`);
            emotionAnalysis = { averageScores: { positive: 0.5, neutral: 0.5, negative: 0 } };
        }

        // 3. 타임라인 생성
        let timeline;
        try {
            logger.info(`1-3: generateTimeline 시작`);
            timeline = generateTimeline(segments);
            logger.info(`1-3: generateTimeline 완료`);
        } catch (error) {
            logger.error(`generateTimeline 실패: ${error.message}`);
            timeline = [];
        }

        // 4. 추천사항 생성
        let suggestions;
        try {
            logger.info(`1-4: generateSuggestions 시작`);
            suggestions = generateSuggestions(segments, sessionType, statistics);
            logger.info(`1-4: generateSuggestions 완료`);
        } catch (error) {
            logger.error(`generateSuggestions 실패: ${error.message}`);
            suggestions = ['더 적극적으로 대화에 참여해보세요.', '감정을 적절히 표현하며 대화하세요.'];
        }

        // 5. 전문화된 분석
        let specializedAnalysis;
        try {
            logger.info(`1-5: generateSpecializedAnalysis 시작`);
            specializedAnalysis = generateSpecializedAnalysis(segments, sessionType);
            logger.info(`1-5: generateSpecializedAnalysis 완료`);
        } catch (error) {
            logger.error(`generateSpecializedAnalysis 실패: ${error.message}`);
            specializedAnalysis = {
                type: '기본 분석',
                communication_effectiveness: '보통',
                key_strengths: ['적극적 참여'],
                improvement_areas: ['다양한 표현 사용']
            };
        }

        // 6. 핵심 인사이트 생성
        let keyInsights;
        try {
            logger.info(`1-6: generateKeyInsights 시작`);
            keyInsights = generateKeyInsights(statistics, emotionAnalysis);
            logger.info(`1-6: generateKeyInsights 완료`);
        } catch (error) {
            logger.error(`generateKeyInsights 실패: ${error.message}`);
            keyInsights = ['분석 데이터를 수집 중입니다.'];
        }

        const result = {
            summary: {
                duration: estimatedDuration,
                totalSegments: totalSegments,
                userSpeakingRatio: statistics.speakingRatio,
                averageSpeakingSpeed: statistics.averageSpeakingSpeed,
                emotionScores: emotionAnalysis.averageScores,
                keyInsights: keyInsights,
                wordsCount: statistics.totalWords
            },
            statistics: {
                question_answer_ratio: statistics.questionAnswerRatio,
                interruptions: statistics.interruptions,
                silence_periods: statistics.silencePeriods,
                habitual_phrases: statistics.habitualPhrases,
                speaking_rate_variance: statistics.speakingRateVariance
            },
            timeline: timeline,
            suggestions: suggestions,
            specializedAnalysis: specializedAnalysis
        };

        logger.info(`analyzeSegments 완료`);
        return result;

    } catch (error) {
        logger.error(`analyzeSegments 최상위 에러: ${error.message}`, { error: error.stack });
        throw error;
    }
};

/**
 * 기본 통계 계산
 */
const calculateBasicStatistics = (segments) => {
    const validSegments = segments.filter(s => s.analysis && s.transcription);
    
    if (validSegments.length === 0) {
        return getDefaultStatistics();
    }

    const speakingSpeeds = validSegments
        .map(s => s.analysis.speakingSpeed)
        .filter(speed => speed && speed > 0);

    const totalWords = validSegments
        .map(s => s.transcription ? s.transcription.split(' ').length : 0)
        .reduce((sum, count) => sum + count, 0);

    const averageSpeakingSpeed = speakingSpeeds.length > 0 
        ? sanitizeValue(Math.round(speakingSpeeds.reduce((sum, speed) => sum + speed, 0) / speakingSpeeds.length), 120)
        : 120; // 기본값

    const speakingRatio = validSegments.length > 0 
        ? sanitizeValue(validSegments.filter(s => s.transcription && s.transcription.trim().length > 0).length / validSegments.length, 0.5)
        : 0.5;

    return {
        speakingRatio: sanitizeValue(Math.round(speakingRatio * 100) / 100, 0.5),
        averageSpeakingSpeed: averageSpeakingSpeed,
        totalWords: sanitizeValue(totalWords, 0),
        questionAnswerRatio: calculateQuestionAnswerRatio(validSegments),
        interruptions: calculateInterruptions(validSegments),
        silencePeriods: calculateSilencePeriods(validSegments),
        habitualPhrases: findHabitualPhrases(validSegments),
        speakingRateVariance: calculateSpeakingRateVariance(speakingSpeeds)
    };
};

/**
 * 감정 분석
 */
const analyzeEmotions = (segments) => {
    const validSegments = segments.filter(s => s.analysis);
    
    if (validSegments.length === 0) {
        return { averageScores: { positive: 0.5, neutral: 0.5, negative: 0 } };
    }

    const likabilityScores = validSegments.map(s => s.analysis.likability || 50);
    const interestScores = validSegments.map(s => s.analysis.interest || 50);

    const averageLikability = likabilityScores.length > 0 
        ? sanitizeValue(likabilityScores.reduce((sum, score) => sum + score, 0) / likabilityScores.length, 50)
        : 50;
    const averageInterest = interestScores.length > 0 
        ? sanitizeValue(interestScores.reduce((sum, score) => sum + score, 0) / interestScores.length, 50)
        : 50;

    return {
        averageScores: {
            positive: sanitizeValue(Math.round((averageLikability + averageInterest) / 2) / 100, 0.5),
            neutral: 0.3,
            negative: sanitizeValue(Math.round((200 - averageLikability - averageInterest) / 2) / 100, 0.2)
        },
        trends: calculateEmotionTrends(likabilityScores, interestScores)
    };
};

/**
 * 타임라인 생성
 */
const generateTimeline = (segments) => {
    return segments.map((segment, index) => ({
        timestamp: segment.timestamp,
        segment: index,
        duration: 30, // 30초 고정
        speakingRate: {
            user: segment.analysis?.speakingSpeed || 120
        },
        emotionScores: {
            positive: (segment.analysis?.likability || 50) / 100,
            neutral: 0.3,
            negative: 1 - ((segment.analysis?.likability || 50) / 100) - 0.3
        },
        keyEvents: segment.hapticFeedbacks || [],
        transcription: segment.transcription || ''
    }));
};

/**
 * 기본 통계값 반환
 */
const getDefaultStatistics = () => ({
    speakingRatio: 0.5,
    averageSpeakingSpeed: 120,
    totalWords: 0,
    questionAnswerRatio: 0,
    interruptions: 0,
    silencePeriods: [],
    habitualPhrases: [],
    speakingRateVariance: 0
});

// 헬퍼 함수들 (간단한 구현)
const calculateQuestionAnswerRatio = (segments) => {
    const validSegments = segments.filter(s => s.transcription && s.transcription.trim().length > 0);
    if (validSegments.length === 0) return 0;
    
    const questionCount = validSegments.filter(s => 
        s.transcription.includes('?') || 
        s.transcription.includes('뭐') || 
        s.transcription.includes('어떻게') ||
        s.transcription.includes('왜') ||
        s.transcription.includes('언제') ||
        s.transcription.includes('어디') ||
        s.transcription.includes('어떤')
    ).length;
    
    const ratio = questionCount / validSegments.length;
    return sanitizeValue(Math.round(ratio * 100) / 100, 0);
};

const calculateInterruptions = (segments) => {
    let interruptions = 0;
    for (let i = 1; i < segments.length; i++) {
        const prev = segments[i - 1];
        const curr = segments[i];
        
        // 이전 세그먼트가 짧고 현재 세그먼트가 시작된 경우 (말 끊기로 간주)
        if (prev.transcription && prev.transcription.length < 50 && 
            curr.transcription && curr.transcription.length > 0) {
            interruptions++;
        }
    }
    return interruptions;
};

const calculateSilencePeriods = (segments) => {
    const silencePeriods = [];
    for (let i = 0; i < segments.length; i++) {
        const segment = segments[i];
        if (!segment.transcription || segment.transcription.trim().length === 0) {
            silencePeriods.push({
                start: i * 30,
                duration: 30,
                type: 'silence'
            });
        }
    }
    return silencePeriods;
};

const findHabitualPhrases = (segments) => {
    const phrases = {};
    const validSegments = segments.filter(s => s.transcription && s.transcription.trim().length > 0);
    
    // 자주 사용되는 표현들 찾기
    const commonPhrases = ['그래서', '그런데', '아니', '근데', '음', '어', '그', '그냥', '좀', '이제'];
    
    validSegments.forEach(segment => {
        const text = segment.transcription.toLowerCase();
        commonPhrases.forEach(phrase => {
            if (text.includes(phrase)) {
                phrases[phrase] = (phrases[phrase] || 0) + 1;
            }
        });
    });
    
    // 3회 이상 사용된 표현들만 반환
    return Object.entries(phrases)
        .filter(([phrase, count]) => count >= 3)
        .map(([phrase, count]) => ({ phrase, count }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 5); // 상위 5개만
};

const calculateSpeakingRateVariance = (speeds) => {
    if (speeds.length <= 1) return 0;
    
    const mean = speeds.reduce((sum, speed) => sum + speed, 0) / speeds.length;
    const variance = speeds.reduce((sum, speed) => sum + Math.pow(speed - mean, 2), 0) / speeds.length;
    const result = Math.sqrt(variance);
    return sanitizeValue(Math.round(result), 0);
};

const calculateEmotionTrends = (likability, interest) => {
    if (likability.length <= 1) return { trend: 'stable', change: 0 };
    
    const firstHalf = likability.slice(0, Math.floor(likability.length / 2));
    const secondHalf = likability.slice(Math.floor(likability.length / 2));
    
    const firstAvg = firstHalf.length > 0 
        ? sanitizeValue(firstHalf.reduce((sum, val) => sum + val, 0) / firstHalf.length, 50)
        : 50;
    const secondAvg = secondHalf.length > 0 
        ? sanitizeValue(secondHalf.reduce((sum, val) => sum + val, 0) / secondHalf.length, 50)
        : 50;
    
    const change = sanitizeValue(secondAvg - firstAvg, 0);
    
    return {
        trend: change > 5 ? 'increasing' : change < -5 ? 'decreasing' : 'stable',
        change: sanitizeValue(Math.round(change), 0),
        likabilityTrend: change > 0 ? '상승' : change < 0 ? '하락' : '안정',
        interestTrend: interest.length > 1 ? '지속적' : '보통'
    };
};

const generateKeyInsights = (stats, emotions) => {
    const insights = [];
    
    // 말하기 속도 인사이트
    if (stats.averageSpeakingSpeed > 180) {
        insights.push('말하기 속도가 빨라 상대방이 따라가기 어려울 수 있습니다.');
    } else if (stats.averageSpeakingSpeed < 100) {
        insights.push('말하기 속도가 느려 대화의 활력이 부족할 수 있습니다.');
    } else {
        insights.push('적절한 속도로 말하여 상대방이 이해하기 쉬웠습니다.');
    }
    
    // 감정 점수 인사이트
    if (emotions.averageScores.positive > 0.7) {
        insights.push('전반적으로 긍정적인 감정으로 대화했습니다.');
    } else if (emotions.averageScores.positive < 0.3) {
        insights.push('감정 표현을 더 풍부하게 하면 좋겠습니다.');
    }
    
    // 말하기 비율 인사이트
    if (stats.speakingRatio > 0.7) {
        insights.push('상대방의 말을 더 많이 들어주면 좋겠습니다.');
    } else if (stats.speakingRatio < 0.3) {
        insights.push('좀 더 적극적으로 대화에 참여해보세요.');
    } else {
        insights.push('대화 참여도가 적절했습니다.');
    }
    
    // 습관적 표현 인사이트
    if (stats.habitualPhrases.length > 0) {
        insights.push(`"${stats.habitualPhrases[0].phrase}" 표현을 자주 사용했습니다. 다양한 표현을 사용해보세요.`);
    }
    
    return insights.slice(0, 3); // 최대 3개 인사이트
};

const generateSuggestions = (segments, sessionType, stats) => {
    try {
        const suggestions = [];
        
        // 📊 안전성 검사
        if (!stats || typeof stats !== 'object') {
            logger.warn('generateSuggestions: stats가 유효하지 않음, 기본 제안 반환');
            return ['더 적극적으로 대화에 참여해보세요.', '감정을 적절히 표현하며 대화하세요.'];
        }
        
        // 세션 타입별 맞춤 제안
        switch (sessionType) {
            case 'dating':
                suggestions.push('상대방의 관심사에 대해 더 많은 질문을 해보세요.');
                if (stats.averageSpeakingSpeed && stats.averageSpeakingSpeed > 150) {
                    suggestions.push('조금 더 천천히 말하면 매력적으로 들릴 수 있습니다.');
                }
                suggestions.push('공통 관심사를 찾아 대화를 이어가보세요.');
                break;
                
            case 'interview':
                suggestions.push('구체적인 경험과 성과를 바탕으로 답변하세요.');
                if (stats.speakingRatio && stats.speakingRatio < 0.6) {
                    suggestions.push('더 자신감 있게 자신의 경험을 어필하세요.');
                }
                suggestions.push('질문의 의도를 파악하고 핵심을 짚어 답변하세요.');
                break;
                
            case 'presentation':
                suggestions.push('핵심 포인트를 먼저 말하고 세부사항을 설명하세요.');
                if (stats.questionAnswerRatio && stats.questionAnswerRatio < 0.1) {
                    suggestions.push('확인 질문을 통해 청중의 이해도를 체크하세요.');
                }
                suggestions.push('데이터와 사실을 기반으로 논리적으로 설명하세요.');
                break;
                
            case 'coaching':
                suggestions.push('경청과 공감을 통해 라포를 형성하세요.');
                suggestions.push('열린 질문으로 상대방의 생각을 이끌어내세요.');
                if (stats.interruptions && stats.interruptions > 2) {
                    suggestions.push('상대방의 말을 끝까지 들어주세요.');
                }
                break;
                
            default:
                suggestions.push('상대방과의 소통을 더욱 활발히 해보세요.');
                suggestions.push('감정을 적절히 표현하며 대화하세요.');
        }
        
        // 공통 제안사항 (안전성 검사 포함)
        if (stats.silencePeriods && Array.isArray(stats.silencePeriods) && stats.silencePeriods.length > 3) {
            suggestions.push('침묵이 길어질 때는 적절한 질문으로 대화를 이어가세요.');
        }
        
        return suggestions.slice(0, 4); // 최대 4개 제안
        
    } catch (error) {
        logger.error(`generateSuggestions 에러: ${error.message}`);
        return ['더 적극적으로 대화에 참여해보세요.', '감정을 적절히 표현하며 대화하세요.'];
    }
};

const generateSpecializedAnalysis = (segments, sessionType) => {
    try {
        // 📊 안전성 검사
        if (!Array.isArray(segments)) {
            logger.warn('generateSpecializedAnalysis: segments가 배열이 아님');
            segments = [];
        }
        
        const validSegments = segments.filter(s => s && s.transcription && s.transcription.trim().length > 0);
        
        switch (sessionType) {
            case 'dating':
                return {
                    type: '소개팅 분석',
                    rapport_building: analyzeDatingRapport(validSegments),
                    conversation_topics: analyzeDatingTopics(validSegments),
                    emotional_connection: analyzeDatingEmotion(validSegments)
                };
                
            case 'interview':
                return {
                    type: '면접 분석',
                    answer_structure: analyzeInterviewStructure(validSegments),
                    confidence_level: analyzeInterviewConfidence(validSegments),
                    technical_communication: analyzeInterviewTechnical(validSegments)
                };
                
            case 'presentation':
                return {
                    type: '발표 분석',
                    presentation_clarity: analyzePresentationClarity(validSegments),
                    persuasion_techniques: analyzePresentationPersuasion(validSegments),
                    audience_engagement: analyzePresentationEngagement(validSegments)
                };
                
            case 'coaching':
                return {
                    type: '코칭 분석',
                    listening_skills: analyzeCoachingListening(validSegments),
                    questioning_techniques: analyzeCoachingQuestions(validSegments),
                    empathy_building: analyzeCoachingEmpathy(validSegments)
                };
                
            default:
                return {
                    type: '일반 대화 분석',
                    communication_effectiveness: '보통',
                    key_strengths: ['적극적 참여'],
                    improvement_areas: ['다양한 표현 사용']
                };
        }
        
    } catch (error) {
        logger.error(`generateSpecializedAnalysis 에러: ${error.message}`);
        return {
            type: '기본 분석',
            communication_effectiveness: '데이터 부족',
            key_strengths: [],
            improvement_areas: ['더 긴 세션 진행']
        };
    }
};

// 세션 타입별 상세 분석 함수들
const analyzeDatingRapport = (segments) => {
    const positiveWords = ['좋아', '재미있', '멋있', '예쁘', '좋은', '훌륭', '대단'];
    const questionCount = segments.filter(s => s.transcription.includes('?')).length;
    const positiveCount = segments.filter(s => 
        positiveWords.some(word => s.transcription.includes(word))
    ).length;
    
    return {
        score: Math.min(100, (positiveCount * 20) + (questionCount * 10)),
        feedback: positiveCount > 2 ? '긍정적 표현을 잘 사용했습니다' : '긍정적 표현을 더 사용해보세요'
    };
};

const analyzeDatingTopics = (segments) => {
    const topics = {
        '취미': ['취미', '좋아하', '관심', '즐기'],
        '여행': ['여행', '가본', '가고싶', '놀러'],
        '음식': ['맛있', '음식', '먹', '요리'],
        '영화': ['영화', '드라마', '봤', '보고'],
        '음악': ['음악', '노래', '듣', '좋아하는']
    };
    
    const mentionedTopics = [];
    Object.entries(topics).forEach(([topic, keywords]) => {
        const mentioned = segments.some(s => 
            keywords.some(keyword => s.transcription.includes(keyword))
        );
        if (mentioned) mentionedTopics.push(topic);
    });
    
    return {
        topics: mentionedTopics,
        diversity: mentionedTopics.length,
        recommendation: mentionedTopics.length < 2 ? '더 다양한 주제로 대화해보세요' : '좋은 주제 선택이었습니다'
    };
};

const analyzeDatingEmotion = (segments) => {
    const laughWords = ['ㅋㅋ', 'ㅎㅎ', '하하', '웃', '재미'];
    const laughCount = segments.filter(s => 
        laughWords.some(word => s.transcription.includes(word))
    ).length;
    
    return {
        humor_level: Math.min(100, laughCount * 25),
        emotional_expression: laughCount > 0 ? '활발함' : '차분함',
        suggestion: laughCount === 0 ? '유머를 적절히 사용해보세요' : '좋은 분위기를 만들었습니다'
    };
};

const analyzeInterviewStructure = (segments) => {
    const structureWords = ['첫째', '둘째', '먼저', '그리고', '마지막으로', '결론적으로'];
    const structuredCount = segments.filter(s => 
        structureWords.some(word => s.transcription.includes(word))
    ).length;
    
    return {
        structure_score: Math.min(100, structuredCount * 30),
        clarity: structuredCount > 0 ? '구조적' : '보통',
        feedback: structuredCount === 0 ? '답변에 구조를 더해보세요' : '체계적으로 답변했습니다'
    };
};

const analyzeInterviewConfidence = (segments) => {
    const confidenceWords = ['자신있', '확신', '경험', '성과', '달성', '성공'];
    const uncertainWords = ['아마', '글쎄', '잘 모르', '확실하지'];
    
    const confidentCount = segments.filter(s => 
        confidenceWords.some(word => s.transcription.includes(word))
    ).length;
    const uncertainCount = segments.filter(s => 
        uncertainWords.some(word => s.transcription.includes(word))
    ).length;
    
    return {
        confidence_level: Math.max(0, Math.min(100, (confidentCount * 25) - (uncertainCount * 15))),
        tone: confidentCount > uncertainCount ? '자신감 있음' : '겸손함',
        suggestion: confidentCount < 2 ? '더 자신감 있게 어필하세요' : '적절한 자신감을 보였습니다'
    };
};

const analyzeInterviewTechnical = (segments) => {
    const technicalWords = ['프로젝트', '시스템', '개발', '분석', '설계', '구현', '테스트'];
    const technicalCount = segments.filter(s => 
        technicalWords.some(word => s.transcription.includes(word))
    ).length;
    
    return {
        technical_depth: Math.min(100, technicalCount * 20),
        communication: technicalCount > 0 ? '전문적' : '일반적',
        advice: '구체적인 기술적 경험을 더 설명해보세요'
    };
};

const analyzePresentationClarity = (segments) => {
    const clarityWords = ['핵심은', '요점은', '중요한', '주요', '기본적으로'];
    const clarityCount = segments.filter(s => 
        clarityWords.some(word => s.transcription.includes(word))
    ).length;
    
    return {
        clarity_score: Math.min(100, clarityCount * 25),
        presentation_style: clarityCount > 1 ? '명확함' : '보통',
        improvement: '핵심 포인트를 먼저 제시하고 설명하세요'
    };
};

const analyzePresentationPersuasion = (segments) => {
    const persuasionWords = ['장점', '이익', '효과', '결과', '성과', '가치'];
    const persuasionCount = segments.filter(s => 
        persuasionWords.some(word => s.transcription.includes(word))
    ).length;
    
    return {
        persuasion_level: Math.min(100, persuasionCount * 20),
        approach: persuasionCount > 2 ? '설득적' : '정보 전달형',
        recommendation: '구체적인 이익과 가치를 더 강조하세요'
    };
};

const analyzePresentationEngagement = (segments) => {
    const engagementWords = ['질문', '의견', '생각', '어떻게', '동의'];
    const engagementCount = segments.filter(s => 
        engagementWords.some(word => s.transcription.includes(word))
    ).length;
    
    return {
        engagement_score: Math.min(100, engagementCount * 15),
        interaction_level: engagementCount > 2 ? '상호작용적' : '일방향적',
        tip: '청중과의 상호작용을 더 늘려보세요'
    };
};

const analyzeCoachingListening = (segments) => {
    const listeningWords = ['그렇군요', '이해', '공감', '맞아요', '그래서', '계속'];
    const listeningCount = segments.filter(s => 
        listeningWords.some(word => s.transcription.includes(word))
    ).length;
    
    return {
        listening_score: Math.min(100, listeningCount * 20),
        style: listeningCount > 2 ? '적극적 경청' : '기본적 경청',
        development: '더 많은 공감 표현을 사용해보세요'
    };
};

const analyzeCoachingQuestions = (segments) => {
    const openQuestions = segments.filter(s => 
        s.transcription.includes('어떻게') || 
        s.transcription.includes('왜') || 
        s.transcription.includes('무엇을')
    ).length;
    
    return {
        question_quality: Math.min(100, openQuestions * 25),
        question_type: openQuestions > 1 ? '열린 질문 활용' : '닫힌 질문 위주',
        guidance: '열린 질문으로 더 깊이 탐색해보세요'
    };
};

const analyzeCoachingEmpathy = (segments) => {
    const empathyWords = ['힘들', '어렵', '이해해', '공감', '마음', '느낌'];
    const empathyCount = segments.filter(s => 
        empathyWords.some(word => s.transcription.includes(word))
    ).length;
    
    return {
        empathy_level: Math.min(100, empathyCount * 30),
        emotional_support: empathyCount > 1 ? '따뜻함' : '중립적',
        suggestion: '감정적 지지를 더 표현해보세요'
    };
};

module.exports = {
    saveSegment,
    getSegmentsBySession,
    updateSegment,
    generateSessionAnalytics
}; 
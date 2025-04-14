const mongodbService = require('./mongodb.service');
const logger = require('../utils/logger');

const progressService = {
    /**
     * 사용자 발전 추이 조회
     */
    async getProgressTrend(userId, metrics = ['userSpeakingRatio', 'positiveEmotion'], period = 30) {
        try {
            const db = await mongodbService.getDb();

            // 조회 기간 계산
            const endDate = new Date();
            const startDate = new Date();
            startDate.setDate(startDate.getDate() - period);

            // 세션 데이터 조회
            const sessions = await db.collection('sessionAnalytics').find({
                userId,
                createdAt: { $gte: startDate, $lte: endDate }
            }).sort({ createdAt: 1 }).toArray();

            // 메트릭별 추이 데이터 구성
            const trends = {};

            metrics.forEach(metric => {
                let data;

                switch (metric) {
                    case 'userSpeakingRatio':
                        data = sessions.map(session => ({
                            date: session.createdAt,
                            value: session.summary.userSpeakingRatio
                        }));
                        break;
                    case 'positiveEmotion':
                        data = sessions.map(session => ({
                            date: session.createdAt,
                            value: session.summary.emotionScores.positive
                        }));
                        break;
                    case 'wordsPerMinute':
                        data = sessions.map(session => ({
                            date: session.createdAt,
                            value: session.summary.wordsCount / (session.summary.duration / 60)
                        }));
                        break;
                    case 'questionRatio':
                        data = sessions.map(session => ({
                            date: session.createdAt,
                            value: session.statistics?.question_answer_ratio || 0
                        }));
                        break;
                    default:
                        data = [];
                }

                trends[metric] = data;
            });

            // 발전 추이 분석
            const analysis = {};

            Object.keys(trends).forEach(metric => {
                const data = trends[metric];

                if (data.length >= 2) {
                    const firstValue = data[0].value;
                    const lastValue = data[data.length - 1].value;
                    const change = lastValue - firstValue;
                    const percentChange = (change / firstValue) * 100;

                    analysis[metric] = {
                        trend: change > 0 ? 'improving' : (change < 0 ? 'declining' : 'stable'),
                        percentChange: Math.round(percentChange * 100) / 100,
                        startValue: firstValue,
                        currentValue: lastValue
                    };
                } else {
                    analysis[metric] = {
                        trend: 'insufficient_data',
                        percentChange: 0,
                        startValue: data[0]?.value || 0,
                        currentValue: data[0]?.value || 0
                    };
                }
            });

            return {
                period,
                sessionCount: sessions.length,
                firstSessionDate: sessions[0]?.createdAt || null,
                lastSessionDate: sessions[sessions.length - 1]?.createdAt || null,
                trends,
                analysis
            };
        } catch (error) {
            logger.error(`Error getting progress trend: ${error.message}`);
            throw error;
        }
    },

    /**
     * 상황별 발전 추이 조회
     */
    async getContextProgressTrend(userId, contextType) {
        try {
            const db = await mongodbService.getDb();

            // 특정 상황 유형의 세션만 조회
            const sessions = await db.collection('sessionAnalytics').find({
                userId,
                sessionType: contextType
            }).sort({ createdAt: 1 }).toArray();

            if (sessions.length === 0) {
                return {
                    contextType,
                    sessionCount: 0,
                    message: `No ${contextType} sessions found for this user`
                };
            }

            // 상황별 특화 지표 구성
            let specializedMetrics = {};

            switch (contextType) {
                case 'dating':
                    // 소개팅 특화 지표
                    specializedMetrics = {
                        likeabilityScore: sessions.map(s => ({
                            date: s.createdAt,
                            value: s.specializedAnalysis?.dating?.likeabilityScore || 0
                        })),
                        likeabilityTrend: sessions[sessions.length - 1]?.specializedAnalysis?.dating?.likeabilityTrend || 'unknown'
                    };
                    break;
                case 'interview':
                    // 면접 특화 지표
                    specializedMetrics = {
                        confidenceScore: sessions.map(s => ({
                            date: s.createdAt,
                            value: s.specializedAnalysis?.interview?.confidenceScore || 0
                        })),
                        clarityScore: sessions.map(s => ({
                            date: s.createdAt,
                            value: s.specializedAnalysis?.interview?.clarityScore || 0
                        }))
                    };
                    break;
                case 'business':
                    // 비즈니스 특화 지표
                    specializedMetrics = {
                        persuasionScore: sessions.map(s => ({
                            date: s.createdAt,
                            value: s.specializedAnalysis?.business?.persuasionScore || 0
                        })),
                        engagementScore: sessions.map(s => ({
                            date: s.createdAt,
                            value: s.specializedAnalysis?.business?.engagementScore || 0
                        }))
                    };
                    break;
                default:
                    specializedMetrics = {};
            }

            // 기본 지표 추이
            const basicMetrics = {
                userSpeakingRatio: sessions.map(s => ({
                    date: s.createdAt,
                    value: s.summary.userSpeakingRatio
                })),
                positiveEmotion: sessions.map(s => ({
                    date: s.createdAt,
                    value: s.summary.emotionScores.positive
                }))
            };

            // 발전 추이 분석
            const analysis = {};
            const allMetrics = { ...basicMetrics, ...specializedMetrics };

            Object.keys(allMetrics).forEach(metric => {
                if (Array.isArray(allMetrics[metric]) && allMetrics[metric].length >= 2) {
                    const data = allMetrics[metric];
                    const firstValue = data[0].value;
                    const lastValue = data[data.length - 1].value;
                    const change = lastValue - firstValue;
                    const percentChange = (change / firstValue) * 100;

                    analysis[metric] = {
                        trend: change > 0 ? 'improving' : (change < 0 ? 'declining' : 'stable'),
                        percentChange: Math.round(percentChange * 100) / 100,
                        startValue: firstValue,
                        currentValue: lastValue
                    };
                }
            });

            return {
                contextType,
                sessionCount: sessions.length,
                firstSessionDate: sessions[0].createdAt,
                lastSessionDate: sessions[sessions.length - 1].createdAt,
                basicMetrics,
                specializedMetrics,
                analysis
            };
        } catch (error) {
            logger.error(`Error getting context progress trend: ${error.message}`);
            throw error;
        }
    },

    /**
     * 발전 추이 요약 조회
     */
    async getProgressSummary(userId) {
        try {
            const db = await mongodbService.getDb();

            // 최근 30일 세션 데이터
            const thirtyDaysAgo = new Date();
            thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

            const recentSessions = await db.collection('sessionAnalytics').find({
                userId,
                createdAt: { $gte: thirtyDaysAgo }
            }).sort({ createdAt: -1 }).toArray();

            // 세션 유형별 개수
            const sessionTypeCount = {};
            recentSessions.forEach(session => {
                if (!sessionTypeCount[session.sessionType]) {
                    sessionTypeCount[session.sessionType] = 0;
                }
                sessionTypeCount[session.sessionType]++;
            });

            // 개선된 영역 식별
            const improvedAreas = [];

            if (recentSessions.length >= 2) {
                // 가장 최근 세션과 이전 세션 비교
                const latestSession = recentSessions[0];
                const previousSession = recentSessions[1];

                // 말하기 비율 개선
                const speakingRatioDiff = latestSession.summary.userSpeakingRatio - previousSession.summary.userSpeakingRatio;
                if (Math.abs(speakingRatioDiff) > 0.05) {
                    improvedAreas.push({
                        area: 'userSpeakingRatio',
                        change: Math.round(speakingRatioDiff * 100) / 100,
                        improved: speakingRatioDiff > 0,
                        message: speakingRatioDiff > 0 ?
                            '대화 참여도가 개선되었습니다.' :
                            '대화에서 발언 균형이 개선되었습니다.'
                    });
                }

                // 긍정적 감정 개선
                const positiveEmotionDiff = latestSession.summary.emotionScores.positive - previousSession.summary.emotionScores.positive;
                if (positiveEmotionDiff > 0.05) {
                    improvedAreas.push({
                        area: 'positiveEmotion',
                        change: Math.round(positiveEmotionDiff * 100) / 100,
                        improved: true,
                        message: '더 긍정적인 감정 표현이 증가했습니다.'
                    });
                }
            }

            // 햅틱 피드백 개선
            const feedbackPipeline = [
                { $match: { userId } },
                { $sort: { timestamp: 1 } },
                { $group: {
                        _id: "$feedbackType",
                        firstCount: {
                            $sum: {
                                $cond: [
                                    { $lte: ["$timestamp", thirtyDaysAgo] },
                                    1,
                                    0
                                ]
                            }
                        },
                        recentCount: {
                            $sum: {
                                $cond: [
                                    { $gt: ["$timestamp", thirtyDaysAgo] },
                                    1,
                                    0
                                ]
                            }
                        }
                    }},
                { $project: {
                        feedbackType: "$_id",
                        firstCount: 1,
                        recentCount: 1,
                        _id: 0
                    }}
            ];

            const feedbackStats = await db.collection('hapticFeedbacks').aggregate(feedbackPipeline).toArray();

            feedbackStats.forEach(stat => {
                // 이전 기간에 피드백이 있고, 최근에 감소했다면 개선된 것
                if (stat.firstCount > 0 && stat.recentCount < stat.firstCount) {
                    improvedAreas.push({
                        area: `feedback_${stat.feedbackType}`,
                        change: stat.firstCount - stat.recentCount,
                        improved: true,
                        message: `${stat.feedbackType} 관련 피드백이 감소했습니다.`
                    });
                }
            });

            return {
                totalSessionsLast30Days: recentSessions.length,
                sessionTypeBreakdown: sessionTypeCount,
                improvedAreas,
                improvementNeededAreas: 3 - improvedAreas.length, // 최대 3개까지 표시
                lastSessionDate: recentSessions[0]?.createdAt || null
            };
        } catch (error) {
            logger.error(`Error getting progress summary: ${error.message}`);
            throw error;
        }
    }
};

module.exports = progressService;
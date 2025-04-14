const mongodbService = require('./mongodb.service');
const logger = require('../utils/logger');

const statsService = {
    /**
     * 세션 유형별 통계 조회
     */
    async getStatsBySessionType(userId, options = {}) {
        try {
            const db = await mongodbService.getDb();

            const pipeline = [
                // 사용자 세션 필터링
                { $match: { userId } },

                // 세션 유형별 그룹화
                { $group: {
                        _id: "$sessionType",
                        count: { $sum: 1 },
                        avgDuration: { $avg: "$summary.duration" },
                        avgWordsCount: { $avg: "$summary.wordsCount" },
                        avgUserSpeakingRatio: { $avg: "$summary.userSpeakingRatio" },
                        avgPositiveEmotion: { $avg: "$summary.emotionScores.positive" },
                        avgNeutralEmotion: { $avg: "$summary.emotionScores.neutral" },
                        avgNegativeEmotion: { $avg: "$summary.emotionScores.negative" }
                    }},

                // 결과 형식 지정
                { $project: {
                        _id: 0,
                        sessionType: "$_id",
                        count: 1,
                        avgDuration: 1,
                        avgWordsCount: 1,
                        avgUserSpeakingRatio: 1,
                        emotions: {
                            positive: "$avgPositiveEmotion",
                            neutral: "$avgNeutralEmotion",
                            negative: "$avgNegativeEmotion"
                        }
                    }}
            ];

            const results = await db.collection('sessionAnalytics').aggregate(pipeline).toArray();

            return {
                stats: results,
                total: results.reduce((acc, curr) => acc + curr.count, 0)
            };
        } catch (error) {
            logger.error(`Error getting stats by session type: ${error.message}`);
            throw error;
        }
    },

    /**
     * 시간별 통계 조회
     */
    async getStatsByTimeframe(userId, timeframe = 'daily', startDate, endDate) {
        try {
            const db = await mongodbService.getDb();

            // 시간 필터 설정
            const matchStage = { userId };
            if (startDate && endDate) {
                matchStage.createdAt = {
                    $gte: new Date(startDate),
                    $lte: new Date(endDate)
                };
            }

            // 시간 그룹화 형식 설정
            let dateFormat;
            switch (timeframe) {
                case 'hourly':
                    dateFormat = { year: { $year: "$createdAt" }, month: { $month: "$createdAt" }, day: { $dayOfMonth: "$createdAt" }, hour: { $hour: "$createdAt" } };
                    break;
                case 'weekly':
                    dateFormat = { year: { $year: "$createdAt" }, week: { $week: "$createdAt" } };
                    break;
                case 'monthly':
                    dateFormat = { year: { $year: "$createdAt" }, month: { $month: "$createdAt" } };
                    break;
                default: // daily
                    dateFormat = { year: { $year: "$createdAt" }, month: { $month: "$createdAt" }, day: { $dayOfMonth: "$createdAt" } };
            }

            const pipeline = [
                { $match: matchStage },
                { $group: {
                        _id: dateFormat,
                        count: { $sum: 1 },
                        avgDuration: { $avg: "$summary.duration" },
                        avgUserSpeakingRatio: { $avg: "$summary.userSpeakingRatio" },
                        avgPositiveEmotion: { $avg: "$summary.emotionScores.positive" }
                    }},
                { $sort: { "_id.year": 1, "_id.month": 1, "_id.day": 1, "_id.hour": 1, "_id.week": 1 } },
                { $project: {
                        _id: 0,
                        timeframe: "$_id",
                        count: 1,
                        avgDuration: 1,
                        avgUserSpeakingRatio: 1,
                        avgPositiveEmotion: 1
                    }}
            ];

            const results = await db.collection('sessionAnalytics').aggregate(pipeline).toArray();

            // 날짜 형식 변환
            results.forEach(item => {
                const tf = item.timeframe;

                if (timeframe === 'hourly') {
                    item.label = `${tf.year}-${tf.month.toString().padStart(2, '0')}-${tf.day.toString().padStart(2, '0')} ${tf.hour.toString().padStart(2, '0')}:00`;
                } else if (timeframe === 'daily') {
                    item.label = `${tf.year}-${tf.month.toString().padStart(2, '0')}-${tf.day.toString().padStart(2, '0')}`;
                } else if (timeframe === 'weekly') {
                    item.label = `${tf.year} Week ${tf.week}`;
                } else if (timeframe === 'monthly') {
                    item.label = `${tf.year}-${tf.month.toString().padStart(2, '0')}`;
                }
            });

            return {
                timeframe,
                stats: results
            };
        } catch (error) {
            logger.error(`Error getting stats by timeframe: ${error.message}`);
            throw error;
        }
    },

    /**
     * 피드백 통계 조회
     */
    async getFeedbackStats(userId) {
        try {
            const db = await mongodbService.getDb();

            // 피드백 유형별 통계
            const feedbackTypePipeline = [
                { $match: { userId } },
                { $group: {
                        _id: "$feedbackType",
                        count: { $sum: 1 },
                        avgIntensity: { $avg: "$intensity" }
                    }},
                { $project: {
                        _id: 0,
                        type: "$_id",
                        count: 1,
                        avgIntensity: 1
                    }}
            ];

            // 세션별 피드백 통계
            const sessionFeedbackPipeline = [
                { $match: { userId } },
                { $group: {
                        _id: "$sessionId",
                        count: { $sum: 1 },
                        types: { $addToSet: "$feedbackType" }
                    }},
                { $group: {
                        _id: null,
                        totalSessions: { $sum: 1 },
                        avgFeedbacksPerSession: { $avg: "$count" },
                        maxFeedbacksInSession: { $max: "$count" },
                        avgUniqueTypesPerSession: { $avg: { $size: "$types" } }
                    }},
                { $project: {
                        _id: 0,
                        totalSessions: 1,
                        avgFeedbacksPerSession: 1,
                        maxFeedbacksInSession: 1,
                        avgUniqueTypesPerSession: 1
                    }}
            ];

            // 패턴별 통계
            const patternPipeline = [
                { $match: { userId } },
                { $group: {
                        _id: "$pattern",
                        count: { $sum: 1 },
                        avgEffectiveScore: { $avg: "$effectiveScore" }
                    }},
                { $project: {
                        _id: 0,
                        pattern: "$_id",
                        count: 1,
                        avgEffectiveScore: 1
                    }}
            ];

            // 모든 통계 실행
            const [feedbackTypeStats, sessionStats, patternStats] = await Promise.all([
                db.collection('hapticFeedbacks').aggregate(feedbackTypePipeline).toArray(),
                db.collection('hapticFeedbacks').aggregate(sessionFeedbackPipeline).toArray(),
                db.collection('hapticFeedbacks').aggregate(patternPipeline).toArray()
            ]);

            return {
                byType: feedbackTypeStats,
                bySession: sessionStats[0] || {
                    totalSessions: 0,
                    avgFeedbacksPerSession: 0,
                    maxFeedbacksInSession: 0,
                    avgUniqueTypesPerSession: 0
                },
                byPattern: patternStats,
                total: feedbackTypeStats.reduce((acc, curr) => acc + curr.count, 0)
            };
        } catch (error) {
            logger.error(`Error getting feedback stats: ${error.message}`);
            throw error;
        }
    }
};

module.exports = statsService;
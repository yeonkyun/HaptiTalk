const { ObjectId } = require('mongodb');
const PDFDocument = require('pdfkit');
// canvas 의존성 제거
// const { ChartJSNodeCanvas } = require('chartjs-node-canvas');
const mongodbService = require('./mongodb.service');
const logger = require('../utils/logger');
const chartsUtils = require('../utils/charts');

const reportService = {
    /**
     * 세션 데이터를 기반으로 리포트 생성
     */
    async generateSessionReport(userId, sessionId, options) {
        try {
            // MongoDB에서 세션 분석 데이터 조회
            const db = await mongodbService.getDb();
            const sessionAnalytics = await db.collection('sessionAnalytics').findOne({
                sessionId,
                userId
            });

            if (!sessionAnalytics) {
                throw new Error('Session analytics data not found');
            }

            // MongoDB에서 피드백 이력 조회
            const feedbackHistory = await db.collection('hapticFeedbacks').find({
                sessionId,
                userId
            }).toArray();

            // 리포트 데이터 생성
            const reportData = {
                _id: new ObjectId(),
                userId,
                sessionId,
                createdAt: new Date(),
                sessionType: sessionAnalytics.sessionType,
                duration: sessionAnalytics.summary.duration,
                overallInsights: this._generateOverallInsights(sessionAnalytics),
                keyMetrics: this._generateKeyMetrics(sessionAnalytics),
                emotionAnalysis: this._generateEmotionAnalysis(sessionAnalytics),
                communicationPatterns: this._generateCommunicationPatterns(sessionAnalytics),
                feedbackSummary: this._generateFeedbackSummary(feedbackHistory),
                improvementAreas: this._generateImprovementAreas(sessionAnalytics),
                detailedTimeline: options.detailLevel === 'comprehensive' ? sessionAnalytics.timeline : null,
                specializationInsights: this._generateSpecializationInsights(sessionAnalytics)
            };

            // MongoDB에 리포트 저장
            await db.collection('sessionReports').insertOne(reportData);

            // 차트 생성 비활성화
            if (options.includeCharts) {
                // reportData.charts = await this._generateChartData(sessionAnalytics, feedbackHistory);
                logger.info('Chart generation is disabled');
                reportData.charts = { disabled: true, message: 'Chart generation is temporarily disabled' };
            }

            // PDF 생성 비활성화
            if (options.format === 'pdf') {
                // const pdfBuffer = await this.generateReportPdf(userId, reportData._id.toString());
                logger.info('PDF generation is disabled');
                reportData.pdfUrl = null; 
                reportData.pdfDisabled = true;
            }

            // 필요 없는 필드 제거 (디테일 레벨에 따라)
            if (options.detailLevel === 'basic') {
                delete reportData.detailedTimeline;
                reportData.communicationPatterns = reportData.communicationPatterns.slice(0, 3);
                reportData.improvementAreas = reportData.improvementAreas.slice(0, 3);
            }

            return reportData;
        } catch (error) {
            logger.error(`Error generating report: ${error.message}`);
            throw error;
        }
    },

    /**
     * 리포트 ID로 리포트 조회
     */
    async getReportById(userId, reportId) {
        try {
            const db = await mongodbService.getDb();
            const report = await db.collection('sessionReports').findOne({
                _id: new ObjectId(reportId),
                userId
            });

            if (!report) {
                throw new Error('Report not found');
            }

            return report;
        } catch (error) {
            logger.error(`Error retrieving report: ${error.message}`);
            throw error;
        }
    },

    /**
     * 사용자별 리포트 목록 조회
     */
    async getReportsByUser(userId, options) {
        try {
            const { page, limit, sessionType, startDate, endDate } = options;
            const skip = (page - 1) * limit;

            // 필터 구성
            const filter = { userId };
            if (sessionType) filter.sessionType = sessionType;
            if (startDate && endDate) {
                filter.createdAt = {
                    $gte: new Date(startDate),
                    $lte: new Date(endDate)
                };
            }

            const db = await mongodbService.getDb();

            // 전체 개수 조회
            const total = await db.collection('sessionReports').countDocuments(filter);

            // 리포트 목록 조회
            const reports = await db.collection('sessionReports')
                .find(filter)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .project({
                    _id: 1,
                    sessionId: 1,
                    sessionType: 1,
                    createdAt: 1,
                    duration: 1,
                    keyMetrics: 1,
                    overallInsights: { $slice: ['$overallInsights', 3] }
                })
                .toArray();

            return {
                reports,
                pagination: {
                    total,
                    page,
                    limit,
                    pages: Math.ceil(total / limit)
                }
            };
        } catch (error) {
            logger.error(`Error retrieving reports: ${error.message}`);
            throw error;
        }
    },

    /**
     * PDF 형식의 리포트 생성 (비활성화)
     */
    async generateReportPdf(userId, reportId) {
        try {
            logger.info('PDF generation is disabled');
            // 임시 PDF 버퍼 반환
            return Buffer.from('PDF generation is disabled');
        } catch (error) {
            logger.error(`Error generating PDF: ${error.message}`);
            throw error;
        }
    },

    /**
     * 세션 간 비교 리포트 생성
     */
    async generateComparisonReport(userId, sessionIds, metrics) {
        try {
            const db = await mongodbService.getDb();

            // 세션 리포트 데이터 조회
            const reports = await db.collection('sessionReports')
                .find({
                    userId,
                    sessionId: { $in: sessionIds }
                })
                .toArray();

            if (reports.length !== sessionIds.length) {
                throw new Error('One or more reports not found');
            }

            // 비교 지표 정의 (기본 지표 또는 사용자 지정 지표)
            const metricsToCompare = metrics || [
                'keyMetrics.userSpeakingRatio',
                'emotionAnalysis.positive',
                'keyMetrics.wordsPerMinute'
            ];

            // 비교 데이터 구성
            const comparisonData = {
                sessionIds,
                metrics: {},
                timeline: {},
                improvements: {},
                recommendations: []
            };

            // 각 지표별 비교 데이터 구성
            metricsToCompare.forEach(metric => {
                comparisonData.metrics[metric] = reports.map(report => {
                    const keys = metric.split('.');
                    let value = report;

                    for (const key of keys) {
                        value = value[key];
                        if (value === undefined) break;
                    }

                    return {
                        sessionId: report.sessionId,
                        sessionType: report.sessionType,
                        date: report.createdAt,
                        value: value
                    };
                });
            });

            // 시간에 따른 개선점 파악
            comparisonData.improvements = this._calculateImprovements(comparisonData.metrics);

            // 개선을 위한 추천사항 생성
            comparisonData.recommendations = this._generateRecommendations(comparisonData.metrics, comparisonData.improvements);

            return comparisonData;
        } catch (error) {
            logger.error(`Error generating comparison report: ${error.message}`);
            throw error;
        }
    },

    /**
     * 내부 헬퍼 메서드: 전체 인사이트 생성
     */
    _generateOverallInsights(sessionAnalytics) {
        // 세션 데이터에서 주요 인사이트 추출 로직
        const insights = [...sessionAnalytics.summary.keyInsights];

        // 추가 인사이트 생성
        if (sessionAnalytics.summary.userSpeakingRatio > 0.6) {
            insights.push('발화 시간이 상대방보다 더 길었습니다. 상대방에게 더 많은 발화 기회를 제공해보세요.');
        } else if (sessionAnalytics.summary.userSpeakingRatio < 0.4) {
            insights.push('상대방이 대화를 주도했습니다. 더 적극적으로 대화에 참여해보세요.');
        }

        return insights;
    },

    /**
     * 내부 헬퍼 메서드: 주요 지표 생성
     */
    _generateKeyMetrics(sessionAnalytics) {
        return {
            userSpeakingRatio: sessionAnalytics.summary.userSpeakingRatio,
            wordsPerMinute: Math.round(sessionAnalytics.summary.wordsCount / (sessionAnalytics.summary.duration / 60)),
            questionAnswerRatio: sessionAnalytics.statistics?.question_answer_ratio || 0,
            interruptionCount: sessionAnalytics.statistics?.interruptions || 0,
            silencePeriods: sessionAnalytics.statistics?.silence_periods?.length || 0
        };
    },

    /**
     * 내부 헬퍼 메서드: 감정 분석 생성
     */
    _generateEmotionAnalysis(sessionAnalytics) {
        return sessionAnalytics.summary.emotionScores;
    },

    /**
     * 내부 헬퍼 메서드: 의사소통 패턴 생성
     */
    _generateCommunicationPatterns(sessionAnalytics) {
        const patterns = [];

        // 습관적인 표현 추가
        if (sessionAnalytics.statistics?.habitual_phrases) {
            sessionAnalytics.statistics.habitual_phrases.forEach(phrase => {
                patterns.push({
                    type: 'habitual_phrase',
                    content: phrase.phrase,
                    count: phrase.count
                });
            });
        }

        // 말하기 속도 패턴 분석 및 추가
        const speakingRates = sessionAnalytics.timeline.map(t => t.speakingRate?.user).filter(Boolean);
        if (speakingRates.length > 0) {
            const avgRate = speakingRates.reduce((a, b) => a + b, 0) / speakingRates.length;
            const variability = Math.sqrt(speakingRates.map(r => Math.pow(r - avgRate, 2)).reduce((a, b) => a + b, 0) / speakingRates.length);

            patterns.push({
                type: 'speaking_rate',
                average: avgRate,
                variability: variability,
                assessment: variability > 20 ? '말하기 속도 변화가 큽니다' : '말하기 속도가 일정합니다'
            });
        }

        return patterns;
    },

    /**
     * 내부 헬퍼 메서드: 피드백 요약 생성
     */
    _generateFeedbackSummary(feedbackHistory) {
        const feedbackTypes = {};

        feedbackHistory.forEach(feedback => {
            if (!feedbackTypes[feedback.feedbackType]) {
                feedbackTypes[feedback.feedbackType] = 0;
            }
            feedbackTypes[feedback.feedbackType]++;
        });

        return {
            total: feedbackHistory.length,
            byType: feedbackTypes,
            mostFrequent: Object.entries(feedbackTypes).sort((a, b) => b[1] - a[1])[0]?.[0]
        };
    },

    /**
     * 내부 헬퍼 메서드: 개선 영역 생성
     */
    _generateImprovementAreas(sessionAnalytics) {
        return sessionAnalytics.suggestions || [];
    },

    /**
     * 내부 헬퍼 메서드: 상황별 특화 인사이트 생성
     */
    _generateSpecializationInsights(sessionAnalytics) {
        if (sessionAnalytics.specializedAnalysis) {
            return sessionAnalytics.specializedAnalysis;
        }
        return null;
    },
    /**
     * 내부 헬퍼 메서드: 차트 데이터 생성 (비활성화)
     */
    async _generateChartData(sessionAnalytics, feedbackHistory) {
        logger.info('Chart generation is disabled');
        return {
            disabled: true,
            message: 'Chart generation is temporarily disabled'
        };
    },

    /**
     * 내부 헬퍼 메서드: 시간에 따른 개선점 계산
     */
    _calculateImprovements(metricsData) {
        const improvements = {};

        Object.keys(metricsData).forEach(metric => {
            // 날짜 기준으로 정렬
            const sortedData = [...metricsData[metric]].sort((a, b) => new Date(a.date) - new Date(b.date));

            if (sortedData.length > 1) {
                const firstValue = sortedData[0].value;
                const lastValue = sortedData[sortedData.length - 1].value;
                const percentChange = ((lastValue - firstValue) / firstValue) * 100;

                improvements[metric] = {
                    firstValue,
                    lastValue,
                    percentChange,
                    improved: percentChange > 0,
                    significant: Math.abs(percentChange) > 10
                };
            }
        });

        return improvements;
    },

    /**
     * 내부 헬퍼 메서드: 개선을 위한 추천사항 생성
     */
    _generateRecommendations(metricsData, improvements) {
        const recommendations = [];

        // 지표 별 추천사항 생성
        Object.keys(improvements).forEach(metric => {
            const improvement = improvements[metric];

            // 개선되지 않은 지표에 대한 추천사항 생성
            if (!improvement.improved && improvement.significant) {
                switch (metric) {
                    case 'keyMetrics.userSpeakingRatio':
                        recommendations.push({
                            metric: '발화 균형',
                            suggestion: '대화에서 적절한 발화 균형을 찾으세요. 상대방의 의견을 더 많이 경청하거나, 더 적극적으로 대화에 참여하는 것이 도움이 될 수 있습니다.'
                        });
                        break;
                    case 'emotionAnalysis.positive':
                        recommendations.push({
                            metric: '긍정적 감정 표현',
                            suggestion: '대화 중 긍정적인 감정 표현을 늘려보세요. 웃음, 공감, 긍정적인 단어 선택이 도움이 될 수 있습니다.'
                        });
                        break;
                    case 'keyMetrics.wordsPerMinute':
                        recommendations.push({
                            metric: '말하기 속도',
                            suggestion: '말하기 속도를 적절히 조절해보세요. 너무 빠르거나 느린 말하기는 의사소통을 방해할 수 있습니다.'
                        });
                        break;
                }
            }
        });

        // 전반적인 추천사항 추가
        if (recommendations.length === 0) {
            recommendations.push({
                metric: '전반적 개선',
                suggestion: '전반적으로 좋은 발전을 보이고 있습니다. 지속적인 연습을 통해 더욱 자연스러운 의사소통 능력을 키워보세요.'
            });
        }

        return recommendations;
    }
};

module.exports = reportService;

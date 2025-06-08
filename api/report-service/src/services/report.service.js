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
            logger.info(`리포트 생성 시작: 사용자 ${userId}, 세션 ${sessionId}`, {
                detailLevel: options.detailLevel,
                includeCharts: options.includeCharts,
                format: options.format
            });

            // MongoDB에서 세션 분석 데이터 조회
            const db = await mongodbService.getDb();
            const sessionAnalytics = await db.collection('sessionAnalytics').findOne({
                sessionId,
                userId
            });

            if (!sessionAnalytics) {
                logger.warn(`리포트 생성 실패 - 세션 분석 데이터 없음: ${sessionId}`, {
                    userId
                });
                throw new Error('Session analytics data not found');
            }

            // MongoDB에서 피드백 이력 조회
            const feedbackHistory = await db.collection('hapticFeedbacks').find({
                sessionId,
                userId
            }).toArray();

            logger.debug(`리포트 데이터 조회 완료: ${sessionId}`, {
                feedbackCount: feedbackHistory.length,
                sessionDuration: sessionAnalytics.summary?.duration
            });

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

            logger.info(`리포트 생성 성공: ${reportData._id}`, {
                userId,
                sessionId,
                reportId: reportData._id.toString(),
                sessionType: reportData.sessionType,
                duration: reportData.duration,
                insightsCount: reportData.overallInsights?.length || 0,
                improvementAreasCount: reportData.improvementAreas?.length || 0
            });

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
            
            // 🔧 reportId가 ObjectId 형식인지 확인하고 처리
            let query;
            if (ObjectId.isValid(reportId)) {
                // MongoDB ObjectId 형식인 경우
                query = {
                    _id: new ObjectId(reportId),
                    userId
                };
            } else {
                // UUID 또는 다른 형식인 경우 sessionId로 조회
                logger.info(`reportId가 ObjectId 형식이 아님, sessionId로 조회: ${reportId}`);
                query = {
                    sessionId: reportId,
                    userId
                };
            }

            const report = await db.collection('sessionReports').findOne(query);

            if (!report) {
                logger.warn(`리포트 조회 실패 - 존재하지 않는 리포트: ${reportId}`, {
                    userId,
                    queryType: ObjectId.isValid(reportId) ? 'ObjectId' : 'sessionId'
                });
                throw new Error('Report not found');
            }

            // 🔧 MongoDB _id를 id로 변환
            const transformedReport = {
                ...report,
                id: report._id.toString(), // _id를 문자열 id로 변환
                _id: undefined // _id 필드 제거
            };

            logger.info(`리포트 조회 성공: ${reportId}`, {
                userId,
                sessionId: transformedReport.sessionId,
                sessionType: transformedReport.sessionType,
                createdAt: transformedReport.createdAt
            });

            return transformedReport;
        } catch (error) {
            logger.error(`Error retrieving report: ${error.message}`);
            throw error;
        }
    },

    /**
     * 🔧 세션 ID로 리포트 조회 (새로운 함수)
     */
    async getReportBySessionId(userId, sessionId) {
        try {
            const db = await mongodbService.getDb();
            
            const report = await db.collection('sessionReports').findOne({
                sessionId,
                userId
            });

            if (!report) {
                logger.warn(`세션 리포트 조회 실패 - 존재하지 않는 세션: ${sessionId}`, {
                    userId
                });
                throw new Error('Session report not found');
            }

            // 🔧 MongoDB _id를 id로 변환
            const transformedReport = {
                ...report,
                id: report._id.toString(), // _id를 문자열 id로 변환
                _id: undefined // _id 필드 제거
            };

            logger.info(`세션 리포트 조회 성공: ${sessionId}`, {
                userId,
                reportId: transformedReport.id,
                sessionType: transformedReport.sessionType,
                createdAt: transformedReport.createdAt
            });

            return transformedReport;
        } catch (error) {
            logger.error(`Error retrieving session report: ${error.message}`);
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

            // 🔧 MongoDB _id를 id로 변환
            const transformedReports = reports.map(report => ({
                ...report,
                id: report._id.toString(), // _id를 문자열 id로 변환
                _id: undefined // _id 필드 제거
            }));

            logger.info(`사용자 리포트 목록 조회 성공: ${userId}`, {
                totalReports: total,
                returnedReports: transformedReports.length,
                page,
                limit,
                filters: {
                    sessionType,
                    dateRange: startDate && endDate ? `${startDate} ~ ${endDate}` : null
                }
            });

            return {
                reports: transformedReports,
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
            logger.info(`PDF 생성 요청 (비활성화): 사용자 ${userId}, 리포트 ${reportId}`);
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
            logger.info(`비교 리포트 생성 시작: 사용자 ${userId}`, {
                sessionCount: sessionIds.length,
                sessions: sessionIds,
                customMetrics: metrics ? metrics.length : 0
            });

            const db = await mongodbService.getDb();

            // 세션 리포트 데이터 조회
            const reports = await db.collection('sessionReports')
                .find({
                    userId,
                    sessionId: { $in: sessionIds }
                })
                .toArray();

            if (reports.length !== sessionIds.length) {
                logger.warn(`비교 리포트 생성 실패 - 일부 리포트 없음: ${userId}`, {
                    requestedSessions: sessionIds.length,
                    foundReports: reports.length,
                    missingSessions: sessionIds.filter(id => !reports.find(r => r.sessionId === id))
                });
                throw new Error('One or more reports not found');
            }

            // 비교 지표 정의 (기본 지표 또는 사용자 지정 지표)
            const metricsToCompare = metrics || [
                'keyMetrics.userSpeakingRatio',
                'emotionAnalysis.positive',
                'keyMetrics.wordsPerMinute'
            ];

            logger.info(`비교 리포트 생성 성공: ${userId}`, {
                comparedSessions: reports.length,
                metricsCompared: metricsToCompare.length,
                reportGeneratedAt: new Date().toISOString()
            });

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
     * 핵심 지표 생성
     */
    _generateKeyMetrics(sessionAnalytics) {
        const statistics = sessionAnalytics.statistics || {};
        const summary = sessionAnalytics.summary || {};
        const emotionMetrics = sessionAnalytics.emotionMetrics || {};
        const sessionSpecificMetrics = sessionAnalytics.sessionSpecificMetrics || {};

        return {
            // 기본 말하기 지표
            speaking: {
                ratio: parseFloat((summary.userSpeakingRatio || 0).toFixed(2)),
                speed: Math.round(summary.averageSpeakingSpeed || 0),
                words: summary.wordsCount || 0,
                // STT 기반 새로운 지표들
                consistency: parseFloat((statistics.speaking_consistency || 0).toFixed(2)),
                pauseStability: parseFloat((statistics.pause_stability || 0).toFixed(2)),
                speechQuality: parseFloat((statistics.speech_pattern_score || 0).toFixed(2)),
                confidence: parseFloat((statistics.confidence_score || 0).toFixed(2))
            },
            
            // 감정 지표 (STT emotion_analysis 기반)
            emotion: {
                overallTone: parseFloat((emotionMetrics.overall_emotional_tone || 0.5).toFixed(2)),
                stability: parseFloat((emotionMetrics.emotional_stability || 0.6).toFixed(2)),
                variability: parseFloat((emotionMetrics.emotional_variability || 0.4).toFixed(2)),
                primaryEmotions: emotionMetrics.primary_emotions || [],
                happiness: parseFloat((emotionMetrics.happiness || 0.3).toFixed(2)),
                confidence: parseFloat((emotionMetrics.confidence || 0.3).toFixed(2)),
                calmness: parseFloat((emotionMetrics.calmness || 0.4).toFixed(2))
            },
            
            // 세션별 특화 지표
            sessionSpecific: sessionSpecificMetrics,
            
            // 전반적 점수 (0-100 스케일로 변환)
            overallScore: Math.round((
                (statistics.confidence_score || 0.6) * 30 +
                (statistics.speaking_consistency || 0.7) * 20 +
                (statistics.speech_pattern_score || 0.8) * 20 +
                (emotionMetrics.overall_emotional_tone || 0.5) * 15 +
                (emotionMetrics.emotional_stability || 0.6) * 15
            ) * 100),
            
            // 기존 분석 데이터
            communication: {
                interruptions: statistics.interruptions || 0,
                questionAnswerRatio: parseFloat((statistics.question_answer_ratio || 0).toFixed(2)),
                speakingRateVariance: parseFloat((statistics.speaking_rate_variance || 0).toFixed(2))
            }
        };
    },

    /**
     * 감정 분석 데이터 생성
     */
    _generateEmotionAnalysis(sessionAnalytics) {
        const emotionMetrics = sessionAnalytics.emotionMetrics || {};
        const summary = sessionAnalytics.summary || {};

        return {
            // STT 기반 전반적 감정 분석
            overallTone: {
                score: parseFloat((emotionMetrics.overall_emotional_tone || 0.5).toFixed(2)),
                label: this._getEmotionLabel(emotionMetrics.overall_emotional_tone || 0.5),
                description: this._getEmotionDescription(emotionMetrics.overall_emotional_tone || 0.5)
            },
            
            // 감정 안정성
            stability: {
                score: parseFloat((emotionMetrics.emotional_stability || 0.6).toFixed(2)),
                variability: parseFloat((emotionMetrics.emotional_variability || 0.4).toFixed(2)),
                interpretation: this._getStabilityInterpretation(emotionMetrics.emotional_stability || 0.6)
            },
            
            // 개별 감정 점수들 (STT emotion_analysis에서 추출)
            emotions: {
                happiness: parseFloat((emotionMetrics.happiness || 0.3).toFixed(2)),
                confidence: parseFloat((emotionMetrics.confidence || 0.3).toFixed(2)),
                calmness: parseFloat((emotionMetrics.calmness || 0.4).toFixed(2)),
                neutral: parseFloat((emotionMetrics.neutral || 0.4).toFixed(2)),
                excitement: parseFloat((emotionMetrics.excitement || 0.2).toFixed(2)),
                sadness: parseFloat((emotionMetrics.sadness || 0.2).toFixed(2)),
                anger: parseFloat((emotionMetrics.anger || 0.1).toFixed(2)),
                fear: parseFloat((emotionMetrics.fear || 0.2).toFixed(2))
            },
            
            // 주요 감정 변화
            primaryEmotions: emotionMetrics.primary_emotions || [],
            emotionDistribution: emotionMetrics.emotion_distribution || {},
            
            // 분석 정보
            segmentsAnalyzed: emotionMetrics.emotion_segments || 0,
            totalSegments: emotionMetrics.total_segments_analyzed || 0,
            
            // 추천 사항
            recommendations: this._generateEmotionRecommendations(emotionMetrics)
        };
    },

    /**
     * 감정 점수에 따른 라벨 반환
     */
    _getEmotionLabel(score) {
        if (score >= 0.7) return '매우 긍정적';
        if (score >= 0.6) return '긍정적';
        if (score >= 0.4) return '중립적';
        if (score >= 0.3) return '약간 부정적';
        return '부정적';
    },

    /**
     * 감정 점수에 따른 설명 반환
     */
    _getEmotionDescription(score) {
        if (score >= 0.7) return '대화 중 매우 긍정적이고 밝은 감정을 유지했습니다.';
        if (score >= 0.6) return '전반적으로 긍정적인 분위기로 대화에 참여했습니다.';
        if (score >= 0.4) return '안정적이고 중립적인 감정 상태를 보였습니다.';
        if (score >= 0.3) return '다소 소극적이거나 부정적인 감정이 나타났습니다.';
        return '감정 표현이 부족하거나 부정적인 상태였습니다.';
    },

    /**
     * 감정 안정성 해석
     */
    _getStabilityInterpretation(stability) {
        if (stability >= 0.8) return '매우 안정적인 감정 상태';
        if (stability >= 0.6) return '안정적인 감정 상태';
        if (stability >= 0.4) return '보통 수준의 감정 변화';
        if (stability >= 0.2) return '감정 변화가 다소 불안정';
        return '감정 변화가 매우 불안정';
    },

    /**
     * 감정 기반 추천 사항 생성
     */
    _generateEmotionRecommendations(emotionMetrics) {
        const recommendations = [];
        
        if (emotionMetrics.happiness < 0.4) {
            recommendations.push('더 밝고 긍정적인 표현을 사용해보세요.');
        }
        
        if (emotionMetrics.confidence < 0.4) {
            recommendations.push('자신감 있는 톤으로 말하는 연습을 해보세요.');
        }
        
        if (emotionMetrics.emotional_stability < 0.5) {
            recommendations.push('감정의 일관성을 유지하는 것에 집중해보세요.');
        }
        
        if (emotionMetrics.calmness < 0.4) {
            recommendations.push('좀 더 차분하고 안정된 상태로 대화해보세요.');
        }
        
        if (recommendations.length === 0) {
            recommendations.push('감정 표현이 적절합니다. 현재 상태를 유지하세요.');
        }
        
        return recommendations;
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

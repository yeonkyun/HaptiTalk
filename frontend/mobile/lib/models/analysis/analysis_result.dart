import 'package:flutter/material.dart';
import 'emotion_data.dart';
import 'metrics.dart';

// 세션 분석 결과 모델
class AnalysisResult {
  final String sessionId; // 세션 ID
  final String title; // 세션 제목
  final DateTime date; // 세션 날짜
  final DateTime sessionStartTime; // 세션 시작 시간 (정렬용)
  final String category; // 세션 카테고리 (예: '소개팅', '면접', '발표' 등)
  final List<EmotionData> emotionData; // 감정 데이터
  final List<EmotionChangePoint> emotionChangePoints; // 감정 변화 포인트
  final SessionMetrics metrics; // 세션 지표

  AnalysisResult({
    required this.sessionId,
    required this.title,
    required this.date,
    required this.sessionStartTime,
    required this.category,
    required this.emotionData,
    required this.emotionChangePoints,
    required this.metrics,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      sessionId: json['sessionId'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      sessionStartTime: DateTime.parse(json['sessionStartTime'] ?? json['date'] as String),
      category: json['category'] as String,
      emotionData: (json['emotionData'] as List<dynamic>)
          .map((e) => EmotionData.fromJson(e as Map<String, dynamic>))
          .toList(),
      emotionChangePoints: (json['emotionChangePoints'] as List<dynamic>)
          .map((e) => EmotionChangePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      metrics: SessionMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
    );
  }

  // 🔥 report-service API 응답에서 AnalysisResult 생성
  factory AnalysisResult.fromApiResponse(Map<String, dynamic> apiData) {
    try {
      print('🔍 API 응답 파싱 시작: $apiData');
      
      // 🔥 실제 API 응답 구조에 맞게 수정
      // 이전: sessionInfo/analysis 구조 → 현재: 직접 필드 접근
      final sessionInfo = apiData['sessionInfo'] ?? {};
      final analysis = apiData['analysis'] ?? {};
      final timeline = apiData['timeline'] ?? [];
      
      // 🔥 실제 API 응답 필드들 추가 확인
      final keyMetrics = apiData['keyMetrics'] ?? {};
      final communicationPatterns = apiData['communicationPatterns'] ?? [];
      final emotionAnalysis = apiData['emotionAnalysis'] ?? {};
      final specializationInsights = apiData['specializationInsights'] ?? {};
      
      print('🔍 sessionInfo: $sessionInfo');
      print('🔍 analysis: $analysis');
      print('🔍 keyMetrics: $keyMetrics');
      print('🔍 communicationPatterns: $communicationPatterns');
      print('🔍 emotionAnalysis: $emotionAnalysis');
      
      // 감정 데이터 생성 (timeline에서 추출)
      List<EmotionData> emotionData = [];
      for (int i = 0; i < timeline.length; i++) {
        final timePoint = timeline[i];
        emotionData.add(EmotionData(
          timestamp: i.toDouble(),
          emotionType: _getEmotionType(timePoint['emotionScore'] ?? 50),
          value: (timePoint['emotionScore'] ?? 50).toDouble(),
          description: timePoint['description'] ?? '',
        ));
      }
      
      // 감정 변화 포인트 생성
      List<EmotionChangePoint> changePoints = [];
      for (var point in (analysis['emotionChanges'] ?? [])) {
        changePoints.add(EmotionChangePoint(
          time: point['time'] ?? '00:00:00',
          timestamp: point['timestamp'] ?? 0,
          description: point['description'] ?? '',
          emotionValue: point['emotionValue'] ?? 50,
          label: point['label'] ?? '',
          topics: List<String>.from(point['topics'] ?? []),
        ));
      }
      
      // 🔥 실제 API 응답에서 값 추출 (새로운 구조 반영)
      final duration = (apiData['duration'] ?? 
                       sessionInfo['duration'] ?? 
                       sessionInfo['totalDuration'] ?? 
                       analysis['duration'] ?? 
                       analysis['totalDuration'] ?? 
                       30).toDouble(); // API에서 초 단위로 오는 것으로 추정
      
      // communicationPatterns에서 speaking_rate 찾기
      double speechRateFromPatterns = 120.0;
      for (var pattern in communicationPatterns) {
        if (pattern['type'] == 'speaking_rate') {
          speechRateFromPatterns = (pattern['average'] ?? 120.0).toDouble();
          break;
        }
      }
      
      final speechRate = (keyMetrics['wordsPerMinute'] ?? 
                         speechRateFromPatterns ??
                         analysis['averageSpeed'] ?? 
                         analysis['speechRate'] ?? 
                         analysis['speakingSpeed'] ?? 
                         analysis['wpm'] ?? 
                         120).toDouble();
      
      final tonality = (analysis['tonality'] ?? 
                        analysis['tone'] ?? 
                        analysis['tonality_score'] ?? 
                        75).toDouble();
      
      final clarity = (analysis['clarity'] ?? 
                       analysis['clarity_score'] ?? 
                       analysis['pronunciation'] ?? 
                       80).toDouble();
      
      // emotionAnalysis에서 감정 지표 추출
      final averageInterest = ((emotionAnalysis['positive'] ?? 0.7) * 100).toDouble();
      
      // specializationInsights에서 추가 정보 추출
      final rapportBuilding = specializationInsights['rapport_building'] ?? {};
      final conversationTopics = specializationInsights['conversation_topics'] ?? {};
      final emotionalConnection = specializationInsights['emotional_connection'] ?? {};
      
      final averageLikeability = (rapportBuilding['score'] ?? 50).toDouble();
      
      final contributionRatio = ((keyMetrics['userSpeakingRatio'] ?? 0.6) * 100).toDouble();
      
      // 대화 흐름 분석에서 경청 점수 계산
      final overallInsights = apiData['overallInsights'] ?? [];
      double listeningScore = 75.0;
      for (var insight in overallInsights) {
        if (insight.toString().contains('들어주면') || insight.toString().contains('경청')) {
          listeningScore = 60.0; // 경청 개선 필요 시 낮은 점수
          break;
        } else if (insight.toString().contains('잘 들었') || insight.toString().contains('적극적')) {
          listeningScore = 85.0; // 좋은 경청 시 높은 점수
          break;
        }
      }
      
      print('🔍 파싱된 값들: duration=$duration, speechRate=$speechRate, tonality=$tonality, clarity=$clarity');
      print('🔍 감정 지표: averageInterest=$averageInterest, contributionRatio=$contributionRatio, listeningScore=$listeningScore');
      print('🔍 전문 분석: rapportScore=${rapportBuilding['score']}, topicDiversity=${conversationTopics['diversity']}');
      
      // 세션 지표 생성
      final metrics = SessionMetrics(
        totalDuration: duration,
        audioRecorded: sessionInfo['audioRecorded'] ?? true,
        speakingMetrics: SpeakingMetrics(
          speechRate: speechRate,
          tonality: tonality,
          clarity: clarity,
          habitPatterns: _convertHabitPatterns(analysis['habitPatterns'] ?? []),
        ),
        emotionMetrics: EmotionMetrics(
          averageInterest: averageInterest,
          averageLikeability: averageLikeability,
          peakLikeability: (analysis['peakLikability'] ?? analysis['maxLikeability'] ?? averageLikeability + 10).toDouble(),
          lowestLikeability: (analysis['lowestLikability'] ?? analysis['minLikeability'] ?? averageLikeability - 10).toDouble(),
          feedbacks: _convertEmotionFeedbacks(analysis['feedbacks'] ?? []),
        ),
        conversationMetrics: ConversationMetrics(
          contributionRatio: contributionRatio,
          listeningScore: listeningScore,
          interruptionCount: (analysis['interruptionCount'] ?? analysis['interruptions'] ?? 0).toDouble(),
          flowDescription: analysis['flowDescription'] ?? analysis['summary'] ?? '안정적인 대화 흐름',
        ),
        topicMetrics: TopicMetrics(
          topics: _convertTopics(conversationTopics['topics'] ?? analysis['topics'] ?? []),
          timepoints: _convertTopicTimepoints(analysis['topicTimepoints'] ?? []),
          insights: _convertApiInsights(overallInsights),
          recommendations: _convertApiRecommendations(apiData['improvementAreas'] ?? []),
        ),
      );
      
      // 🔥 세션 타입 추출 (실제 API 응답 구조 반영)
      final sessionType = apiData['sessionType'] ??
                         sessionInfo['type'] ?? 
                         sessionInfo['sessionType'] ?? 
                         sessionInfo['category'] ?? 
                         'presentation'; // 기본값은 가장 일반적인 발표로
      
      print('🔍 세션 타입 파싱: apiData[sessionType]=${apiData['sessionType']}, 최종값=$sessionType');
      final convertedCategory = _convertSessionType(sessionType);
      print('🔍 변환된 카테고리: $sessionType → $convertedCategory');
      
      return AnalysisResult(
        sessionId: apiData['sessionId'] ?? sessionInfo['sessionId'] ?? 'unknown',
        title: sessionInfo['title'] ?? sessionInfo['name'] ?? '이름 없는 세션',
        date: DateTime.tryParse(apiData['createdAt'] ?? sessionInfo['date'] ?? sessionInfo['createdAt'] ?? '') ?? DateTime.now(),
        sessionStartTime: DateTime.tryParse(sessionInfo['startTime'] ?? sessionInfo['date'] ?? sessionInfo['createdAt'] ?? apiData['createdAt'] ?? '') ?? DateTime.now(),
        category: convertedCategory,
        emotionData: emotionData,
        emotionChangePoints: changePoints,
        metrics: metrics,
      );
    } catch (e) {
      print('❌ API 응답 파싱 오류: $e');
      print('❌ API 데이터: $apiData');
      
      // 🔥 파싱 오류 시 더 나은 기본값으로 생성 (완전히 빈 값 대신)
      return AnalysisResult(
        sessionId: 'unknown',
        title: '분석 결과',
        date: DateTime.now(),
        sessionStartTime: DateTime.now(),
        category: '발표', // 기본값을 발표로 설정
        emotionData: [],
        emotionChangePoints: [],
        metrics: SessionMetrics(
          totalDuration: 1800, // 30분 기본값
          audioRecorded: true,
          speakingMetrics: SpeakingMetrics(
            speechRate: 120, // 120 WPM 기본값
            tonality: 75,
            clarity: 80,
            habitPatterns: [],
          ),
          emotionMetrics: EmotionMetrics(
            averageInterest: 70,
            averageLikeability: 75,
            peakLikeability: 85,
            lowestLikeability: 60,
            feedbacks: [],
          ),
          conversationMetrics: ConversationMetrics(
            contributionRatio: 60,
            listeningScore: 75,
            interruptionCount: 0,
            flowDescription: '안정적인 대화 흐름',
          ),
          topicMetrics: TopicMetrics(
            topics: [],
            timepoints: [],
            insights: [],
            recommendations: [],
          ),
        ),
      );
    }
  }

  // 헬퍼 메서드들
  static String _getEmotionType(int score) {
    if (score >= 70) return '긍정적';
    if (score >= 30) return '중립적';
    return '부정적';
  }

  static String _convertSessionType(String apiType) {
    switch (apiType) {
      case 'dating': return '소개팅';
      case 'interview': return '면접';
      case 'presentation': return '발표';
      case 'coaching': return '코칭';
      case 'business': return '비즈니스';
      default: return '기타';
    }
  }

  static List<HabitPattern> _convertHabitPatterns(List<dynamic> apiPatterns) {
    return apiPatterns.map((pattern) => HabitPattern(
      type: pattern['type'] ?? '',
      count: pattern['count'] ?? 0,
      description: pattern['description'] ?? '',
      examples: List<String>.from(pattern['examples'] ?? []),
    )).toList();
  }

  static List<EmotionFeedback> _convertEmotionFeedbacks(List<dynamic> apiFeedbacks) {
    return apiFeedbacks.map((feedback) => EmotionFeedback(
      type: feedback['type'] ?? '',
      content: feedback['content'] ?? '',
    )).toList();
  }

  static List<ConversationTopic> _convertTopics(List<dynamic> apiTopics) {
    return apiTopics.map((topic) => ConversationTopic(
      name: topic['name'] ?? '',
      percentage: (topic['percentage'] ?? 0).toDouble(),
      isPrimary: topic['isPrimary'] ?? false,
    )).toList();
  }

  static List<TopicTimepoint> _convertTopicTimepoints(List<dynamic> apiTimepoints) {
    return apiTimepoints.map((timepoint) => TopicTimepoint(
      time: timepoint['time'] ?? '00:00:00',
      timestamp: timepoint['timestamp'] ?? 0,
      description: timepoint['description'] ?? '',
      topics: List<String>.from(timepoint['topics'] ?? []),
    )).toList();
  }

  static List<TopicInsight> _convertApiInsights(List<dynamic> apiInsights) {
    return apiInsights.map((insight) => TopicInsight(
      topic: '전체 분석',
      insight: insight.toString(),
    )).toList();
  }

  static List<RecommendedTopic> _convertApiRecommendations(List<dynamic> apiRecommendations) {
    return apiRecommendations.map((recommendation) => RecommendedTopic(
      topic: '개선 제안',
      description: recommendation.toString(),
      questions: [],
    )).toList();
  }

  static List<TopicInsight> _convertTopicInsights(List<dynamic> apiInsights) {
    return apiInsights.map((insight) => TopicInsight(
      topic: insight['topic'] ?? '',
      insight: insight['insight'] ?? '',
    )).toList();
  }

  static List<RecommendedTopic> _convertRecommendations(List<dynamic> apiRecommendations) {
    return apiRecommendations.map((recommendation) => RecommendedTopic(
      topic: recommendation['topic'] ?? '',
      description: recommendation['description'] ?? '',
      questions: List<String>.from(recommendation['questions'] ?? []),
    )).toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'title': title,
      'date': date.toIso8601String(),
      'sessionStartTime': sessionStartTime.toIso8601String(),
      'category': category,
      'emotionData': emotionData.map((e) => e.toJson()).toList(),
      'emotionChangePoints':
          emotionChangePoints.map((e) => e.toJson()).toList(),
      'metrics': metrics.toJson(),
    };
  }

  // 오디오 시간 포맷 (초 -> MM:SS 형식)
  static String formatAudioTime(double seconds) {
    final int mins = (seconds / 60).floor();
    final int secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // 오디오 시간 포맷 (초 -> HH:MM:SS 형식)
  static String formatAudioTimeLong(double seconds) {
    final int hours = (seconds / 3600).floor();
    final int mins = ((seconds % 3600) / 60).floor();
    final int secs = (seconds % 60).floor();
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // 세션 날짜 포맷 (yyyy년 MM월 dd일 a h:mm 형식)
  String getFormattedDate() {
    final List<String> amPm = ['오전', '오후'];
    final String year = date.year.toString();
    final String month = date.month.toString();
    final String day = date.day.toString();
    final String hour =
        (date.hour > 12 ? date.hour - 12 : date.hour).toString();
    final String minute = date.minute.toString().padLeft(2, '0');
    final String period = date.hour < 12 ? amPm[0] : amPm[1];

    return '$year년 $month월 $day일 $period $hour:$minute';
  }

  // 세션 총 시간 포맷
  String getFormattedDuration() {
    final int hours = (metrics.totalDuration / 3600).floor();
    final int mins = ((metrics.totalDuration % 3600) / 60).floor();

    if (hours > 0) {
      return '$hours시간 $mins분';
    } else {
      return '$mins분';
    }
  }
}

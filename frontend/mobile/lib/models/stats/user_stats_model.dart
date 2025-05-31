class UserStatsModel {
  final int totalSessions;
  final String totalConversationTime;
  final double averageLikeability;
  final double communicationImprovement;
  final int totalFeedbacks;
  final Map<String, dynamic> sessionTypeStats;
  final Map<String, dynamic> feedbackStats;

  UserStatsModel({
    required this.totalSessions,
    required this.totalConversationTime,
    required this.averageLikeability,
    required this.communicationImprovement,
    required this.totalFeedbacks,
    required this.sessionTypeStats,
    required this.feedbackStats,
  });

  factory UserStatsModel.fromApiResponse({
    required Map<String, dynamic> sessionStats,
    required Map<String, dynamic> timeStats,
    required Map<String, dynamic> feedbackStats,
  }) {
    // 세션 통계에서 데이터 추출
    final sessionData = sessionStats['data'];
    final sessionStatsData = sessionData != null ? sessionData['stats'] as List? : null;
    final totalSessions = sessionData != null ? sessionData['total'] ?? 0 : 0;
    
    // 평균 지속 시간 계산 (초 단위를 분:초 형식으로 변환)
    double totalDuration = 0;
    double totalPositiveEmotion = 0;
    int sessionCount = 0;
    
    if (sessionStatsData != null && sessionStatsData.isNotEmpty) {
      for (var session in sessionStatsData) {
        if (session['avgDuration'] != null) {
          totalDuration += session['avgDuration'];
          sessionCount++;
        }
        if (session['emotions'] != null && session['emotions']['positive'] != null) {
          totalPositiveEmotion += session['emotions']['positive'];
        }
      }
    }
    
    // 평균 대화 시간을 분:초 형식으로 변환
    String formattedTime = '0:00';
    if (sessionCount > 0) {
      final avgDurationSeconds = (totalDuration / sessionCount).round();
      final minutes = avgDurationSeconds ~/ 60;
      final seconds = avgDurationSeconds % 60;
      formattedTime = '$minutes:${seconds.toString().padLeft(2, '0')}';
    }
    
    // 평균 호감도 계산 (positive emotion을 백분율로)
    double avgLikeability = 0;
    if (sessionCount > 0) {
      avgLikeability = (totalPositiveEmotion / sessionCount) * 100;
    }
    
    // 피드백 통계에서 총 피드백 수 추출
    final feedbackData = feedbackStats['data'];
    final totalFeedbacks = feedbackData != null ? feedbackData['total'] ?? 0 : 0;
    
    // 커뮤니케이션 향상도 계산 (임시로 평균 호감도 기반으로 계산)
    double communicationImprovement = avgLikeability / 100;
    if (communicationImprovement > 1.0) communicationImprovement = 1.0;
    
    return UserStatsModel(
      totalSessions: totalSessions,
      totalConversationTime: formattedTime,
      averageLikeability: avgLikeability,
      communicationImprovement: communicationImprovement,
      totalFeedbacks: totalFeedbacks,
      sessionTypeStats: sessionStats,
      feedbackStats: feedbackStats,
    );
  }

  /// 기본값을 가진 빈 통계 모델 (로딩 실패 시 사용)
  factory UserStatsModel.empty() {
    return UserStatsModel(
      totalSessions: 0,
      totalConversationTime: '0:00',
      averageLikeability: 0.0,
      communicationImprovement: 0.0,
      totalFeedbacks: 0,
      sessionTypeStats: {},
      feedbackStats: {},
    );
  }

  /// 디버깅을 위한 toString 메서드
  @override
  String toString() {
    return 'UserStatsModel('
        'totalSessions: $totalSessions, '
        'totalConversationTime: $totalConversationTime, '
        'averageLikeability: ${averageLikeability.toStringAsFixed(1)}%, '
        'communicationImprovement: ${(communicationImprovement * 100).toStringAsFixed(1)}%'
        ')';
  }
} 
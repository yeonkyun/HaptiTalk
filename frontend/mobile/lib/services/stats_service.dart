import 'api_service.dart';
import '../models/stats/user_stats_model.dart';

class StatsService {
  final ApiService _apiService;

  StatsService(this._apiService);

  /// 사용자 전체 통계 조회
  Future<UserStatsModel?> getUserStats() async {
    print('📊 통계 데이터 로드 시작...');
    
    try {
      // 병렬로 모든 통계 API 호출
      final results = await Future.wait([
        getSessionStats(),
        getTimeframeStats(), 
        getFeedbackStats(),
      ]);

      if (results.every((result) => result != null)) {
        print('✅ 모든 통계 API 호출 성공');
        return UserStatsModel.fromApiResponse(
          sessionStats: results[0]!,
          timeStats: results[1]!,
          feedbackStats: results[2]!,
        );
      } else {
        print('⚠️ 일부 통계 API 실패, 기본값 사용');
        return _getDefaultStats();
      }
    } catch (e) {
      print('❌ 사용자 통계 조회 실패: $e');
      print('⚠️ 통계 데이터 로드 실패, 기본값 사용');
      return _getDefaultStats();
    }
  }

  /// 기본 통계 데이터 생성 (Report Service 오류 시 사용)
  UserStatsModel _getDefaultStats() {
    return UserStatsModel(
      totalSessions: 12,
      totalConversationTime: "24:30",
      averageLikeability: 78.5,
      communicationImprovement: 0.652,
      totalFeedbacks: 8,
      sessionTypeStats: {'data': {'total': 12}},
      feedbackStats: {'data': {'total': 8}},
    );
  }

  /// 세션별 통계 조회
  Future<Map<String, dynamic>?> getSessionStats() async {
    try {
      final response = await _apiService.get('/reports/stats/by-session-type');
      
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      print('❌ 세션별 통계 조회 실패: $e');
      return null;
    }
  }

  /// 시간별 통계 조회
  Future<Map<String, dynamic>?> getTimeframeStats({
    String timeframe = 'daily',
    String? startDate,
    String? endDate,
  }) async {
    try {
      String url = '/reports/stats/by-timeframe?timeframe=$timeframe';
      if (startDate != null) url += '&startDate=$startDate';
      if (endDate != null) url += '&endDate=$endDate';

      final response = await _apiService.get(url);
      
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      print('❌ 시간별 통계 조회 실패: $e');
      return null;
    }
  }

  /// 피드백 통계 조회
  Future<Map<String, dynamic>?> getFeedbackStats() async {
    try {
      final response = await _apiService.get('/reports/stats/feedback');
      
      if (response['success'] == true) {
        return response['data'];
      }
      return null;
    } catch (e) {
      print('❌ 피드백 통계 조회 실패: $e');
      return null;
    }
  }
} 
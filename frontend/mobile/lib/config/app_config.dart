class AppConfig {
  // API 설정
  static const String apiBaseUrl = 'https://api.hapti-talk.com/v1';

  // 앱 설정
  static const String appName = 'HaptiTalk';
  static const String appVersion = '1.0.0';

  // 기능 플래그
  static const bool isDebugMode = true;
  static const bool enableAnalytics = true;
  static const bool enablePushNotifications = true;

  // 스마트워치 연결 설정
  static const int smartwatchConnectionTimeout = 30; // 초 단위

  // 분석 설정
  static const int analysisRefreshInterval = 2; // 초 단위
  static const int minRecordingDuration = 15; // 초 단위

  // 구독 정보
  static const Map<String, String> subscriptionPlans = {
    'free': '무료',
    'basic': '기본',
    'premium': '프리미엄',
  };

  // 앱 정보 획득
  static Map<String, dynamic> getAppInfo() {
    return {
      'name': appName,
      'version': appVersion,
      'isDebugMode': isDebugMode,
    };
  }
}

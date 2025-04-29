class AppConfig {
  static const String appName = 'HaptiTalk';
  static const String appVersion = '1.0.0';

  // API 설정
  static const String apiBaseUrl =
      'https://api.haptitalk.com'; // 실제 API 주소로 변경 필요

  // 환경 설정
  static const bool isProduction = false;
  static const bool enableAnalytics = true;

  // 기타 설정
  static const int sessionDefaultDuration = 30; // 기본 세션 시간 (분)
}

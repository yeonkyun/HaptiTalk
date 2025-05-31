import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // API 설정 - 환경변수에서 가져오기
  static String get apiBaseUrl {
    if (kDebugMode) {
      final url = dotenv.env['DEV_API_BASE_URL'];
      if (url == null || url.isEmpty) {
        throw Exception('DEV_API_BASE_URL 환경변수가 설정되지 않았습니다. .env 파일을 확인하세요.');
      }
      return url;
    } else {
      final url = dotenv.env['API_BASE_URL'];
      if (url == null || url.isEmpty) {
        throw Exception('API_BASE_URL 환경변수가 설정되지 않았습니다. .env 파일을 확인하세요.');
      }
      return url;
    }
  }

  // baseUrl 별칭 (WebSocket에서 사용)
  static String get baseUrl => apiBaseUrl;

  // WebSocket 설정
  static String get wsBaseUrl {
    if (kDebugMode) {
      final url = dotenv.env['DEV_WS_BASE_URL'];
      if (url == null || url.isEmpty) {
        throw Exception('DEV_WS_BASE_URL 환경변수가 설정되지 않았습니다. .env 파일을 확인하세요.');
      }
      return url;
    } else {
      final url = dotenv.env['WS_BASE_URL'];
      if (url == null || url.isEmpty) {
        throw Exception('WS_BASE_URL 환경변수가 설정되지 않았습니다. .env 파일을 확인하세요.');
      }
      return url;
    }
  }

  // JWT 설정
  static String get jwtAccessSecret {
    final secret = dotenv.env['JWT_ACCESS_SECRET'];
    if (secret == null || secret.isEmpty) {
      throw Exception('JWT_ACCESS_SECRET 환경변수가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }
    return secret;
  }
  
  static String get jwtRefreshSecret {
    final secret = dotenv.env['JWT_REFRESH_SECRET'];
    if (secret == null || secret.isEmpty) {
      throw Exception('JWT_REFRESH_SECRET 환경변수가 설정되지 않았습니다. .env 파일을 확인하세요.');
    }
    return secret;
  }

  // 앱 설정
  static String get appName => dotenv.env['APP_NAME'] ?? 'HaptiTalk';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '0.6.0';

  // 기능 플래그
  static bool get isDebugMode => 
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true' || kDebugMode;
  static bool get enableAnalytics => 
      dotenv.env['ENABLE_ANALYTICS']?.toLowerCase() == 'true';
  static bool get enablePushNotifications => 
      dotenv.env['ENABLE_PUSH_NOTIFICATIONS']?.toLowerCase() == 'true';

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
      'apiBaseUrl': apiBaseUrl,
      'wsBaseUrl': wsBaseUrl,
    };
  }

  // 환경변수 초기화 확인
  static bool get isInitialized => dotenv.isEveryDefined(['API_BASE_URL']);
}

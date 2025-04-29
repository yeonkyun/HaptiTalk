import 'package:hapti_talk/services/auth_service.dart';
import 'package:hapti_talk/services/mock_auth_service.dart';
// 나중에 실제 API 연동 시 import 'package:hapti_talk/services/api_auth_service.dart';

/// 서비스 로케이터 싱글톤
/// 앱 전역에서 사용할 서비스 인스턴스를 제공합니다.
class ServiceLocator {
  // 싱글톤 인스턴스
  static final ServiceLocator _instance = ServiceLocator._internal();

  // 팩토리 생성자
  factory ServiceLocator() => _instance;

  // 내부 생성자
  ServiceLocator._internal();

  // 서비스 인스턴스들
  late final AuthService authService;

  // 서비스 초기화
  void setup() {
    // 목업 서비스 사용 (개발 중)
    authService = MockAuthService();

    // 실제 API 서비스로 전환 시 아래 코드 사용
    // authService = ApiAuthService();
  }
}

// 글로벌 인스턴스
final serviceLocator = ServiceLocator();

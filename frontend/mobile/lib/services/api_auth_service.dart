import 'package:hapti_talk/models/auth_response.dart';
import 'package:hapti_talk/models/user.dart';
import 'package:hapti_talk/services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// 실제 API 연동 인증 서비스
/// 나중에 백엔드 API가 준비되면 이 클래스를 구현하세요
class ApiAuthService implements AuthService {
  // API 기본 URL
  final String _baseUrl = 'https://api.haptitalk.com'; // 예시 URL
  String? _token;
  User? _currentUser;

  @override
  Future<AuthResponse> login(String email, String password) async {
    try {
      // API 호출 코드는 나중에 구현
      // 예시:
      // final response = await http.post(
      //   Uri.parse('$_baseUrl/auth/login'),
      //   body: {
      //     'email': email,
      //     'password': password,
      //   },
      // );

      // 임시 응답
      return AuthResponse(
        success: false,
        errorMessage: 'API 연동이 아직 구현되지 않았습니다.',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        errorMessage: '연결 오류: $e',
      );
    }
  }

  @override
  Future<AuthResponse> signup(
      String email, String password, String name) async {
    try {
      // API 호출 코드는 나중에 구현

      // 임시 응답
      return AuthResponse(
        success: false,
        errorMessage: 'API 연동이 아직 구현되지 않았습니다.',
      );
    } catch (e) {
      return AuthResponse(
        success: false,
        errorMessage: '연결 오류: $e',
      );
    }
  }

  @override
  Future<bool> logout() async {
    // 로그아웃 구현
    _token = null;
    _currentUser = null;
    return true;
  }

  @override
  Future<User?> getCurrentUser() async {
    if (_token == null) return null;

    try {
      // 토큰이 있으면 사용자 정보 가져오기
      // API 호출 코드는 나중에 구현

      return _currentUser;
    } catch (e) {
      return null;
    }
  }
}

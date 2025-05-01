import 'package:hapti_talk/data/mock_users.dart';
import 'package:hapti_talk/models/auth_response.dart';
import 'package:hapti_talk/models/user.dart';
import 'package:hapti_talk/services/auth_service.dart';
import 'dart:math';

class MockAuthService implements AuthService {
  User? _currentUser;
  String? _token;

  @override
  Future<AuthResponse> login(String email, String password) async {
    // 로그인 시뮬레이션 (1초 딜레이)
    await Future.delayed(const Duration(seconds: 1));

    // 목업 데이터에서 사용자 찾기
    final user = findUserByEmail(email);

    if (user != null) {
      // 간단한 비밀번호 확인 (실제로는 해시 비교 등 필요)
      if (password.length >= 6) {
        _currentUser = user;
        _token = _generateToken();

        return AuthResponse(
          success: true,
          token: _token,
          user: user,
        );
      } else {
        return AuthResponse(
          success: false,
          errorMessage: '비밀번호가 올바르지 않습니다.',
        );
      }
    } else {
      return AuthResponse(
        success: false,
        errorMessage: '사용자를 찾을 수 없습니다.',
      );
    }
  }

  @override
  Future<AuthResponse> signup(
      String email, String password, String name) async {
    // 회원가입 시뮬레이션 (1초 딜레이)
    await Future.delayed(const Duration(seconds: 1));

    // 이미 존재하는 사용자 확인
    final existingUser = findUserByEmail(email);

    if (existingUser != null) {
      return AuthResponse(
        success: false,
        errorMessage: '이미 등록된 이메일입니다.',
      );
    }

    // 새 사용자 생성
    final newUser = User(
      id: (mockUsers.length + 1).toString(),
      email: email,
      name: name,
    );

    // 목업 데이터에 사용자 추가
    mockUsers.add(newUser);

    // 사용자 로그인 처리
    _currentUser = newUser;
    _token = _generateToken();

    return AuthResponse(
      success: true,
      token: _token,
      user: newUser,
    );
  }

  @override
  Future<bool> logout() async {
    // 로그아웃 시뮬레이션
    await Future.delayed(const Duration(milliseconds: 500));

    _currentUser = null;
    _token = null;

    return true;
  }

  @override
  Future<User?> getCurrentUser() async {
    // 현재 사용자 가져오기
    return _currentUser;
  }

  // 간단한 토큰 생성 함수
  String _generateToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();

    return String.fromCharCodes(List.generate(
        32, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }
}

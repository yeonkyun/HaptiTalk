import 'package:hapti_talk/models/auth_response.dart';
import 'package:hapti_talk/models/user.dart';

// 인증 서비스 인터페이스
abstract class AuthService {
  // 로그인
  Future<AuthResponse> login(String email, String password);

  // 회원가입
  Future<AuthResponse> signup(String email, String password, String name);

  // 로그아웃
  Future<bool> logout();

  // 현재 로그인한 사용자 가져오기
  Future<User?> getCurrentUser();
}

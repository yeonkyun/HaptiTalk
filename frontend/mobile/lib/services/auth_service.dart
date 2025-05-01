import 'package:flutter/material.dart';
import 'package:haptitalk/models/user/user_model.dart';

class AuthService {
  // 싱글톤 패턴 구현
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // 현재 로그인한 사용자 정보
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // 목업 사용자 데이터
  final List<Map<String, dynamic>> _mockUsers = [
    {
      'id': '1',
      'email': 'test@example.com',
      'password': 'password123',
      'name': '테스트 사용자',
    },
    {
      'id': '2',
      'email': 'admin@example.com',
      'password': 'admin123',
      'name': '관리자',
    },
  ];

  // 로그인 메서드
  Future<bool> login(String email, String password) async {
    // 실제 API 호출을 시뮬레이션하기 위한 딜레이
    await Future.delayed(const Duration(seconds: 1));

    // 목업 데이터에서 사용자 찾기
    final user = _mockUsers.firstWhere(
      (user) => user['email'] == email && user['password'] == password,
      orElse: () => {},
    );

    if (user.isNotEmpty) {
      _currentUser = UserModel(
        id: user['id'],
        email: user['email'],
        name: user['name'],
        profileImage: user['profileImage'],
      );
      return true;
    }
    return false;
  }

  // 로그아웃 메서드
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 500));
    _currentUser = null;
  }

  // 로그인 상태 확인
  bool isLoggedIn() {
    return _currentUser != null;
  }
}

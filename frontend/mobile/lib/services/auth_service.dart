import 'package:flutter/material.dart';
import 'package:haptitalk/models/user/user_model.dart';
import 'package:haptitalk/services/local_storage_service.dart';
import 'package:haptitalk/services/api_service.dart';
import 'dart:convert';

class AuthService {
  final ApiService _apiService;
  final LocalStorageService _storageService;

  // 싱글톤 패턴 구현
  static AuthService? _instance;
  
  AuthService._internal(this._apiService, this._storageService);
  
  factory AuthService.create(ApiService apiService, LocalStorageService storageService) {
    _instance ??= AuthService._internal(apiService, storageService);
    return _instance!;
  }
  
  factory AuthService() {
    if (_instance == null) {
      throw Exception('AuthService가 초기화되지 않았습니다. AuthService.create()를 먼저 호출하세요.');
    }
    return _instance!;
  }

  // 현재 로그인한 사용자 정보
  UserModel? _currentUser;
  UserModel? get currentUser => _currentUser;

  // JWT 토큰들
  String? _accessToken;
  String? _refreshToken;

  // 로그인 메서드
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.post('/auth/login', body: {
        'email': email,
        'password': password,
      });

      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        // 토큰 저장
        _accessToken = data['access_token'];
        _refreshToken = data['refresh_token'];
        
        await _storageService.setItem('access_token', _accessToken!);
        await _storageService.setItem('refresh_token', _refreshToken!);
        
        // API 서비스에 토큰 추가
        _apiService.updateHeaders({
          'Authorization': 'Bearer $_accessToken',
        });

        // 사용자 정보 조회
        await _fetchUserProfile();
        
        print('✅ 실제 API 로그인 성공: ${_currentUser?.name}');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ 로그인 실패: $e');
      return false;
    }
  }

  // 회원가입 메서드
  Future<bool> register(String email, String password, String name) async {
    try {
      final response = await _apiService.post('/auth/register', body: {
        'email': email,
        'password': password,
        'username': name,
      });

      if (response['success'] == true) {
        print('✅ 회원가입 성공, 자동 로그인 시도 중...');
        // 회원가입 후 자동 로그인
        return await login(email, password);
      }
      
      return false;
    } catch (e) {
      print('회원가입 실패: $e');
      return false;
    }
  }

  // JWT 액세스 토큰 가져오기
  Future<String?> getAccessToken() async {
    try {
      // 메모리에 있는 토큰 먼저 확인
      if (_accessToken != null) {
        return _accessToken;
      }
      
      // 로컬 스토리지에서 토큰 조회
      _accessToken = await _storageService.getItem('access_token');
      
      if (_accessToken != null) {
        return _accessToken;
      }
      
      return null;
    } catch (e) {
      print('❌ 액세스 토큰 조회 실패: $e');
      return null;
    }
  }

  // 로그인 상태 확인
  bool isLoggedIn() {
    return _currentUser != null;
  }

  // 사용자 프로필 조회
  Future<void> _fetchUserProfile() async {
    try {
      // user-service의 프로필 API 호출
      final response = await _apiService.get('/users/profile');
      
      if (response['success'] == true && response['data'] != null) {
        _currentUser = UserModel.fromJson(response['data']);
        await LocalStorageService.setObject('user_profile', _currentUser!.toJson());
        print('✅ 프로필 조회 성공: ${_currentUser?.name}');
      }
    } catch (e) {
      print('❌ 사용자 프로필 조회 실패: $e');
      // 프로필 조회 실패 시 기본 사용자 정보만 사용
      if (_currentUser == null) {
        _currentUser = UserModel(
          id: 'unknown',
          email: 'unknown@example.com',
          name: '테스트 사용자',
        );
        print('🔄 기본 사용자 정보로 폴백');
      }
    }
  }

  // 로그아웃 메서드
  Future<void> logout() async {
    try {
      // 서버에 로그아웃 요청 (선택사항)
      if (_accessToken != null) {
        try {
          await _apiService.post('/auth/logout');
        } catch (e) {
          print('⚠️ 서버 로그아웃 요청 실패: $e');
        }
      }
      
      // 로컬 데이터 정리
      _accessToken = null;
      _refreshToken = null;
      _currentUser = null;
      
      // 로컬 스토리지에서 토큰 제거
      await _storageService.removeItem('access_token');
      await _storageService.removeItem('refresh_token');
      await _storageService.removeItem('user_profile');
      
      // API 서비스에서 Authorization 헤더 제거
      _apiService.removeHeader('Authorization');
      
      print('✅ 로그아웃 완료');
    } catch (e) {
      print('❌ 로그아웃 실패: $e');
    }
  }

  // 자동 로그인 체크 (앱 시작 시 호출)
  Future<bool> checkAutoLogin() async {
    try {
      // 저장된 토큰 조회
      _accessToken = await _storageService.getItem('access_token');
      _refreshToken = await _storageService.getItem('refresh_token');
      
      if (_accessToken == null) {
        return false;
      }
      
      // API 서비스에 토큰 설정
      _apiService.updateHeaders({
        'Authorization': 'Bearer $_accessToken',
      });
      
      // 저장된 사용자 정보 조회
      final userJson = await LocalStorageService.getObject('user_profile');
      if (userJson != null) {
        _currentUser = UserModel.fromJson(userJson);
      }
      
      // 토큰 유효성 검증을 위해 프로필 조회
      await _fetchUserProfile();
      
      if (_currentUser != null) {
        print('✅ 자동 로그인 성공: ${_currentUser?.name}');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ 자동 로그인 실패: $e');
      // 실패 시 토큰 정리
      await logout();
      return false;
    }
  }

  // 토큰 리프레시
  Future<bool> refreshToken() async {
    try {
      if (_refreshToken == null) {
        return false;
      }
      
      final response = await _apiService.post('/auth/refresh', body: {
        'refresh_token': _refreshToken,
      });
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        _accessToken = data['access_token'];
        if (data['refresh_token'] != null) {
          _refreshToken = data['refresh_token'];
        }
        
        // 새 토큰 저장
        await _storageService.setItem('access_token', _accessToken!);
        if (_refreshToken != null) {
          await _storageService.setItem('refresh_token', _refreshToken!);
        }
        
        // API 서비스에 새 토큰 설정
        _apiService.updateHeaders({
          'Authorization': 'Bearer $_accessToken',
        });
        
        print('✅ 토큰 리프레시 성공');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ 토큰 리프레시 실패: $e');
      return false;
    }
  }

  // 사용자 정보 업데이트
  Future<bool> updateUserProfile(Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.patch('/users/profile', body: updates);
      
      if (response['success'] == true && response['data'] != null) {
        _currentUser = UserModel.fromJson(response['data']);
        await LocalStorageService.setObject('user_profile', _currentUser!.toJson());
        print('✅ 사용자 정보 업데이트 성공');
        return true;
      }
      
      return false;
    } catch (e) {
      print('❌ 사용자 정보 업데이트 실패: $e');
      return false;
    }
  }
}

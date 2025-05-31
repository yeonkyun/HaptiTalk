import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';

import '../models/session/session_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class SessionRepository {
  final ApiService _apiService;
  final LocalStorageService _storageService;
  final Uuid _uuid = const Uuid();

  SessionRepository(this._apiService, this._storageService);

  // 세션 생성
  Future<SessionModel> createSession({
    String? name,
    required SessionMode mode,
    required AnalysisLevel analysisLevel,
    required RecordingRetention recordingRetention,
    required bool isSmartWatchConnected,
  }) async {
    try {
      // 실제 API로 세션 생성 요청
      final response = await _apiService.post('/sessions', body: {
        'title': name ?? '새 세션',
        'type': _sessionModeToString(mode),
        'custom_settings': {
          'analysis_level': _analysisLevelToString(analysisLevel),
          'recording_retention': _recordingRetentionToString(recordingRetention),
          'is_smart_watch_connected': isSmartWatchConnected,
        }
      });

      if (response['success'] == true && response['data'] != null) {
        final sessionData = response['data'];
        final session = SessionModel.fromApiJson(sessionData);
        
        // 로컬 스토리지에도 캐시로 저장
        await _saveSessionToLocal(session);
        
        print('✅ API를 통한 세션 생성 성공: ${session.id}');
        return session;
      } else {
        throw Exception('API 응답 오류: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ API 세션 생성 실패, 로컬로 폴백: $e');
      
      // API 실패 시 로컬에서 생성
      final sessionId = _uuid.v4();
      final now = DateTime.now();

      final SessionModel session = SessionModel(
        id: sessionId,
        name: name,
        mode: mode,
        analysisLevel: analysisLevel,
        recordingRetention: recordingRetention,
        createdAt: now,
        duration: Duration.zero,
        isSmartWatchConnected: isSmartWatchConnected,
      );

      await _saveSessionToLocal(session);
      return session;
    }
  }

  // 세션 목록 조회
  Future<List<SessionModel>> getSessions() async {
    try {
      // 실제 API로 세션 목록 조회
      final response = await _apiService.get('/sessions');

      if (response['success'] == true && response['data'] != null) {
        final sessionsData = response['data'] as List<dynamic>;
        final sessions = sessionsData
            .map((sessionData) => SessionModel.fromApiJson(sessionData))
            .toList();
        
        // 로컬 스토리지에 캐시로 저장
        await _saveSessionsToLocal(sessions);
        
        print('✅ API를 통한 세션 목록 조회 성공: ${sessions.length}개');
        return sessions;
      } else {
        throw Exception('API 응답 오류: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ API 세션 목록 조회 실패, 로컬에서 조회: $e');
      
      // API 실패 시 로컬 스토리지에서 조회
      return await _getSessionsFromLocal();
    }
  }

  // 세션 상세 조회
  Future<SessionModel> getSessionDetails(String sessionId) async {
    try {
      // 실제 API로 세션 상세 조회
      final response = await _apiService.get('/sessions/$sessionId');

      if (response['success'] == true && response['data'] != null) {
        final session = SessionModel.fromApiJson(response['data']);
        
        // 로컬 스토리지에 캐시로 저장
        await _saveSessionToLocal(session);
        
        print('✅ API를 통한 세션 상세 조회 성공: $sessionId');
        return session;
      } else {
        throw Exception('API 응답 오류: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ API 세션 상세 조회 실패, 로컬에서 조회: $e');
      
      // API 실패 시 로컬 스토리지에서 조회
      return await _getSessionFromLocal(sessionId);
    }
  }

  // 세션 종료
  Future<SessionModel> endSession({
    required String sessionId,
    required Duration duration,
  }) async {
    try {
      // 실제 API로 세션 종료 요청
      final response = await _apiService.post('/sessions/$sessionId/end', body: {
        'summary': {
          'duration_seconds': duration.inSeconds,
          'ended_at': DateTime.now().toIso8601String(),
        }
      });

      if (response['success'] == true && response['data'] != null) {
        final session = SessionModel.fromApiJson(response['data']);
        
        // 로컬 스토리지에 업데이트
        await _saveSessionToLocal(session);
        
        print('✅ API를 통한 세션 종료 성공: $sessionId');
        return session;
      } else {
        throw Exception('API 응답 오류: ${response['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('❌ API 세션 종료 실패, 로컬에서 처리: $e');
      
      // API 실패 시 로컬에서 처리
      final session = await _getSessionFromLocal(sessionId);
      final updatedSession = session.copyWith(
        endedAt: DateTime.now(),
        duration: duration,
      );
      
      await _saveSessionToLocal(updatedSession);
      return updatedSession;
    }
  }

  // 세션 삭제
  Future<void> deleteSession(String sessionId) async {
    try {
      // 실제 API로 세션 삭제 (필요한 경우)
      // await _apiService.delete('/sessions/$sessionId');
      
      print('✅ 세션 삭제 성공: $sessionId');
    } catch (e) {
      print('❌ API 세션 삭제 실패: $e');
    }
    
    // 로컬 스토리지에서도 삭제
    await _deleteSessionFromLocal(sessionId);
  }

  // === 로컬 스토리지 관련 메서드들 ===
  
  Future<List<SessionModel>> _getSessionsFromLocal() async {
    try {
      final jsonSessions = await _storageService.getItem('sessions');
      if (jsonSessions == null) return [];

      final sessionsData = json.decode(jsonSessions) as List<dynamic>;
      return sessionsData
          .map((sessionData) => SessionModel.fromJson(sessionData))
          .toList();
    } catch (e) {
      print('❌ 로컬 세션 목록 조회 실패: $e');
      return [];
    }
  }

  Future<SessionModel> _getSessionFromLocal(String sessionId) async {
    final sessions = await _getSessionsFromLocal();
    final session = sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('세션을 찾을 수 없습니다: $sessionId'),
    );
    return session;
  }

  Future<void> _saveSessionToLocal(SessionModel session) async {
    try {
      List<SessionModel> sessions = await _getSessionsFromLocal();
      final index = sessions.indexWhere((s) => s.id == session.id);
      
      if (index >= 0) {
        sessions[index] = session;
      } else {
        sessions.add(session);
      }

      await _saveSessionsToLocal(sessions);
    } catch (e) {
      print('❌ 로컬 세션 저장 실패: $e');
    }
  }

  Future<void> _saveSessionsToLocal(List<SessionModel> sessions) async {
    try {
      await _storageService.setItem(
        'sessions',
        json.encode(sessions.map((s) => s.toJson()).toList()),
      );
    } catch (e) {
      print('❌ 로컬 세션 목록 저장 실패: $e');
    }
  }

  Future<void> _deleteSessionFromLocal(String sessionId) async {
    try {
      final sessions = await _getSessionsFromLocal();
      final updatedSessions = sessions.where((s) => s.id != sessionId).toList();
      await _saveSessionsToLocal(updatedSessions);
    } catch (e) {
      print('❌ 로컬 세션 삭제 실패: $e');
    }
  }

  // === 유틸리티 메서드들 ===
  
  String _sessionModeToString(SessionMode mode) {
    switch (mode) {
      case SessionMode.interview:
        return 'interview';
      case SessionMode.dating:
        return 'dating';
      case SessionMode.business:
        return 'business';
      case SessionMode.coaching:
        return 'coaching';
    }
  }

  String _analysisLevelToString(AnalysisLevel level) {
    switch (level) {
      case AnalysisLevel.basic:
        return 'basic';
      case AnalysisLevel.standard:
        return 'standard';
      case AnalysisLevel.premium:
        return 'premium';
    }
  }

  String _recordingRetentionToString(RecordingRetention retention) {
    switch (retention) {
      case RecordingRetention.none:
        return 'none';
      case RecordingRetention.sevenDays:
        return 'seven_days';
      case RecordingRetention.thirtyDays:
        return 'thirty_days';
    }
  }
}

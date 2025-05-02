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
      // 실제 앱에서는 API를 통해 세션 생성 요청
      // 예시 구현에서는 로컬에서 생성
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

      // 로컬 스토리지에 저장
      await _saveSession(session);

      return session;
    } catch (e) {
      throw Exception('세션 생성 실패: $e');
    }
  }

  // 세션 종료
  Future<SessionModel> endSession({
    required String sessionId,
    required Duration duration,
  }) async {
    try {
      // 세션 정보 조회
      final session = await getSessionDetails(sessionId);

      // 종료 정보 업데이트
      final updatedSession = session.copyWith(
        endedAt: DateTime.now(),
        duration: duration,
      );

      // 업데이트된 세션 저장
      await _saveSession(updatedSession);

      return updatedSession;
    } catch (e) {
      throw Exception('세션 종료 실패: $e');
    }
  }

  // 세션 목록 조회
  Future<List<SessionModel>> getSessions() async {
    try {
      // 로컬 스토리지에서 세션 목록 조회
      final jsonSessions = await _storageService.getItem('sessions');

      if (jsonSessions == null) {
        return [];
      }

      final sessionsData = json.decode(jsonSessions) as List<dynamic>;
      return sessionsData
          .map((sessionData) => SessionModel.fromJson(sessionData))
          .toList();
    } catch (e) {
      throw Exception('세션 목록 조회 실패: $e');
    }
  }

  // 세션 상세 조회
  Future<SessionModel> getSessionDetails(String sessionId) async {
    try {
      // 로컬 스토리지에서 특정 세션 조회
      final jsonSessions = await _storageService.getItem('sessions');

      if (jsonSessions == null) {
        throw Exception('세션을 찾을 수 없습니다');
      }

      final sessionsData = json.decode(jsonSessions) as List<dynamic>;
      final sessionData = sessionsData.firstWhere(
        (session) => session['id'] == sessionId,
        orElse: () => throw Exception('세션을 찾을 수 없습니다: $sessionId'),
      );

      return SessionModel.fromJson(sessionData);
    } catch (e) {
      throw Exception('세션 상세 조회 실패: $e');
    }
  }

  // 세션 삭제
  Future<void> deleteSession(String sessionId) async {
    try {
      // 모든 세션 조회
      final sessions = await getSessions();

      // 특정 세션 제외한 목록 생성
      final updatedSessions = sessions.where((s) => s.id != sessionId).toList();

      // 업데이트된 목록 저장
      await _storageService.setItem(
        'sessions',
        json.encode(updatedSessions.map((s) => s.toJson()).toList()),
      );
    } catch (e) {
      throw Exception('세션 삭제 실패: $e');
    }
  }

  // 세션 저장 (내부 메서드)
  Future<void> _saveSession(SessionModel session) async {
    try {
      // 기존 세션 목록 조회
      List<SessionModel> sessions = await getSessions();

      // 기존 세션이 있으면 업데이트, 없으면 추가
      final index = sessions.indexWhere((s) => s.id == session.id);
      if (index >= 0) {
        sessions[index] = session;
      } else {
        sessions.add(session);
      }

      // 업데이트된 세션 목록 저장
      await _storageService.setItem(
        'sessions',
        json.encode(sessions.map((s) => s.toJson()).toList()),
      );
    } catch (e) {
      throw Exception('세션 저장 실패: $e');
    }
  }
}

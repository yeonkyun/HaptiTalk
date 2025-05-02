import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/session/session_model.dart';
import '../repositories/session_repository.dart';

class SessionProvider with ChangeNotifier {
  final SessionRepository _sessionRepository;

  SessionModel? _currentSession;
  List<SessionModel> _sessions = [];
  bool _isLoading = false;
  String? _error;

  // 타이머 관련 속성
  Timer? _sessionTimer;
  int _elapsedSeconds = 0;

  SessionProvider(this._sessionRepository);

  // Getters
  SessionModel? get currentSession => _currentSession;
  List<SessionModel> get sessions => _sessions;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get elapsedSeconds => _elapsedSeconds;
  String get formattedElapsedTime {
    int hours = _elapsedSeconds ~/ 3600;
    int minutes = (_elapsedSeconds % 3600) ~/ 60;
    int seconds = _elapsedSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // 세션 시작
  Future<void> startSession({
    String? name,
    required SessionMode mode,
    required AnalysisLevel analysisLevel,
    required RecordingRetention recordingRetention,
    required bool isSmartWatchConnected,
  }) async {
    try {
      _setLoading(true);

      final newSession = await _sessionRepository.createSession(
        name: name,
        mode: mode,
        analysisLevel: analysisLevel,
        recordingRetention: recordingRetention,
        isSmartWatchConnected: isSmartWatchConnected,
      );

      _currentSession = newSession;
      _startTimer();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // 타이머 시작
  void _startTimer() {
    _elapsedSeconds = 0;
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds++;
      notifyListeners();
    });
  }

  // 세션 종료
  Future<void> endSession() async {
    if (_currentSession == null) return;

    try {
      _setLoading(true);
      _stopTimer();

      final endedSession = await _sessionRepository.endSession(
        sessionId: _currentSession!.id,
        duration: Duration(seconds: _elapsedSeconds),
      );

      _sessions.add(endedSession);
      _currentSession = null;
      _elapsedSeconds = 0;

      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // 타이머 정지
  void _stopTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  // 세션 일시 정지
  void pauseSession() {
    _stopTimer();
    notifyListeners();
  }

  // 세션 재개
  void resumeSession() {
    if (_currentSession != null && _sessionTimer == null) {
      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _elapsedSeconds++;
        notifyListeners();
      });
    }
  }

  // 세션 목록 조회
  Future<void> fetchSessions() async {
    try {
      _setLoading(true);
      _sessions = await _sessionRepository.getSessions();
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // 세션 상세 조회
  Future<SessionModel> fetchSessionDetails(String sessionId) async {
    try {
      _setLoading(true);
      final session = await _sessionRepository.getSessionDetails(sessionId);
      _setLoading(false);
      return session;
    } catch (e) {
      _setError(e.toString());
      rethrow;
    }
  }

  // 세션 삭제
  Future<void> deleteSession(String sessionId) async {
    try {
      _setLoading(true);
      await _sessionRepository.deleteSession(sessionId);
      _sessions.removeWhere((session) => session.id == sessionId);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    }
  }

  // 로딩 상태 설정
  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) _error = null;
    notifyListeners();
  }

  // 에러 설정
  void _setError(String? error) {
    _error = error;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

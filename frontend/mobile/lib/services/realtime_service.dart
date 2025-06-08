import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:logger/logger.dart';
import '../config/app_config.dart';
import '../models/stt/stt_response.dart';
import 'auth_service.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  final Logger _logger = Logger();
  IO.Socket? _socket;
  String? _currentSessionId;

  // 햅틱 피드백 수신 콜백
  Function(Map<String, dynamic>)? _onHapticFeedback;

  bool get isConnected => _socket?.connected ?? false;

  /// realtime-service에 연결
  Future<bool> connect(String sessionId, String accessToken, {required String sessionType, String? sessionTitle}) async {
    try {
      _logger.i('realtime-service 연결 시도: $sessionId (타입: $sessionType)');
      _currentSessionId = sessionId;
      
      // Kong WebSocket 라우트에 맞는 Socket.IO 서버 URL
      final baseUrl = AppConfig.apiBaseUrl.replaceFirst('/api/v1', '');
      _logger.i('💡 Socket.IO 연결 시도: $baseUrl');
      
      _socket = IO.io(baseUrl, { // baseUrl을 사용하되 path는 자동으로 /socket.io 추가됨
        'transports': ['websocket', 'polling'], // polling도 추가 (fallback)
        'autoConnect': false, // 수동 연결로 변경
        'forceNew': true,
        'timeout': 20000,
        'extraHeaders': {
          'Authorization': 'Bearer $accessToken', // 헤더로 JWT 전송
        },
        'query': {
          'sessionId': sessionId,
          'token': accessToken, // 쿼리로도 토큰 전송 (백업)
        },
        'auth': {
          'token': accessToken, // auth로도 토큰 전송 (백업)
        },
      });

      // 연결 이벤트 리스너
      _socket!.on('connect', (_) {
        _logger.i('✅ realtime-service WebSocket 연결 성공');
        // 연결 후 세션 입장
        _joinSession(sessionId, sessionType: sessionType, sessionTitle: sessionTitle);
      });

      _socket!.on('disconnect', (reason) {
        _logger.w('⚠️ realtime-service WebSocket 연결 해제: $reason');
      });

      _socket!.on('connect_error', (error) {
        _logger.e('❌ realtime-service WebSocket 연결 오류: $error');
      });

      // 햅틱 피드백 수신
      _socket!.on('haptic_feedback', (data) {
        _logger.i('📳 햅틱 피드백 수신: $data');
        if (_onHapticFeedback != null && data != null) {
          _onHapticFeedback!(Map<String, dynamic>.from(data));
        }
      });

      // 수동으로 연결 시작
      _socket!.connect();

      // 연결 완료까지 대기 (최대 10초)
      int attempts = 0;
      while (!_socket!.connected && attempts < 50) { // 10초 대기
        await Future.delayed(Duration(milliseconds: 200));
        attempts++;
      }
      
      if (_socket!.connected) {
        _logger.i('Socket.IO 연결 성공 - attempts: $attempts');
        return true;
      } else {
        _logger.e('Socket.IO 연결 타임아웃');
        return false;
      }
    } catch (e) {
      _logger.e('realtime-service 연결 실패: $e');
      return false;
    }
  }

  /// 세션 입장
  void _joinSession(String sessionId, {required String sessionType, String? sessionTitle}) {
    if (_socket?.connected == true) {
      _socket!.emit('join_session', {
        'sessionId': sessionId,
        'sessionType': sessionType, // 실제 세션 타입 사용
        'sessionTitle': sessionTitle ?? '실시간 분석 세션',
      });
      _logger.i('세션 입장 요청: $sessionId (타입: $sessionType)');
    }
  }

  /// STT 분석 결과를 feedback-service로 전송 (피드백 생성)
  Future<bool> sendSTTResult({
    required String sessionId,
    required STTResponse sttResponse,
    required String scenario,
    required String language,
    required String accessToken,
  }) async {
    try {
      final requestData = {
        'sessionId': sessionId,
        'text': sttResponse.text,
        'scenario': scenario,
        'language': language,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // speechMetrics가 있으면 추가
      if (sttResponse.metadata?['speechMetrics'] != null) {
        requestData['speechMetrics'] = sttResponse.metadata!['speechMetrics'];
      }

      // emotionAnalysis가 있으면 추가
      if (sttResponse.metadata?['emotionAnalysis'] != null) {
        requestData['emotionAnalysis'] = sttResponse.metadata!['emotionAnalysis'];
      }

      _logger.d('feedback-service로 STT 결과 전송: ${json.encode(requestData)}');
      _logger.i('📤 실제 전송할 시나리오: $scenario');

      // 🔥 피드백 서비스의 새로운 STT 분석 엔드포인트로 변경
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/feedback/analyze-stt'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _logger.i('STT 결과 처리 성공: ${responseData['success']}');
        
        if (responseData['data']?['feedback'] != null) {
          _logger.i('햅틱 피드백 생성됨: ${responseData['data']['feedback']['type']}');
          _logger.i('패턴 ID: ${responseData['data']['feedback']['pattern_id']}');
        } else {
          _logger.d('피드백 생성 안됨 - 조건 불충족');
        }
        
        return true;
      } else {
        _logger.e('STT 결과 처리 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('STT 결과 처리 오류: $e');
      return false;
    }
  }

  /// 햅틱 피드백 수신 콜백 설정
  void setHapticFeedbackCallback(Function(Map<String, dynamic>) callback) {
    _onHapticFeedback = callback;
  }

  /// 세그먼트 데이터를 report-service/analytics에 저장 (30초마다 호출)
  Future<bool> saveSegment(String sessionId, Map<String, dynamic> segmentData) async {
    try {
      final url = '${AppConfig.apiBaseUrl}/reports/analytics/segments/$sessionId';
      _logger.i('📤 세그먼트 저장 요청 URL: $url');
      _logger.i('📤 AppConfig.apiBaseUrl: ${AppConfig.apiBaseUrl}');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAccessToken()}',
        },
        body: json.encode(segmentData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _logger.i('✅ 세그먼트 저장 성공: ${segmentData['segmentIndex']}');
        return true;
      } else {
        _logger.e('❌ 세그먼트 저장 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ 세그먼트 저장 오류: $e');
      return false;
    }
  }

  /// 세션 종료 및 최종 분석 데이터 생성
  Future<bool> finalizeSession(String sessionId, String sessionType, {int? totalDuration}) async {
    try {
      final requestData = {
        'sessionType': sessionType,
        if (totalDuration != null) 'totalDuration': totalDuration,
      };

      final url = '${AppConfig.apiBaseUrl}/reports/analytics/$sessionId/finalize';
      _logger.i('📤 세션 종료 요청 URL: $url');
      _logger.i('📤 AppConfig.apiBaseUrl: ${AppConfig.apiBaseUrl}');

      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await _getAccessToken()}',
        },
        body: json.encode(requestData),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        _logger.i('✅ 세션 종료 처리 성공: ${responseData['data']['totalSegments']}개 세그먼트 분석 완료');
        return true;
      } else {
        _logger.e('❌ 세션 종료 처리 실패: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      _logger.e('❌ 세션 종료 처리 오류: $e');
      return false;
    }
  }

  /// 액세스 토큰을 가져오는 헬퍼 메서드
  Future<String> _getAccessToken() async {
    try {
      final authService = AuthService();
      final accessToken = await authService.getAccessToken();
      
      if (accessToken == null) {
        throw Exception('액세스 토큰을 가져올 수 없습니다');
      }
      
      return accessToken;
    } catch (e) {
      _logger.e('❌ 액세스 토큰 가져오기 실패: $e');
      throw e;
    }
  }

  /// 연결 해제
  void disconnect() {
    if (_currentSessionId != null && _socket?.connected == true) {
      _socket!.emit('leave_session', {'sessionId': _currentSessionId});
    }
    
    _socket?.disconnect();
    _socket = null;
    _currentSessionId = null;
    _onHapticFeedback = null;
    _logger.i('realtime-service 연결 해제');
  }
} 
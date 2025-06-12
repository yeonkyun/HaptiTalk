import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/app_config.dart';
import 'auth_service.dart';

class WebSocketService {
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  StreamController<Map<String, dynamic>>? _messageController;
  bool _isConnected = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  static const int maxReconnectAttempts = 5;

  // 메시지 스트림
  Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;
  bool get isConnected => _isConnected;

  // 싱글톤 패턴
  static final WebSocketService _instance = WebSocketService._internal();
  WebSocketService._internal();
  factory WebSocketService() => _instance;

  // WebSocket 연결
  Future<void> connect() async {
    try {
      // 인증 토큰 확인
      final authService = AuthService();
      final token = await authService.getAccessToken();
      
      if (token == null) {
        print('❌ WebSocket 연결 실패: 인증 토큰이 없습니다.');
        return;
      }

      // WebSocket URL 생성
      final wsUrl = '${AppConfig.wsBaseUrl}/realtime?token=$token';
      
      // WebSocket 연결
      _channel = IOWebSocketChannel.connect(wsUrl);
      _messageController = StreamController<Map<String, dynamic>>.broadcast();

      // 메시지 수신 리스너
      _subscription = _channel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message);
            _messageController?.add(data);
            print('📨 WebSocket 메시지 수신: $data');
          } catch (e) {
            print('❌ WebSocket 메시지 파싱 실패: $e');
          }
        },
        onError: (error) {
          print('❌ WebSocket 에러: $error');
          _isConnected = false;
          _attemptReconnect();
        },
        onDone: () {
          print('📡 WebSocket 연결 종료');
          _isConnected = false;
          _attemptReconnect();
        },
      );

      _isConnected = true;
      _reconnectAttempts = 0;
      print('✅ WebSocket 연결 성공: $wsUrl');

    } catch (e) {
      print('❌ WebSocket 연결 실패: $e');
      _isConnected = false;
      _attemptReconnect();
    }
  }

  // 메시지 전송
  void sendMessage(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      try {
        final jsonMessage = json.encode(message);
        _channel!.sink.add(jsonMessage);
        print('📤 WebSocket 메시지 전송: $message');
      } catch (e) {
        print('❌ WebSocket 메시지 전송 실패: $e');
      }
    } else {
      print('⚠️ WebSocket이 연결되지 않았습니다.');
    }
  }

  // 재연결 시도
  void _attemptReconnect() {
    if (_reconnectAttempts >= maxReconnectAttempts) {
      print('❌ WebSocket 재연결 시도 한계 도달');
      return;
    }

    _reconnectAttempts++;
    final delay = Duration(seconds: _reconnectAttempts * 2);
    
    print('🔄 WebSocket 재연결 시도 ${_reconnectAttempts}/${maxReconnectAttempts} (${delay.inSeconds}초 후)');
    
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  // 연결 해제
  void disconnect() {
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _messageController?.close();
    
    _isConnected = false;
    _reconnectAttempts = 0;
    
    print('📡 WebSocket 연결 해제');
  }

  // 특정 이벤트 전송
  void sendSessionEvent(String eventType, Map<String, dynamic> data) {
    sendMessage({
      'type': 'session_event',
      'event': eventType,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void sendAnalysisRequest(String sessionId, Map<String, dynamic> data) {
    sendMessage({
      'type': 'analysis_request',
      'session_id': sessionId,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void sendHeartbeat() {
    sendMessage({
      'type': 'heartbeat',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
} 
import 'package:flutter/services.dart';
import 'dart:async';

class WatchConnectionStatus {
  final bool isSupported;
  final bool isPaired;
  final bool isWatchAppInstalled;
  final bool isReachable;
  final int activationState;

  WatchConnectionStatus({
    required this.isSupported,
    required this.isPaired,
    required this.isWatchAppInstalled,
    required this.isReachable,
    required this.activationState,
  });

  bool get isFullyConnected =>
      isSupported &&
      isPaired &&
      isWatchAppInstalled &&
      isReachable &&
      activationState == 2; // 2 = activated

  @override
  String toString() =>
      'WatchConnectionStatus(isSupported: $isSupported, isPaired: $isPaired, '
      'isWatchAppInstalled: $isWatchAppInstalled, isReachable: $isReachable, '
      'activationState: $activationState)';
}

class WatchService {
  static const MethodChannel _channel = MethodChannel('com.haptitalk/watch');

  // 연결 상태 스트림
  final _connectionStatusController =
      StreamController<WatchConnectionStatus>.broadcast();
  Stream<WatchConnectionStatus> get connectionStatus =>
      _connectionStatusController.stream;

  // 워치 메시지 스트림
  final _watchMessageController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get watchMessages =>
      _watchMessageController.stream;

  // 싱글톤 패턴
  static final WatchService _instance = WatchService._internal();
  factory WatchService() => _instance;

  WatchService._internal() {
    _setupMessageHandler();
    // 초기 연결 상태 확인
    _checkConnectionStatus();
  }

  // Watch에서 오는 메시지 처리
  void _setupMessageHandler() {
    _channel.setMethodCallHandler((call) async {
      print('Watch 메시지 수신: ${call.method} - ${call.arguments}');

      switch (call.method) {
        case 'watchMessage':
          _handleWatchMessage(call.arguments);
          break;
        case 'watchConnectionStatus':
          _handleConnectionStatus(call.arguments);
          break;
      }
    });
  }

  void _handleWatchMessage(dynamic message) {
    if (message is! Map<String, dynamic>) {
      print('잘못된 워치 메시지 형식: $message');
      return;
    }

    print('Watch 메시지 처리: $message');
    _watchMessageController.add(message);
  }

  void _handleConnectionStatus(dynamic status) {
    if (status is! Map<String, dynamic>) {
      print('잘못된 연결 상태 형식: $status');
      return;
    }

    final connectionStatus = WatchConnectionStatus(
      isSupported: status['isSupported'] ?? false,
      isPaired: status['isPaired'] ?? false,
      isWatchAppInstalled: status['isWatchAppInstalled'] ?? false,
      isReachable: status['isReachable'] ?? false,
      activationState: status['activationState'] ?? 0,
    );

    print('Watch 연결 상태 업데이트: $connectionStatus');
    _connectionStatusController.add(connectionStatus);
  }

  // 연결 상태 확인
  Future<void> _checkConnectionStatus() async {
    try {
      final result = await _channel.invokeMethod('testConnection');
      _handleConnectionStatus(result);
    } catch (e) {
      print('연결 상태 확인 실패: $e');
      _handleConnectionStatus({
        'isSupported': false,
        'isPaired': false,
        'isWatchAppInstalled': false,
        'isReachable': false,
        'activationState': 0,
      });
    }
  }

  // 세션 시작을 Watch에 알림
  Future<void> startSession(String sessionType) async {
    try {
      await _checkConnectionStatus(); // 세션 시작 전 연결 상태 확인

      final result = await _channel.invokeMethod('startSession', {
        'sessionType': sessionType,
      });
      print('Watch 세션 시작: $sessionType - 결과: $result');
    } catch (e) {
      print('Watch 세션 시작 실패: $e');
      rethrow;
    }
  }

  // 세션 종료를 Watch에 알림
  Future<void> stopSession() async {
    try {
      final result = await _channel.invokeMethod('stopSession');
      print('Watch 세션 종료 - 결과: $result');
    } catch (e) {
      print('Watch 세션 종료 실패: $e');
      rethrow;
    }
  }

  // 햅틱 피드백을 Watch에 전송
  Future<void> sendHapticFeedback(String message) async {
    try {
      final result = await _channel.invokeMethod('sendHapticFeedback', {
        'message': message,
      });
      print('Watch 햅틱 피드백 전송: $message - 결과: $result');
    } catch (e) {
      print('Watch 햅틱 피드백 실패: $e');
      rethrow;
    }
  }

  // 실시간 분석 데이터를 Watch에 전송
  Future<void> sendRealtimeAnalysis({
    required int likability,
    required int interest,
    required int speakingSpeed,
    required String emotion,
    required String feedback,
    required String elapsedTime,
  }) async {
    try {
      final result = await _channel.invokeMethod('sendRealtimeAnalysis', {
        'likability': likability,
        'interest': interest,
        'speakingSpeed': speakingSpeed,
        'emotion': emotion,
        'feedback': feedback,
        'elapsedTime': elapsedTime,
      });
      print('Watch 실시간 분석 데이터 전송 성공 - 결과: $result');
    } catch (e) {
      print('Watch 실시간 분석 데이터 전송 실패: $e');
      rethrow;
    }
  }

  // 워치 연결 상태 확인
  Future<bool> isWatchConnected() async {
    try {
      final status = await _channel.invokeMethod('testConnection');
      final connectionStatus = WatchConnectionStatus(
        isSupported: status['isSupported'] ?? false,
        isPaired: status['isPaired'] ?? false,
        isWatchAppInstalled: status['isWatchAppInstalled'] ?? false,
        isReachable: status['isReachable'] ?? false,
        activationState: status['activationState'] ?? 0,
      );
      return connectionStatus.isFullyConnected;
    } catch (e) {
      print('워치 연결 상태 확인 실패: $e');
      return false;
    }
  }

  // 리소스 정리
  void dispose() {
    _connectionStatusController.close();
    _watchMessageController.close();
  }
}

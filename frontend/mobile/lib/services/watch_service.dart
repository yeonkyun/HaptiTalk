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

  // Timer 관리
  Timer? _periodicTimer;

  // 싱글톤 패턴
  static final WatchService _instance = WatchService._internal();
  factory WatchService() => _instance;

  WatchService._internal() {
    _setupMessageHandler();
    // 초기 연결 상태 확인
    _checkConnectionStatus();
    // 주기적 연결 상태 모니터링 (10초마다)
    _startPeriodicConnectionCheck();
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
    // Map으로 변환 처리 개선
    Map<String, dynamic> messageMap;
    
    if (message is Map<String, dynamic>) {
      messageMap = message;
    } else if (message is Map) {
      // 다른 타입의 Map을 String, dynamic으로 변환
      messageMap = Map<String, dynamic>.from(message);
    } else {
      print('잘못된 워치 메시지 형식: $message (타입: ${message.runtimeType})');
      return;
    }

    // watchReady 필드 타입 변환 처리
    if (messageMap.containsKey('watchReady')) {
      final watchReadyValue = messageMap['watchReady'];
      if (watchReadyValue is int) {
        messageMap['watchReady'] = watchReadyValue == 1;
      } else if (watchReadyValue is String) {
        messageMap['watchReady'] = watchReadyValue.toLowerCase() == 'true' || watchReadyValue == '1';
      }
      // bool인 경우는 그대로 유지
    }

    print('Watch 메시지 처리: $messageMap');
    // StreamController가 닫혔는지 확인
    if (!_watchMessageController.isClosed) {
      _watchMessageController.add(messageMap);
    }
  }

  void _handleConnectionStatus(dynamic status) {
    // Map으로 변환 처리
    Map<String, dynamic> statusMap;
    
    if (status is Map<String, dynamic>) {
      statusMap = status;
    } else if (status is Map) {
      // 다른 타입의 Map을 String, dynamic으로 변환
      statusMap = Map<String, dynamic>.from(status);
    } else {
      print('지원되지 않는 연결 상태 형식: $status (타입: ${status.runtimeType})');
      return;
    }

    final connectionStatus = WatchConnectionStatus(
      isSupported: statusMap['isSupported'] ?? false,
      isPaired: statusMap['isPaired'] ?? false,
      isWatchAppInstalled: statusMap['isWatchAppInstalled'] ?? false,
      isReachable: statusMap['isReachable'] ?? false,
      activationState: statusMap['activationState'] ?? 0,
    );

    print('Watch 연결 상태 업데이트: $connectionStatus');
    // StreamController가 닫혔는지 확인
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(connectionStatus);
    }
  }

  // 연결 상태 확인
  Future<void> _checkConnectionStatus() async {
    try {
      final result = await _channel.invokeMethod('testConnection');
      _handleConnectionStatus(result);
    } catch (e) {
      print('연결 상태 확인 실패: $e');
      // StreamController가 닫혔는지 확인
      if (!_connectionStatusController.isClosed) {
        _handleConnectionStatus({
          'isSupported': false,
          'isPaired': false,
          'isWatchAppInstalled': false,
          'isReachable': false,
          'activationState': 0,
        });
      }
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

  // WCSession 강제 재연결
  Future<void> forceReconnect() async {
    try {
      final result = await _channel.invokeMethod('forceReconnect');
      print('🔄 강제 재연결 시도: $result');
      
      // 재연결 후 잠시 대기하고 상태 확인
      await Future.delayed(const Duration(seconds: 6));
      await _checkConnectionStatus();
    } catch (e) {
      print('❌ 강제 재연결 실패: $e');
      rethrow;
    }
  }

  // 주기적 연결 상태 확인 (자동 재연결 로직)
  void _startPeriodicConnectionCheck() {
    _periodicTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      try {
        await _checkConnectionStatus();
        print('🔄 주기적 연결 상태 확인 완료');
      } catch (e) {
        print('❌ 주기적 연결 확인 실패: $e');
      }
    });
  }

  // 리소스 정리
  void dispose() {
    _connectionStatusController.close();
    _watchMessageController.close();
    _periodicTimer?.cancel();
  }
}

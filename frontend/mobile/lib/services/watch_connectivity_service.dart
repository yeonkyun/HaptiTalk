import 'package:flutter/foundation.dart';
import 'package:watch_connectivity/watch_connectivity.dart';

class WatchConnectivityService {
  static final WatchConnectivityService _instance = WatchConnectivityService._internal();
  factory WatchConnectivityService() => _instance;
  WatchConnectivityService._internal();

  final _watchConnectivity = WatchConnectivity();
  
  Future<void> initialize() async {
    try {
      // 디버깅 정보 출력
      final isSupported = await _watchConnectivity.isSupported;
      debugPrint('WatchConnectivity supported: $isSupported');
      
      if (!isSupported) {
        debugPrint('WatchConnectivity is not supported on this device');
        return;
      }
      
      final isPaired = await _watchConnectivity.isPaired;
      debugPrint('Watch paired: $isPaired');
      
      final isReachable = await _watchConnectivity.isReachable;
      debugPrint('Watch reachable: $isReachable');
      
      // 메시지 수신 리스너 설정
      _watchConnectivity.messageStream.listen((message) {
        debugPrint('Received message from watch: $message');
        _handleWatchMessage(message);
      });
      
    } catch (e) {
      debugPrint('Error initializing WatchConnectivity: $e');
    }
  }
  
  void _handleWatchMessage(Map<String, dynamic> message) {
    // 워치로부터 받은 메시지 처리
    if (message.containsKey('hapticPattern')) {
      // 햅틱 패턴 처리
      debugPrint('Haptic pattern received: ${message['hapticPattern']}');
    }
  }
  
  Future<void> sendMessageToWatch(Map<String, dynamic> message) async {
    try {
      final reachable = await _watchConnectivity.isReachable;
      if (reachable) {
        await _watchConnectivity.sendMessage(message);
        debugPrint('Message sent to watch: $message');
      } else {
        debugPrint('Watch is not reachable');
        // reachable하지 않으면 applicationContext 사용
        await updateApplicationContext(message);
      }
    } catch (e) {
      debugPrint('Error sending message to watch: $e');
    }
  }
  
  Future<void> updateApplicationContext(Map<String, dynamic> context) async {
    try {
      await _watchConnectivity.updateApplicationContext(context);
      debugPrint('Application context updated: $context');
    } catch (e) {
      debugPrint('Error updating application context: $e');
    }
  }
  
  // 연결 상태 확인 메서드
  Future<Map<String, bool>> getConnectionStatus() async {
    try {
      final isSupported = await _watchConnectivity.isSupported;
      final isPaired = await _watchConnectivity.isPaired;
      final isReachable = await _watchConnectivity.isReachable;
      
      return {
        'supported': isSupported,
        'paired': isPaired,
        'reachable': isReachable,
      };
    } catch (e) {
      debugPrint('Error getting connection status: $e');
      return {
        'supported': false,
        'paired': false,
        'reachable': false,
      };
    }
  }
}

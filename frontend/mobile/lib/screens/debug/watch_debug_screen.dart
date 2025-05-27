import 'package:flutter/material.dart';
import '../../services/watch_service.dart';

class WatchDebugScreen extends StatefulWidget {
  const WatchDebugScreen({super.key});

  @override
  State<WatchDebugScreen> createState() => _WatchDebugScreenState();
}

class _WatchDebugScreenState extends State<WatchDebugScreen> {
  final WatchService _watchService = WatchService();
  WatchConnectionStatus? _connectionStatus;
  String _lastMessage = '';

  @override
  void initState() {
    super.initState();
    _setupSubscriptions();
  }

  void _setupSubscriptions() {
    // 연결 상태 구독
    _watchService.connectionStatus.listen((status) {
      setState(() {
        _connectionStatus = status;
      });
    });

    // 워치 메시지 구독
    _watchService.watchMessages.listen((message) {
      setState(() {
        _lastMessage = '워치 메시지: ${message.toString()}';
      });
    });
  }

  @override
  void dispose() {
    _watchService.dispose();
    super.dispose();
  }

  Future<void> _startTestSession() async {
    try {
      await _watchService.startSession('테스트 모드');
      setState(() {
        _lastMessage = '테스트 세션 시작됨';
      });
    } catch (e) {
      setState(() {
        _lastMessage = '세션 시작 실패: $e';
      });
    }
  }

  Future<void> _stopTestSession() async {
    try {
      await _watchService.stopSession();
      setState(() {
        _lastMessage = '테스트 세션 종료됨';
      });
    } catch (e) {
      setState(() {
        _lastMessage = '세션 종료 실패: $e';
      });
    }
  }

  Future<void> _sendTestHaptic() async {
    try {
      await _watchService.sendHapticFeedback('테스트 햅틱 피드백');
      setState(() {
        _lastMessage = '햅틱 피드백 전송됨';
      });
    } catch (e) {
      setState(() {
        _lastMessage = '햅틱 피드백 실패: $e';
      });
    }
  }

  Future<void> _sendTestRealtimeData() async {
    try {
      await _watchService.sendRealtimeAnalysis(
        likability: 85,
        interest: 92,
        speakingSpeed: 78,
        emotion: '긍정적',
        feedback: '테스트 피드백: 대화가 잘 진행되고 있습니다',
        elapsedTime: '00:05:23',
      );
      setState(() {
        _lastMessage = '실시간 분석 데이터 전송됨';
      });
    } catch (e) {
      setState(() {
        _lastMessage = '실시간 데이터 전송 실패: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('워치 연결 디버그'),
        backgroundColor: const Color(0xFF3F51B5),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 연결 상태 카드
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '연결 상태',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      _buildConnectionStatusRow(
                          '지원 여부', _connectionStatus?.isSupported ?? false),
                      _buildConnectionStatusRow(
                          '페어링됨', _connectionStatus?.isPaired ?? false),
                      _buildConnectionStatusRow('워치앱 설치됨',
                          _connectionStatus?.isWatchAppInstalled ?? false),
                      _buildConnectionStatusRow(
                          '연결 가능', _connectionStatus?.isReachable ?? false),
                      _buildConnectionStatusRow('완전히 연결됨',
                          _connectionStatus?.isFullyConnected ?? false),
                      const SizedBox(height: 8),
                      Text(
                        '활성화 상태: ${_getActivationStateString(_connectionStatus?.activationState ?? 0)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 테스트 버튼들
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '테스트 기능',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _startTestSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('테스트 세션 시작'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _stopTestSession,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('테스트 세션 종료'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _sendTestHaptic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('테스트 햅틱 전송'),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _sendTestRealtimeData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('테스트 데이터 전송'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 마지막 메시지 카드
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '마지막 메시지',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(_lastMessage),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 주의사항
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ 주의사항',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Apple Watch가 iPhone과 페어링되어 있어야 합니다\n'
                      '• 워치앱이 설치되어 있어야 합니다\n'
                      '• 두 기기가 블루투스 범위 내에 있어야 합니다\n'
                      '• 워치앱이 백그라운드에서도 실행되어야 합니다',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: value ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ${value ? "예" : "아니오"}',
            style: TextStyle(
              color: value ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _getActivationStateString(int state) {
    switch (state) {
      case 0:
        return '비활성화';
      case 1:
        return '비활성화 중';
      case 2:
        return '활성화됨';
      default:
        return '알 수 없음';
    }
  }
}

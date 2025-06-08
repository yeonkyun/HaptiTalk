import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../constants/colors.dart';
import '../../models/analysis/analysis_result.dart';
import '../../models/session/session_model.dart';
import '../../models/stt/stt_response.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/watch_service.dart';
import '../../services/audio_service.dart';
import '../../services/realtime_service.dart';
import '../../widgets/analysis/metrics_card.dart';
import '../analysis/analysis_summary_screen.dart';
import '../../services/auth_service.dart';

class RealtimeAnalysisScreen extends StatefulWidget {
  final String sessionId;
  final String? sessionType;

  const RealtimeAnalysisScreen({
    Key? key, 
    required this.sessionId,
    this.sessionType,
  }) : super(key: key);

  @override
  _RealtimeAnalysisScreenState createState() => _RealtimeAnalysisScreenState();
}

class _RealtimeAnalysisScreenState extends State<RealtimeAnalysisScreen> {
  late Timer _timer;
  late Timer _watchSyncTimer;
  Timer? _segmentSaveTimer; // 세그먼트 저장 타이머 추가
  final WatchService _watchService = WatchService();
  final AudioService _audioService = AudioService();
  final RealtimeService _realtimeService = RealtimeService();

  int _seconds = 0;
  bool _isRecording = false;
  bool _isWatchConnected = false;
  bool _isRealtimeConnected = false;
  String _transcription = '';
  String _feedback = '';
  List<String> _suggestedTopics = [];
  bool _isAudioInitialized = false;
  StreamSubscription? _sttSubscription;
  StreamSubscription? _watchMessageSubscription;

  // 분석 데이터 (실제 AI 결과로 업데이트)
  String _emotionState = '대기 중';
  int _speakingSpeed = 0;
  int _likability = 0;
  int _interest = 0;
  String _currentScenario = 'dating'; // 기본 시나리오

  String _lastHapticMessage = '';  // 🚫 중복 햅틱 방지
  DateTime? _lastHapticTime;  // ⏰ 마지막 햅틱 시간
  final int _hapticCooldownSeconds = 15;  // 🕐 햅틱 쿨다운 (15초로 단축)
  
  // 🎯 햅틱 패턴 카테고리별 마지막 전송 시간
  Map<String, DateTime> _lastHapticByCategory = {
    'speaker': DateTime.now().subtract(Duration(hours: 1)),    // 화자 행동 (S)
    'listener': DateTime.now().subtract(Duration(hours: 1)),   // 청자 행동 (L)  
    'flow': DateTime.now().subtract(Duration(hours: 1)),       // 대화 흐름 (F)
    'reaction': DateTime.now().subtract(Duration(hours: 1)),   // 상대방 반응 (R)
  };

  // 마지막 전송된 Watch 햅틱 피드백 추적
  String _lastSentWatchFeedback = '';

  // 세그먼트 저장 관련 변수들
  int _currentSegmentIndex = 0;
  Map<String, dynamic> _currentSegmentData = {};
  List<Map<String, dynamic>> _segmentHapticFeedbacks = [];
  DateTime? _segmentStartTime;

  String _lastWatchSyncData = '';

  // 🔥 초기화 및 세션 종료 상태 관리
  bool _isInitializing = true;
  bool _isSessionEnded = false; // 세션 종료 플래그 추가

  @override
  void initState() {
    super.initState();
    
    // 세션 타입을 STT 시나리오로 변환
    print('🎯 원본 세션 타입: ${widget.sessionType}');
    _currentScenario = _convertSessionTypeToScenario(widget.sessionType);
    print('🎯 변환된 STT 시나리오: $_currentScenario');
    print('🎯 현재 세션 모드: ${widget.sessionType} → STT 시나리오: $_currentScenario');
    
    // 🔥 로딩 다이얼로그 표시 후 초기화 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showInitializationDialog();
    });
    
    _initializeServices();
    
    // 세션 타입에 따른 초기 추천 주제 설정
    if (widget.sessionType == '발표') {
      _suggestedTopics = ['핵심 포인트 강조', '청중과의 소통', '시각적 자료 활용', '명확한 결론', '질의응답 준비'];
    } else if (widget.sessionType == '면접' || widget.sessionType == '면접(인터뷰)') {
      _suggestedTopics = ['경력 소개', '성장 경험', '회사 지원 동기', '미래 계획', '강점과 약점'];
    } else {
      // 소개팅 모드 (기본)
    _suggestedTopics = ['여행 경험', '좋아하는 여행지', '사진 취미', '역사적 장소', '제주도 명소'];
    }
    
    // STT 스트림 구독 상태 주기적 확인
    Timer.periodic(Duration(seconds: 10), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      if (_sttSubscription == null && _isAudioInitialized) {
        print('🔄 STT 스트림 구독이 없음, 재구독 시도');
        _subscribeToSTTMessages();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _watchSyncTimer.cancel();
    _segmentSaveTimer?.cancel();
    _sttSubscription?.cancel();
    _watchMessageSubscription?.cancel();
    _audioService.dispose();
    _realtimeService.disconnect();
    super.dispose();
  }

  /// 🔥 초기화 로딩 다이얼로그 표시
  void _showInitializationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                '세션 준비 중...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '마이크 초기화 및 연결을 확인하고 있습니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 서비스 초기화
  Future<void> _initializeServices() async {
    try {
      print('🔧 실시간 분석 서비스 초기화 시작');
      
      // AudioService 초기화
      final initialized = await _audioService.initialize();
      if (initialized) {
        setState(() {
          _isAudioInitialized = true;
        });
        print('✅ AudioService 초기화 완료');
        
        // Realtime Service 연결
        await _connectToRealtimeService();
        print('✅ Realtime Service 연결 완료');
        
        // 🎤 자동으로 녹음 시작
        await _startRecordingAutomatically();
        print('✅ 자동 녹음 시작 완료');
        
        // 📳 Watch 세션 시작 및 테스트 햅틱 피드백 전송
        await _startWatchSession();
        print('✅ Watch 세션 시작 완료');
        
        // ⭐ STT 메시지 스트림 구독 (모든 초기화 완료 후)
        await Future.delayed(Duration(seconds: 2)); // 2초 대기
        _subscribeToSTTMessages();
        
        // 🔥 초기화 완료 - 로딩 다이얼로그 닫고 타이머 시작
        setState(() {
          _isInitializing = false;
        });
        if (mounted) {
          Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
          _startTimer(); // 타이머 시작
          _checkWatchConnection();
          _startWatchSync();
          _subscribeToWatchMessages();
          _startSegmentSaveTimer(); // 🔥 세그먼트 저장 타이머 시작
        }
        
        print('✅ 실시간 분석 서비스 초기화 완료');
      } else {
        print('❌ AudioService 초기화 실패');
        if (mounted) {
          Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
          _showErrorSnackBar('마이크 권한이 필요합니다. 설정에서 권한을 허용해주세요.');
        }
      }
    } catch (e) {
      print('❌ 서비스 초기화 실패: $e');
      if (mounted) {
        Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
        _showErrorSnackBar('서비스 초기화에 실패했습니다: $e');
      }
    }
  }

  /// 자동으로 녹음 시작
  Future<void> _startRecordingAutomatically() async {
    if (!_isAudioInitialized) {
      print('❌ 자동 녹음 시작 실패: AudioService가 초기화되지 않음');
      return;
    }

    try {
      print('🎤 자동 녹음 시작 시도... (scenario: $_currentScenario)');
      final success = await _audioService.startRealTimeRecording(scenario: _currentScenario);
      if (success) {
        setState(() {
          _isRecording = true;
        });
        print('✅ 자동 녹음 시작 성공 (scenario: $_currentScenario)');
      } else {
        print('❌ 자동 녹음 시작 실패');
        _showErrorSnackBar('자동 녹음 시작에 실패했습니다. 수동으로 녹음을 시작해주세요.');
      }
    } catch (e) {
      print('❌ 자동 녹음 시작 예외: $e');
      _showErrorSnackBar('자동 녹음 시작 중 오류가 발생했습니다: $e');
    }
  }

  /// Realtime Service 연결
  Future<void> _connectToRealtimeService() async {
    try {
      // AuthService에서 실제 액세스 토큰 가져오기
      final authService = AuthService();
      final accessToken = await authService.getAccessToken();
      
      if (accessToken == null) {
        print('❌ realtime-service 연결 실패: 액세스 토큰 없음');
        _showErrorSnackBar('인증 토큰이 없습니다. 다시 로그인해주세요.');
        return;
      }
      
      final connected = await _realtimeService.connect(
        widget.sessionId, 
        accessToken,
        sessionType: widget.sessionType ?? '발표',
        sessionTitle: '실시간 ${widget.sessionType ?? '발표'} 연습',
      );
      
      setState(() {
        _isRealtimeConnected = connected;
      });
      
      if (connected) {
        print('✅ realtime-service 연결 성공');
        
        // 햅틱 피드백 콜백 설정
        _realtimeService.setHapticFeedbackCallback(_handleHapticFeedback);
      } else {
        print('❌ realtime-service 연결 실패');
        _showErrorSnackBar('실시간 서비스 연결에 실패했습니다');
      }
    } catch (e) {
      print('❌ realtime-service 연결 오류: $e');
      _showErrorSnackBar('실시간 서비스 연결 오류: $e');
    }
  }

  /// 햅틱 피드백 처리
  void _handleHapticFeedback(Map<String, dynamic> feedback) {
    // 🔥 세션이 종료된 경우 햅틱 피드백 무시
    if (_isSessionEnded) {
      print('⏹️ 세션 종료됨 - 햅틱 피드백 무시: ${feedback['message']}');
      return;
    }

    try {
      final message = feedback['message'] as String;
      final pattern = feedback['pattern'] as String;
      final category = feedback['category'] as String;
      final patternId = feedback['patternId'] as String;

      print('📳 햅틱 피드백 수신: $message (패턴: $pattern, 카테고리: $category, ID: $patternId)');

      // 세그먼트 데이터에 햅틱 피드백 추가
      _segmentHapticFeedbacks.add({
        'timestamp': DateTime.now().toIso8601String(),
        'message': message,
        'pattern': pattern,
        'category': category,
        'patternId': patternId,
      });

      // 쿨다운 확인 (카테고리별)
      if (!_canSendHaptic(category)) {
        print('🚫 쿨다운 중 - 햅틱 전송 스킵 ($category)');
        return;
      }

      // Watch에 햅틱 피드백 전송 (설계 문서 기반 패턴 포함)
      _sendHapticWithPattern(
        message: message,
        pattern: pattern,
        category: category,
        patternId: patternId,
      );

      // 카테고리별 마지막 전송 시간 업데이트
      _lastHapticByCategory[category] = DateTime.now();

    } catch (e) {
      print('❌ 햅틱 피드백 처리 오류: $e');
    }
  }

  /// 카테고리별 햅틱 전송 가능 여부 확인
  bool _canSendHaptic(String category) {
    final lastSent = _lastHapticByCategory[category];
    if (lastSent == null) return true;
    
    // 카테고리별 다른 쿨다운 시간
    final cooldownSeconds = {
      'speaker': 10,    // 화자 행동: 10초
      'listener': 15,   // 청자 행동: 15초  
      'flow': 20,       // 대화 흐름: 20초
      'reaction': 8,    // 상대방 반응: 8초 (가장 중요)
    };
    
    final cooldown = cooldownSeconds[category] ?? _hapticCooldownSeconds;
    return DateTime.now().difference(lastSent).inSeconds >= cooldown;
  }

  /// 설계 문서 기반 패턴별 햅틱 전송
  Future<void> _sendHapticWithPattern({
    required String message,
    required String pattern,
    required String category, 
    required String patternId
  }) async {
    try {
      // Watch에 패턴 정보와 함께 전송
      await _watchService.sendHapticFeedbackWithPattern(
        message: message,
        pattern: pattern,
        category: category,
        patternId: patternId
      );
    } catch (e) {
      print('❌ 패턴 햅틱 전송 실패: $e');
      // 폴백: 기본 햅틱 전송
      await _watchService.sendHapticFeedback(message);
    }
  }

  /// 속도 카테고리를 감정으로 매핑
  String _mapSpeedToEmotion(String speedCategory) {
    switch (speedCategory) {
      case 'very_slow':
        return '침착함';
      case 'slow':
        return '안정적';
      case 'normal':
        return '자연스러움';
      case 'fast':
        return '활발함';
      case 'very_fast':
        return '흥미로움';
      default:
        return '대기 중';
    }
  }

  /// 말하기 패턴을 관심도로 매핑 (0-100)
  int _mapPatternToInterest(String speechPattern) {
    switch (speechPattern) {
      case 'very_sparse':
        return 30; // 띄엄띄엄 말하면 관심도 낮음
      case 'staccato':
        return 50; // 끊어서 말하면 보통
      case 'normal':
        return 70; // 일반적이면 적당한 관심
      case 'continuous':
        return 85; // 연속적이면 높은 관심
      case 'steady':
        return 80; // 일정하면 안정적 관심
      case 'variable':
        return 75; // 변화가 있으면 적당한 관심
      default:
        return 0;
    }
  }

  /// 발화 밀도를 호감도로 매핑 (0-100)
  int _mapDensityToLikability(double speechDensity) {
    if (speechDensity < 0.3) {
      return 20; // 발화 밀도가 낮으면 호감도 낮음
    } else if (speechDensity < 0.5) {
      return 40;
    } else if (speechDensity < 0.7) {
      return 60;
    } else if (speechDensity < 0.8) {
      return 80;
    } else {
      return 90; // 발화 밀도가 높으면 호감도 높음
    }
  }

  /// 텍스트 내용 기반 피드백 생성
  void _generateTextBasedFeedback(String text, Map<String, dynamic>? speechMetrics) {
    String feedback = '';
    
    // 말하기 속도 피드백
    if (speechMetrics != null) {
      final speedCategory = speechMetrics['speed_category'] as String?;
      final evaluationWpm = speechMetrics['evaluation_wpm'] as num?;
      
      if (speedCategory == 'very_fast' && evaluationWpm != null) {
        feedback = '말하기 속도가 조금 빠른 편입니다. 천천히 말해보세요';
      } else if (speedCategory == 'very_slow') {
        feedback = '조금 더 활발하게 대화해보세요';
      }
      // 🔄 정상적인 속도일 때는 피드백을 생성하지 않음 (중복 방지)
      
      // 발화 패턴 피드백
      final speechPattern = speechMetrics['speech_pattern'] as String?;
      if (speechPattern == 'very_sparse') {
        if (feedback.isNotEmpty) feedback += '\n';
        feedback += '더 연결된 대화를 시도해보세요';
      }
    }
    
    // 텍스트 길이 기반 피드백
    if (text.length > 100) {
      if (feedback.isNotEmpty) feedback += '\n';
      feedback += '좋습니다! 적극적으로 대화하고 있어요';
    }
    
    // 🔄 새로운 피드백이 있고 기존 피드백과 다를 때만 업데이트
    if (feedback.isNotEmpty && feedback != _feedback) {
      _feedback = feedback;
      print('📝 새로운 피드백 생성: $feedback');
    }
  }

  /// STT 결과를 realtime-service로 전송
  Future<void> _sendToRealtimeService(STTResponse response) async {
    if (!_isRealtimeConnected) {
      print('⚠️ realtime-service 연결 안됨, STT 결과 전송 스킵');
      return;
    }

    try {
      // AuthService에서 실제 액세스 토큰 가져오기
      final authService = AuthService();
      final accessToken = await authService.getAccessToken();
      
      if (accessToken == null) {
        print('❌ STT 결과 전송 실패: 액세스 토큰 없음');
        return;
      }
      
      print('📤 STT 결과 전송 - 실제 scenario 값: $_currentScenario');
      print('📤 STT 결과 전송 - 세션 타입: ${widget.sessionType}');
      
      final success = await _realtimeService.sendSTTResult(
        sessionId: widget.sessionId,
        sttResponse: response,
        scenario: _currentScenario,
        language: 'ko',
        accessToken: accessToken,
      );
      
      if (success) {
        print('✅ STT 결과를 realtime-service로 전송 성공');
      } else {
        print('❌ STT 결과 realtime-service 전송 실패');
      }
    } catch (e) {
      print('❌ STT 결과 전송 오류: $e');
    }
  }

  /// STT 메시지 스트림 구독
  void _subscribeToSTTMessages() {
    print('🔗 STT 메시지 스트림 구독 시작');
    
    try {
      // 기존 구독이 있으면 취소
      _sttSubscription?.cancel();
      
      // AudioService의 STT 메시지 스트림 확인
      final sttStream = _audioService.sttMessageStream;
      if (sttStream == null) {
        print('❌ STT 메시지 스트림이 null입니다');
        // 잠시 후 재시도
        Timer(Duration(seconds: 1), () {
          if (mounted) {
            print('🔄 STT 메시지 스트림 재구독 시도');
            _subscribeToSTTMessages();
          }
        });
        return;
      }

      print('✅ STT 메시지 스트림 발견, 구독 진행');
      
      _sttSubscription = sttStream.listen(
        (response) {
          print('📨 실시간 분석 화면에서 STT 메시지 수신: ${response.type}');
          if (mounted) {
            _handleSTTResponse(response);
          } else {
            print('⚠️ 화면이 dispose되어 STT 메시지 처리 스킵');
          }
        },
        onError: (error) {
          print('❌ STT 스트림 에러: $error');
          _showErrorSnackBar('음성 인식 오류: $error');

          // 에러 후 재구독 시도
          Timer(Duration(seconds: 2), () {
            if (mounted) {
              print('🔄 STT 스트림 에러 후 재구독 시도');
              _subscribeToSTTMessages();
            }
          });
        },
        onDone: () {
          print('📡 STT 스트림 종료');
          
          // 스트림 종료 후 재구독 시도
          Timer(Duration(seconds: 1), () {
            if (mounted) {
              print('🔄 STT 스트림 종료 후 재구독 시도');
              _subscribeToSTTMessages();
            }
          });
        },
      );
      
      print('✅ STT 메시지 스트림 구독 완료');

    } catch (e) {
      print('❌ STT 메시지 스트림 구독 실패: $e');
      
      // 예외 발생 시 재시도
      Timer(Duration(seconds: 2), () {
        if (mounted) {
          print('🔄 STT 메시지 스트림 구독 예외 후 재시도');
          _subscribeToSTTMessages();
        }
      });
    }
  }

  /// STT 응답 처리 및 realtime-service로 전송
  void _handleSTTResponse(STTResponse response) {
    print('🔍 STT 응답 처리 시작: ${response.type}');
    
    switch (response.type) {
      case 'connected':
        print('✅ STT 연결됨: ${response.connectionId}');
        break;
        
      case 'transcription':
        print('📝 전사 결과 수신: ${response.text?.substring(0, min(50, response.text?.length ?? 0))}...');
        print('📊 isFinal: ${response.isFinal}, metadata 존재: ${response.metadata != null}');
        print('📊 metadata 내용: ${response.metadata}');
        
        // 모든 전사 결과에 대해 분석 데이터 업데이트 (텍스트 유무와 관계없이)
        setState(() {
          print('🔄 setState 내부 진입 - 분석 데이터 업데이트 시작');
          
          // STT 결과에서 분석 데이터 추출 및 화면 업데이트
          _updateAnalysisFromSTT(response);
          
          // 텍스트가 있는 경우에만 전사 내용 업데이트
          if (response.text != null && response.text!.isNotEmpty) {
            if (response.isFinal == true) {
              // 최종 전사 결과 - realtime-service로 전송
              _transcription += '${response.text} ';
              print('📝 최종 전사 결과 추가: ${response.text}');
            } else {
              // 임시 전사 결과 (실시간 업데이트)
              final sentences = _transcription.split(' ');
              if (sentences.isNotEmpty) {
                sentences[sentences.length - 1] = response.text!;
                _transcription = sentences.join(' ');
              } else {
                _transcription = response.text!;
              }
              print('📝 임시 전사 결과 업데이트');
            }
          }
          
          print('🔄 setState 내부 처리 완료');
        });
        
        // realtime-service로 전송 (setState 밖에서, 최종 결과만)
        if (response.isFinal == true && response.text != null && response.text!.isNotEmpty) {
          print('📤 realtime-service로 최종 결과 전송');
          _sendToRealtimeService(response);
        }
        break;
        
      case 'status':
        print('ℹ️ STT 상태: ${response.message}');
        break;
        
      case 'recording_stopped':
        print('🔴 STT 녹음 중지: ${response.message ?? "녹음이 중지되었습니다"}');
        // 녹음 중지 시 특별한 처리가 필요하면 여기에 추가
        break;
        
      case 'error':
        print('❌ STT 에러: ${response.message}');
        _showErrorSnackBar('음성 인식 오류: ${response.message}');
        break;
        
      default:
        print('⚠️ 알 수 없는 STT 응답 타입: ${response.type}');
        break;
    }
    
    print('🔍 STT 응답 처리 완료: ${response.type}');
  }

  /// STT 결과에서 분석 데이터를 추출하여 화면 상태 업데이트
  void _updateAnalysisFromSTT(STTResponse response) {
    print('🔍 _updateAnalysisFromSTT 함수 시작');
    
    try {
      // metadata에서 직접 데이터 추출
      final metadata = response.metadata;
      print('🔍 metadata 상태: ${metadata != null ? "존재함" : "null"}');
      
      if (metadata == null) {
        print('⚠️ STT response에 metadata가 없습니다');
        return;
      }
      
      print('🔍 metadata 키들: ${metadata.keys.toList()}');
      
      // 이전 값들 저장 (변화 감지용)
      final prevSpeakingSpeed = _speakingSpeed;
      final prevEmotionState = _emotionState;
      final prevInterest = _interest;
      final prevLikability = _likability;
      
      print('🔍 이전 값들 - 속도: $prevSpeakingSpeed, 감정: $prevEmotionState, 관심: $prevInterest, 호감: $prevLikability');
      
      // speech_metrics 처리
      final speechMetrics = metadata['speech_metrics'] as Map<String, dynamic>?;
      print('🔍 speech_metrics 상태: ${speechMetrics != null ? "존재함" : "null"}');
      
      if (speechMetrics != null) {
        print('🔍 speech_metrics 발견: $speechMetrics');
        
        // 말하기 속도 업데이트
        final evaluationWpm = speechMetrics['evaluation_wpm'] as num?;
        print('🔍 evaluation_wpm: $evaluationWpm');
        if (evaluationWpm != null) {
          _speakingSpeed = evaluationWpm.round();
          print('📊 말하기 속도 업데이트: $_speakingSpeed WPM');
        }
        
        // 속도 카테고리에 따른 감정 상태 업데이트
        final speedCategory = speechMetrics['speed_category'] as String?;
        print('🔍 speed_category: $speedCategory');
        if (speedCategory != null) {
          _emotionState = _mapSpeedToEmotion(speedCategory);
          print('📊 감정 상태 업데이트: $_emotionState (속도: $speedCategory)');
        }
        
        // 말하기 패턴에 따른 관심도 업데이트
        final speechPattern = speechMetrics['speech_pattern'] as String?;
        print('🔍 speech_pattern: $speechPattern');
        if (speechPattern != null) {
          _interest = _mapPatternToInterest(speechPattern);
          print('📊 관심도 업데이트: $_interest (패턴: $speechPattern)');
        }
        
        // 발화 밀도에 따른 호감도 업데이트
        final speechDensity = speechMetrics['speech_density'] as num?;
        print('🔍 speech_density: $speechDensity');
        if (speechDensity != null) {
          _likability = _mapDensityToLikability(speechDensity.toDouble());
          print('📊 호감도 업데이트: $_likability (밀도: ${speechDensity.toStringAsFixed(2)})');
        }
      } else {
        print('⚠️ speech_metrics가 metadata에 없습니다');
        print('⚠️ 사용 가능한 키들: ${metadata.keys.toList()}');
      }
      
      // emotion_analysis 처리 (있는 경우)
      final emotionAnalysis = metadata['emotion_analysis'] as Map<String, dynamic>?;
      if (emotionAnalysis != null) {
        final emotion = emotionAnalysis['emotion'] as String?;
        if (emotion != null) {
          _emotionState = emotion;
          print('📊 감정 분석 업데이트: $_emotionState');
        }
      }
      
      // 텍스트 내용 기반 피드백 생성
      final text = response.text ?? '';
      _generateTextBasedFeedback(text, speechMetrics);
      
      // 💡 텍스트 내용 기반 추천 토픽 업데이트
      _updateSuggestedTopics(text, speechMetrics);
      
      print('🔍 최종 업데이트된 값들 - 속도: $_speakingSpeed, 감정: $_emotionState, 관심: $_interest, 호감: $_likability');
      
      print('🔍 _updateAnalysisFromSTT 함수 완료');
      
    } catch (e) {
      print('❌ STT 분석 데이터 처리 오류: $e');
      print('❌ 스택 트레이스: ${StackTrace.current}');
    }
  }

  /// 말하기 속도를 직관적인 텍스트로 변환
  String _getSpeedText(int wpm) {
    if (wpm == 0) return '측정 중';
    
    if (wpm < 80) {
      return '천천히 (${wpm}WPM)';
    } else if (wpm < 120) {
      return '적당히 (${wpm}WPM)';
    } else if (wpm < 160) {
      return '보통 (${wpm}WPM)';
    } else if (wpm < 200) {
      return '빠르게 (${wpm}WPM)';
    } else {
      return '매우 빠르게 (${wpm}WPM)';
    }
  }

  /// 텍스트 내용 기반 추천 토픽 업데이트
  void _updateSuggestedTopics(String text, Map<String, dynamic>? speechMetrics) {
    // 세션 타입별 추천 주제 업데이트 로직
    if (widget.sessionType == '발표') {
      // 발표 모드일 때 적절한 추천 주제 업데이트
      if (text.contains('질문') || text.contains('문의')) {
        if (!_suggestedTopics.contains('질의응답 준비')) {
          setState(() {
            _suggestedTopics = ['질의응답 준비', '명확한 답변', '추가 설명', '예시 제시', '요약 정리'];
          });
        }
      }
    } else if (widget.sessionType == '면접') {
      // 면접 모드일 때 적절한 추천 주제 업데이트
      if (text.contains('경험') || text.contains('프로젝트')) {
        if (!_suggestedTopics.contains('구체적 성과')) {
          setState(() {
            _suggestedTopics = ['구체적 성과', '배운 점', '어려움과 해결', '팀워크 경험', '개선 방안'];
          });
        }
      }
    } else {
      // 소개팅 모드 (기본) - 텍스트 내용에 따른 동적 추천
      if (text.contains('여행') || text.contains('휴가')) {
        if (!_suggestedTopics.contains('여행 이야기')) {
          setState(() {
            _suggestedTopics = ['여행 이야기', '인상깊은 장소', '현지 음식', '문화 차이', '다음 여행지'];
          });
        }
      } else if (text.contains('취미') || text.contains('좋아하')) {
        if (!_suggestedTopics.contains('취미 활동')) {
          setState(() {
            _suggestedTopics = ['취미 활동', '새로운 도전', '운동 경험', '창작 활동', '배우고 싶은 것'];
          });
        }
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  // Watch 연결 상태 확인
  Future<void> _checkWatchConnection() async {
    try {
      final isConnected = await _watchService.isWatchConnected();
      setState(() {
        _isWatchConnected = isConnected;
      });
    } catch (e) {
      print('Watch 연결 상태 확인 실패: $e');
    }
  }

  // Watch와 주기적 동기화
  void _startWatchSync() {
    _watchSyncTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _syncWithWatch();
    });
  }

  // Watch에 실시간 데이터 전송
  Future<void> _syncWithWatch() async {
    if (!_isWatchConnected) return;

    try {
      // 🔥 상태 변경이 있을 때만 동기화 (불필요한 전송 방지)
      String currentStatus = '$_likability:$_interest:$_speakingSpeed:$_emotionState:${_feedback.hashCode}';
      if (_lastWatchSyncData == currentStatus) {
        print('⏭️ Watch 동기화 스킵: 상태 변경 없음 (완전 동일)');
        return;
      }
      
      // 🔥 초기 상태(모든 값이 0 또는 기본값)일 때는 전송하지 않음
      if (_likability == 0 && _interest == 0 && _speakingSpeed == 0 && _emotionState == '대기 중' && _feedback.isEmpty) {
        print('⏭️ Watch 동기화 스킵: 초기 상태 (의미있는 데이터 없음)');
        return;
      }
      
      // 실시간 분석 데이터를 구조화된 형태로 전송
      await _watchService.sendRealtimeAnalysis(
        likability: _likability,
        interest: _interest,
        speakingSpeed: _speakingSpeed,
        emotion: _emotionState,
        feedback: _feedback,
        elapsedTime: _formatTime(_seconds),
      );

      _lastWatchSyncData = currentStatus;
      print('📊 Watch 동기화 완료: L$_likability I$_interest S$_speakingSpeed E$_emotionState F:${_feedback.length}');
      
    } catch (e) {
      print('Watch 동기화 실패: $e');
    }
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _toggleRecording() async {
    if (!_isAudioInitialized) {
      _showErrorSnackBar('오디오 서비스가 초기화되지 않았습니다');
      return;
    }

    if (_isRecording) {
      // 녹음 중지
      await _audioService.pauseRecording();
    setState(() {
        _isRecording = false;
      });
    } else {
      // 녹음 시작
      final success = await _audioService.startRealTimeRecording(scenario: _currentScenario);
      if (success) {
        setState(() {
          _isRecording = true;
        });
      } else {
        _showErrorSnackBar('녹음 시작에 실패했습니다');
      }
    }
  }

  void _endSession() async {
    // 🔥 세션 종료 플래그 설정 (햅틱 피드백 차단)
    setState(() {
      _isSessionEnded = true;
    });
    
    _timer.cancel();
    _watchSyncTimer.cancel();
    _segmentSaveTimer?.cancel(); // 🔥 세그먼트 저장 타이머 취소

    // 로딩 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              const Text(
                '분석 결과 생성 중...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '대화 내용을 분석하고\n개인화된 피드백을 준비하고 있습니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // 🔥 세션 종료 전 최종 데이터 저장 및 분석
      await _finalizeSession();

      // 오디오 녹음 중지
      await _audioService.stopRecording();

    // Watch에 세션 종료 알림
    try {
      await _watchService.stopSession();
    } catch (e) {
      print('Watch 세션 종료 알림 실패: $e');
    }

    // 세션 종료 및 분석 결과 저장
    Provider.of<AnalysisProvider>(context, listen: false)
        .stopAnalysis(widget.sessionId);

      // 🔥 분석 결과가 준비될 때까지 잠시 대기 (서버 처리 시간)
      await Future.delayed(Duration(seconds: 3));

      // 🔥 분석 결과 존재 여부 확인
      final analysisProvider = Provider.of<AnalysisProvider>(context, listen: false);
      bool analysisReady = false;
      int retryCount = 0;
      const maxRetries = 5;

      while (!analysisReady && retryCount < maxRetries) {
        try {
          final analysis = await analysisProvider.getSessionAnalysis(widget.sessionId);
          if (analysis != null) {
            analysisReady = true;
            print('✅ 분석 결과 확인 완료');
          } else {
            print('⏳ 분석 결과 대기 중... (${retryCount + 1}/$maxRetries)');
            await Future.delayed(Duration(seconds: 2));
            retryCount++;
          }
        } catch (e) {
          print('⚠️ 분석 결과 확인 실패: $e');
          await Future.delayed(Duration(seconds: 2));
          retryCount++;
        }
      }

      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (analysisReady) {
        // 🔥 세션 분석 완료 - 바로 해당 세션의 분석 요약 화면으로 이동
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => AnalysisSummaryScreen(
                sessionId: widget.sessionId,
                sessionType: widget.sessionType,
              ),
            ),
            (route) => false, // 모든 이전 화면 제거
          );
        }
      } else {
        // 분석 결과를 불러올 수 없는 경우, 에러 메시지와 함께 홈으로 이동
        if (mounted) {
          _showErrorSnackBar('분석 결과를 생성하는 데 시간이 걸리고 있습니다. 잠시 후 분석 탭에서 확인해주세요.');
          
          // 홈 화면으로 이동
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/main',
      (route) => false,
            arguments: {'initialTabIndex': 0}, // 홈 탭
          );
        }
      }

    } catch (e) {
      print('❌ 세션 종료 처리 중 오류: $e');
      
      // 로딩 다이얼로그 닫기
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar('세션 종료 처리 중 오류가 발생했습니다: $e');
        
        // 오류 발생 시에도 홈으로 이동
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/main',
          (route) => false,
          arguments: {'initialTabIndex': 0},
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  /// Watch 세션 시작 및 테스트 햅틱 전송
  Future<void> _startWatchSession() async {
    try {
      print('🚀 Watch 세션 시작 프로세스 시작');
      
      // 1. Watch 연결 상태 재확인
      final isConnected = await _watchService.isWatchConnected();
      setState(() {
        _isWatchConnected = isConnected;
      });
      
      if (!isConnected) {
        print('⚠️ Watch가 연결되지 않아 세션 시작을 건너뛰니다');
        return;
      }
      
      // 2. Watch 세션 시작 (자동 화면 전환 포함)
      await _watchService.startSession(widget.sessionType ?? '소개팅');
      print('✅ Watch 세션 시작 신호 전송 완료');
      
      // 3. 추가 대기 시간 (Watch 앱 화면 전환 대기)
      await Future.delayed(Duration(seconds: 3));
      
      // 🔥 세션 시작 햅틱 피드백 제거 (불필요한 진동 방지)
      print('⏭️ 세션 시작 햅틱 피드백 스킵 (불필요한 진동 방지)');
      
      print('🎉 Watch 세션 시작 프로세스 완료');
      
    } catch (e) {
      print('❌ Watch 세션 시작 실패: $e');
      _showErrorSnackBar('Watch 세션 시작에 실패했습니다: $e');
    }
  }

  /// 세션 타입을 STT 시나리오로 변환
  String _convertSessionTypeToScenario(String? sessionType) {
    switch (sessionType) {
      case '발표':
        return 'presentation'; // presentation 시나리오 사용
      case '소개팅':
        return 'dating'; // dating 시나리오 사용
      case '면접':
        return 'interview'; // interview 시나리오 사용
      case '코칭':
        return 'business'; // 코칭은 business로 매핑
      case '회의':  // 혹시 모를 레거시 케이스
        return 'business';
      default:
        return 'general';  // 기본값을 general로 변경
    }
  }

  /// 🔥 세그먼트 저장 타이머 시작 (30초마다)
  void _startSegmentSaveTimer() {
    _segmentStartTime = DateTime.now();
    _segmentSaveTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _saveCurrentSegment();
      _currentSegmentIndex++;
      _resetSegmentData();
    });
    print('📊 세그먼트 저장 타이머 시작 (30초 간격)');
  }

  /// 🔥 현재 세그먼트 데이터를 서버에 저장
  Future<void> _saveCurrentSegment() async {
    if (!_isRecording || _segmentStartTime == null) {
      print('⏸️ 녹음 중이 아니거나 세그먼트 시작 시간이 없어 저장 건너뜀');
      return;
    }

    try {
      final segmentData = {
        'segmentIndex': _currentSegmentIndex,
        'timestamp': _segmentStartTime!.toIso8601String(),
        'transcription': _transcription,
        'analysis': {
          'emotionState': _emotionState,
          'speakingSpeed': _speakingSpeed,
          'likability': _likability,
          'interest': _interest,
          'confidence': _calculateConfidence(), // 실제 신뢰도 값 계산
          'volume': _calculateVolume(), // 실제 볼륨 값 계산
          'pitch': _calculatePitch(), // 실제 피치 값 계산
        },
        'hapticFeedbacks': List.from(_segmentHapticFeedbacks),
        'suggestedTopics': List.from(_suggestedTopics),
      };

      final success = await _realtimeService.saveSegment(widget.sessionId, segmentData);
      
      if (success) {
        print('✅ 세그먼트 $_currentSegmentIndex 저장 완료');
      } else {
        print('❌ 세그먼트 $_currentSegmentIndex 저장 실패');
      }

    } catch (e) {
      print('❌ 세그먼트 저장 중 오류: $e');
    }
  }

  /// 🔥 세그먼트 데이터 초기화
  void _resetSegmentData() {
    _segmentHapticFeedbacks.clear();
    _segmentStartTime = DateTime.now();
    print('🔄 세그먼트 $_currentSegmentIndex 데이터 초기화');
  }

  /// 🔥 세션 종료 처리
  Future<void> _finalizeSession() async {
    try {
      // 마지막 세그먼트 저장
      await _saveCurrentSegment();
      
      // 세션 타입 변환 (presentation -> business 등)
      final sessionType = _convertSessionTypeToAnalytics(widget.sessionType);
      final totalDuration = _seconds;
      
      // 서버에서 모든 segments를 종합하여 sessionAnalytics 생성
      final success = await _realtimeService.finalizeSession(
        widget.sessionId, 
        sessionType,
        totalDuration: totalDuration,
      );
      
      if (success) {
        print('✅ 세션 데이터 통합 완료');
      } else {
        print('❌ 세션 종료 처리 실패');
      }
    } catch (e) {
      print('❌ 세션 종료 처리 중 오류: $e');
    }
  }

  /// 🔥 세션 타입을 analytics 형식으로 변환
  String _convertSessionTypeToAnalytics(String? sessionType) {
    switch (sessionType) {
      case '발표':
        return 'presentation';
      case 'presentation':
        return 'presentation';
      case '소개팅':
        return 'dating';
      case 'dating':
        return 'dating';
      case '면접':
        return 'interview';
      case 'interview':
        return 'interview';
      case '코칭':
        return 'coaching';
      case 'coaching':
        return 'coaching';
      default:
        print('⚠️ 알 수 없는 세션 타입: $sessionType, 기본값 presentation 사용');
        return 'presentation';
    }
  }

  /// 🔥 음성 신뢰도 계산 (transcription 품질 기반)
  double _calculateConfidence() {
    if (_transcription.isEmpty) return 0.0;
    
    // 텍스트 길이와 완성도를 기반으로 신뢰도 계산
    double baseConfidence = 0.5;
    
    // 텍스트 길이에 따른 점수 (긴 텍스트일수록 높은 신뢰도)
    if (_transcription.length > 50) {
      baseConfidence += 0.3;
    } else if (_transcription.length > 20) {
      baseConfidence += 0.2;
    } else if (_transcription.length > 10) {
      baseConfidence += 0.1;
    }
    
    // 완전한 문장 여부 확인 (마침표, 물음표, 느낌표 등)
    if (_transcription.contains('.') || _transcription.contains('?') || 
        _transcription.contains('!') || _transcription.contains('다') ||
        _transcription.contains('요')) {
      baseConfidence += 0.2;
    }
    
    // 노이즈 단어가 많으면 신뢰도 감소
    final noiseWords = ['음', '어', 'ㅋㅋ', 'ㅎㅎ'];
    final noiseCount = noiseWords.where((word) => _transcription.contains(word)).length;
    baseConfidence -= (noiseCount * 0.1);
    
    return max(0.0, min(1.0, baseConfidence));
  }

  /// 🔥 음성 볼륨 레벨 계산 (음성 활동 기반)
  double _calculateVolume() {
    // 현재 말하기 상태와 속도를 기반으로 볼륨 추정
    double baseVolume = 0.3; // 기본 볼륨
    
    // 말하기 속도가 빠를수록 볼륨이 클 가능성
    if (_speakingSpeed > 150) {
      baseVolume += 0.3;
    } else if (_speakingSpeed > 120) {
      baseVolume += 0.2;
    } else if (_speakingSpeed > 100) {
      baseVolume += 0.1;
    }
    
    // 감정 상태에 따른 볼륨 조정
    switch (_emotionState) {
      case 'excited':
      case 'happy':
        baseVolume += 0.2;
        break;
      case 'nervous':
      case 'anxious':
        baseVolume += 0.1;
        break;
      case 'calm':
      case 'relaxed':
        baseVolume -= 0.1;
        break;
    }
    
    // 텍스트에 감탄사나 강조 표현이 있으면 볼륨 증가
    if (_transcription.contains('!') || _transcription.contains('ㅋㅋ') || 
        _transcription.contains('와') || _transcription.contains('어머')) {
      baseVolume += 0.15;
    }
    
    return max(0.0, min(1.0, baseVolume));
  }

  /// 🔥 음성 피치 계산 (감정과 말하기 패턴 기반)
  double _calculatePitch() {
    double basePitch = 150.0; // 기본 피치 (Hz)
    
    // 감정 상태에 따른 피치 조정
    switch (_emotionState) {
      case 'excited':
      case 'happy':
        basePitch += 30.0; // 높은 피치
        break;
      case 'nervous':
      case 'anxious':
        basePitch += 20.0; // 약간 높은 피치
        break;
      case 'sad':
      case 'disappointed':
        basePitch -= 20.0; // 낮은 피치
        break;
      case 'angry':
        basePitch += 15.0; // 약간 높고 거친 피치
        break;
      case 'calm':
      case 'relaxed':
        basePitch -= 10.0; // 안정적인 낮은 피치
        break;
    }
    
    // 질문 형태면 피치 상승
    if (_transcription.contains('?') || _transcription.contains('뭐') || 
        _transcription.contains('어떻게') || _transcription.contains('왜')) {
      basePitch += 25.0;
    }
    
    // 감탄사가 있으면 피치 변화 증가
    if (_transcription.contains('!') || _transcription.contains('와') || 
        _transcription.contains('어머') || _transcription.contains('대박')) {
      basePitch += 20.0;
    }
    
    // 말하기 속도가 빠르면 피치도 약간 상승하는 경향
    if (_speakingSpeed > 160) {
      basePitch += 10.0;
    } else if (_speakingSpeed < 100) {
      basePitch -= 10.0;
    }
    
    // 피치 범위 제한 (인간 음성 범위 내)
    return max(80.0, min(300.0, basePitch));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Column(
          children: [
            _buildSessionHeader(),
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      _buildTranscriptionArea(),
                      const SizedBox(height: 20),
                      _buildMetricsSection(),
                      const SizedBox(height: 15),
                      if (_feedback.isNotEmpty) _buildFeedbackSection(),
                      const SizedBox(height: 15),
                      _buildSuggestedTopicsSection(),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
            _buildControlsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSessionHeader() {
    return Container(
      padding: const EdgeInsets.all(15),
      color: Colors.black.withOpacity(0.2),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              children: [
                Icon(_getSessionIcon(widget.sessionType), color: Colors.white, size: 18),
                const SizedBox(width: 5),
                Text(
                  widget.sessionType ?? '소개팅',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatTime(_seconds),
            style: TextStyle(
              color: AppColors.lightText,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              // STT 연결 상태
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _audioService.isSTTConnected ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'STT',
                style: TextStyle(
                  color: AppColors.lightText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 15),
              // Watch 연결 상태
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isWatchConnected ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'Watch',
                style: TextStyle(
                  color: AppColors.lightText,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 15),
              // 녹음 상태
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _isRecording ? Colors.red : Colors.grey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '녹음중',
                style: TextStyle(
                  color: AppColors.lightText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptionArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.text_snippet,
                color: AppColors.lightText,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '실시간 음성 인식',
        style: TextStyle(
          color: AppColors.lightText,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '30초 단위',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _transcription.isEmpty ? '음성을 30초 단위로 분석하고 있습니다...' : _transcription,
            style: TextStyle(
              color: _transcription.isEmpty ? AppColors.disabledText : AppColors.lightText,
          fontSize: 16,
          height: 1.5,
        ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '주요 지표',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              Text(
                '실시간',
                style: TextStyle(
                  color: AppColors.disabledText,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          // 세션 타입에 따라 다른 지표 표시
          if (widget.sessionType == '발표') ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: '자신감',
                    value: '$_likability%',
                    icon: Icons.psychology,
                    progressValue: _likability / 100,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: '말하기 속도',
                    value: _getSpeedText(_speakingSpeed),
                    icon: Icons.speed,
                    progressValue: _speakingSpeed > 0 ? _speakingSpeed / 200 : 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: '설득력',
                    value: '$_interest%',
                    icon: Icons.trending_up,
                    progressValue: _interest / 100,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: '명확성',
                    value: _emotionState,
                    icon: Icons.radio_button_checked,
                    isTextValue: true,
                  ),
                ),
              ],
            ),
          ] else if (widget.sessionType == '면접' || widget.sessionType == '면접(인터뷰)') ...[
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: '자신감',
                    value: '$_likability%',
                    icon: Icons.psychology,
                    progressValue: _likability / 100,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: '말하기 속도',
                    value: _getSpeedText(_speakingSpeed),
                    icon: Icons.speed,
                    progressValue: _speakingSpeed > 0 ? _speakingSpeed / 200 : 0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    title: '명확성',
                    value: '$_interest%',
                    icon: Icons.radio_button_checked,
                    progressValue: _interest / 100,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricCard(
                    title: '안정감',
                    value: _emotionState,
                    icon: Icons.sentiment_satisfied_alt,
                    isTextValue: true,
                  ),
                ),
              ],
            ),
          ] else ...[
            // 소개팅 모드 (기본)
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: '감정 상태',
                  value: _emotionState,
                  icon: Icons.sentiment_satisfied_alt,
                  isTextValue: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: '말하기 속도',
                    value: _getSpeedText(_speakingSpeed),
                  icon: Icons.speed,
                    progressValue: _speakingSpeed > 0 ? _speakingSpeed / 200 : 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: '호감도',
                  value: '$_likability%',
                  icon: Icons.favorite,
                  progressValue: _likability / 100,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricCard(
                  title: '관심도',
                  value: '$_interest%',
                  icon: Icons.star,
                  progressValue: _interest / 100,
                ),
              ),
            ],
          ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    bool isTextValue = false,
    double? progressValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.lightText,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Icon(icon, size: 16, color: AppColors.lightText),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (progressValue != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeedbackSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.2),
        border: Border.all(color: AppColors.primary),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: AppColors.lightText,
            size: 24,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _feedback,
              style: TextStyle(
                color: AppColors.lightText,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedTopicsSection() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 5),
              Text(
                '추천 대화 주제',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _suggestedTopics.map((topic) {
              bool isHighlighted = topic == '여행 경험';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? AppColors.primary.withOpacity(0.3)
                      : AppColors.darkCardBackground,
                  border: isHighlighted
                      ? Border.all(color: AppColors.primary)
                      : null,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  topic,
                  style: TextStyle(
                    color: isHighlighted
                        ? AppColors.accentLight
                        : AppColors.lightText,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      color: AppColors.darkBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[700],
            child: IconButton(
              icon: const Icon(Icons.pause, color: Colors.white),
              onPressed: () async {
                if (_isRecording) {
                  await _audioService.pauseRecording();
                }
              },
            ),
          ),
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.red,
            child: IconButton(
              icon: const Icon(Icons.stop, color: Colors.white),
              onPressed: _showEndSessionDialog,
            ),
          ),
          CircleAvatar(
            radius: 25,
            backgroundColor: _isRecording 
                ? Colors.red 
                : (_isAudioInitialized ? Colors.green : Colors.grey[700]),
            child: IconButton(
              icon: Icon(
                _isRecording ? Icons.mic : Icons.mic_off,
                color: Colors.white,
              ),
              onPressed: _toggleRecording,
            ),
          ),
        ],
      ),
    );
  }

  /// 세션 타입에 따른 아이콘 반환
  IconData _getSessionIcon(String? sessionType) {
    switch (sessionType) {
      case '발표':
        return Icons.present_to_all;
      case '소개팅':
        return Icons.people;
      case '면접(인터뷰)':
      case '면접':
        return Icons.business_center;
      case '코칭':
        return Icons.psychology;
      case '비즈니스':
        return Icons.handshake;
      default:
        return Icons.people;
    }
  }

  void _showEndSessionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.stop_circle_outlined,
                color: Colors.red[600],
                size: 24,
              ),
              const SizedBox(width: 8),
              const Text(
                '세션 종료',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),
            ],
          ),
          content: const Text(
            '현재 진행 중인 분석 세션을 종료하고\n결과를 생성하시겠습니까?',
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF757575),
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                '계속 진행',
                style: TextStyle(
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // 다이얼로그 닫기
                _endSession(); // 세션 종료
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                '종료하기',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 🚀 Watch 메시지 스트림 구독
  void _subscribeToWatchMessages() {
    print('🔗 Watch 메시지 스트림 구독 시작');
    
    try {
      _watchMessageSubscription = _watchService.watchMessages.listen(
        (message) {
          print('📨 핸드폰에서 Watch 메시지 수신: $message');
          if (mounted) {
            _handleWatchMessage(message);
          }
        },
        onError: (error) {
          print('❌ Watch 메시지 스트림 에러: $error');
        },
        onDone: () {
          print('📡 Watch 메시지 스트림 종료');
        },
      );
      
      print('✅ Watch 메시지 스트림 구독 완료');
      
    } catch (e) {
      print('❌ Watch 메시지 스트림 구독 실패: $e');
    }
  }

  /// 🚀 Watch 메시지 처리
  void _handleWatchMessage(Map<String, dynamic> message) {
    final action = message['action'] as String?;
    
    switch (action) {
      case 'watchSessionStarted':
        print('🎉 Watch에서 세션 진입 완료 신호 수신');
        final sessionType = message['sessionType'] as String?;
        setState(() {
          _feedback = 'Apple Watch에서 $sessionType 세션이 시작되었습니다!';
        });
        
        // 5초 후 피드백 메시지 클리어
        Timer(Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _feedback = '';
            });
          }
        });
        break;
        
      case 'watchConnected':
        print('📱 Watch 연결 신호 수신');
        setState(() {
          _isWatchConnected = true;
        });
        break;
        
      default:
        print('⚠️ 알 수 없는 Watch 메시지: $action');
        break;
    }
  }
}

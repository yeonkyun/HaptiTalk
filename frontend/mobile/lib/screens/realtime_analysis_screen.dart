import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:hapti_talk/constants/colors.dart';
import 'package:hapti_talk/screens/analysis_summary_screen.dart';

class RealtimeAnalysisScreen extends StatefulWidget {
  final String sessionTitle;
  final String sessionTag;
  final String elapsedTime;

  const RealtimeAnalysisScreen(
      {Key? key,
      required this.sessionTitle,
      required this.sessionTag,
      required this.elapsedTime})
      : super(key: key);

  @override
  State<RealtimeAnalysisScreen> createState() => _RealtimeAnalysisScreenState();
}

class _RealtimeAnalysisScreenState extends State<RealtimeAnalysisScreen> {
  // 현재 대화 내용 (실제로는 API에서 받아올 내용)
  String conversationText =
      "저는 평소에 여행을 좋아해서 시간이 날 때마다 이곳저곳 다니는 편이에요. 사진 찍는 것도 좋아해서 여행지에서 사진을 많이 찍어요. 특히 자연 경관이 아름다운 곳이나 역사적인 장소를 방문하는 걸 좋아합니다. 최근에는 제주도에 다녀왔는데, 정말 예뻤어요. 다음에는 어디로 여행 가보셨나요?";

  // 실시간 지표 (실제로는 API에서 받아올 내용)
  String emotionalState = "긍정적";
  int speakingSpeed = 85;
  int likeability = 78;
  int interestLevel = 92;

  // 추천 대화 주제
  final List<String> recommendedTopics = [
    "여행 경험",
    "좋아하는 여행지",
    "사진 취미",
    "역사적 장소",
    "제주도 명소"
  ];

  // 현재 활성화된 대화 주제
  String activeTopicName = "여행 경험";

  // 피드백 메시지
  String feedbackMessage = "말하기 속도가 빨라지고 있어요. 좀 더 천천히 말해보세요.";

  // 타이머 관련 변수
  Timer? _timer;
  int _seconds = 0;
  String _timerText = "00:00:00";

  // 음소거 상태
  bool _isMuted = true;

  @override
  void initState() {
    super.initState();
    // 상태 표시줄 스타일 설정
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    // 타이머 시작
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    // 앱 종료 시 상태 표시줄 원래대로 복원
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    super.dispose();
  }

  // 타이머 시작 함수
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        _updateTimerText();
      });
    });
  }

  // 타이머 텍스트 업데이트
  void _updateTimerText() {
    int hours = _seconds ~/ 3600;
    int minutes = (_seconds % 3600) ~/ 60;
    int secs = _seconds % 60;

    _timerText =
        "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  // 음소거 토글 함수
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
    });
  }

  // 설정 모달 표시 함수
  void _showSettingsModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, color: Colors.white, size: 24),
                  const SizedBox(width: 16),
                  const Text(
                    "세션 설정",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildSettingsItem(
                icon: Icons.equalizer,
                title: "분석 수준",
                subtitle: "표준",
              ),
              const Divider(color: Color(0xFF333333)),
              _buildSettingsItem(
                icon: Icons.save,
                title: "녹음 저장",
                subtitle: "7일 자동 삭제",
              ),
              const Divider(color: Color(0xFF333333)),
              _buildSettingsItem(
                icon: Icons.vibration,
                title: "햅틱 피드백",
                subtitle: "켜짐",
              ),
              const SizedBox(height: 30),
            ],
          ),
        );
      },
    );
  }

  // 설정 항목 위젯
  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFE0E0E0), size: 24),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFFBDBDBD),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          const Icon(Icons.chevron_right, color: Color(0xFFBDBDBD)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        body: Container(
          color: const Color(0xFF121212),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildConversationBox(),
                          const SizedBox(height: 16),
                          _buildRealTimeMetrics(),
                          const SizedBox(height: 16),
                          _buildFeedbackBox(),
                          const SizedBox(height: 16),
                          _buildRecommendedTopics(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                ),
                _buildControlPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 헤더 위젯
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      widget.sessionTag,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                _timerText,
                style: const TextStyle(
                    color: Color(0xFFE0E0E0),
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      "녹음중",
                      style: TextStyle(color: Color(0xFFE0E0E0), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 대화 내용 박스
  Widget _buildConversationBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        conversationText,
        style: const TextStyle(
            color: Color(0xFFE0E0E0), fontSize: 16, height: 1.5),
      ),
    );
  }

  // 실시간 지표 박스
  Widget _buildRealTimeMetrics() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "주요 지표",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "실시간",
                  style: TextStyle(color: Color(0xFFBDBDBD), fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard(
                title: "감정 상태",
                value: emotionalState,
                isText: true,
                icon: Icons.sentiment_satisfied_alt,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                title: "말하기 속도",
                value: "$speakingSpeed%",
                progress: speakingSpeed / 100,
                icon: Icons.speed,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricCard(
                title: "호감도",
                value: "$likeability%",
                progress: likeability / 100,
                icon: Icons.favorite_border,
              ),
              const SizedBox(width: 12),
              _buildMetricCard(
                title: "관심도",
                value: "$interestLevel%",
                progress: interestLevel / 100,
                icon: Icons.lightbulb_outline,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 지표 카드 위젯
  Widget _buildMetricCard({
    required String title,
    required String value,
    double? progress,
    bool isText = false,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
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
                  style: const TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                ),
                Icon(icon, size: 16, color: const Color(0xFFE0E0E0)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            if (!isText) const SizedBox(height: 8),
            if (!isText)
              Stack(
                children: [
                  Container(
                    height: 6,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF424242),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Container(
                    height: 6,
                    width: (progress ?? 0) *
                        MediaQuery.of(context).size.width *
                        0.35,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 피드백 박스
  Widget _buildFeedbackBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFE0E0E0), size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feedbackMessage,
              style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // 추천 대화 주제 위젯
  Widget _buildRecommendedTopics() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  size: 18, color: Colors.white),
              const SizedBox(width: 8),
              const Text(
                "추천 대화 주제",
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: recommendedTopics.map((topic) {
              bool isActive = topic == activeTopicName;
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primaryColor.withOpacity(0.3)
                      : const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(50),
                  border: isActive
                      ? Border.all(color: AppColors.primaryColor)
                      : null,
                ),
                child: Text(
                  topic,
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF90CAF9)
                        : const Color(0xFFE0E0E0),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // 하단 컨트롤 패널
  Widget _buildControlPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              InkWell(
                onTap: _toggleMute,
                child: _buildControlButton(
                  icon: _isMuted ? Icons.mic : Icons.mic_off,
                  color: _isMuted
                      ? AppColors.primaryColor
                      : const Color(0xFF424242),
                  size: 50,
                ),
              ),
              InkWell(
                onTap: () {
                  // 타이머 정지
                  _timer?.cancel();

                  // AnalysisSummaryScreen으로 이동
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AnalysisSummaryScreen(
                        sessionTitle: widget.sessionTitle,
                        sessionTag: widget.sessionTag,
                        sessionDate: '2024년 3월 23일 오후 2:30', // 현재 날짜로 설정 가능
                        sessionDuration: '1시간 32분', // 실제 elapsedTime 기반으로 설정 가능
                      ),
                    ),
                  );
                },
                child: _buildControlButton(
                  icon: Icons.stop,
                  color: Colors.red,
                  size: 60,
                ),
              ),
              InkWell(
                onTap: _showSettingsModal,
                child: _buildControlButton(
                  icon: Icons.settings,
                  color: const Color(0xFF424242),
                  size: 50,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // 컨트롤 버튼
  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
    );
  }
}

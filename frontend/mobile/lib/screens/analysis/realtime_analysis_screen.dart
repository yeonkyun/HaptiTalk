import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../constants/colors.dart';
import '../../models/analysis/analysis_result.dart';
import '../../models/session/session_model.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/analysis/metrics_card.dart';
import '../analysis/analysis_summary_screen.dart';

class RealtimeAnalysisScreen extends StatefulWidget {
  final String sessionId;

  const RealtimeAnalysisScreen({Key? key, required this.sessionId})
      : super(key: key);

  @override
  _RealtimeAnalysisScreenState createState() => _RealtimeAnalysisScreenState();
}

class _RealtimeAnalysisScreenState extends State<RealtimeAnalysisScreen> {
  late Timer _timer;
  int _seconds = 0;
  bool _isRecording = true;
  String _transcription = '';
  String _feedback = '';
  List<String> _suggestedTopics = [];

  // 분석 데이터
  String _emotionState = '긍정적';
  int _speakingSpeed = 85;
  int _likability = 78;
  int _interest = 92;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startAnalysis();

    // 초기 추천 주제 설정
    _suggestedTopics = ['여행 경험', '좋아하는 여행지', '사진 취미', '역사적 장소', '제주도 명소'];
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
      });
    });
  }

  void _startAnalysis() {
    // 실제 앱에서는 여기서 음성 인식 및 실시간 분석 시작
    // 예시 데이터로 대체
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _transcription =
            '저는 평소에 여행을 좋아해서 시간이 날 때마다\n이곳저곳 다니는 편이에요. 사진 찍는 것도 좋\n아해서 여행지에서 사진을 많이 찍어요. 특히\n자연 경관이 아름다운 곳이나 역사적인 장소를\n방문하는 걸 좋아합니다. 최근에는 제주도에 다\n녀왔는데, 정말 예뻤어요. 다음에는 어디로 여\n행 가보셨나요?';
        _feedback = '말하기 속도가 빨라지고 있어요. 좀 더 천천히 말해보세요.';
      });
    });
  }

  String _formatTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _toggleRecording() {
    setState(() {
      _isRecording = !_isRecording;
    });
  }

  void _endSession() {
    _timer.cancel();
    // 세션 종료 및 결과 화면으로 이동
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AnalysisSummaryScreen(sessionId: widget.sessionId),
      ),
    );
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
                const Icon(Icons.people, color: Colors.white, size: 18),
                const SizedBox(width: 5),
                Text(
                  '소개팅',
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
      child: Text(
        _transcription,
        style: TextStyle(
          color: AppColors.lightText,
          fontSize: 16,
          height: 1.5,
        ),
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
                  value: '$_speakingSpeed%',
                  icon: Icons.speed,
                  progressValue: _speakingSpeed / 100,
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
              onPressed: () {
                // 세션 일시 정지
              },
            ),
          ),
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.red,
            child: IconButton(
              icon: const Icon(Icons.stop, color: Colors.white),
              onPressed: _endSession,
            ),
          ),
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey[700],
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
}

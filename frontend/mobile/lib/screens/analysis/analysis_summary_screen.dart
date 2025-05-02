import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../constants/colors.dart';
import '../../models/analysis/analysis_result.dart';
import '../../models/session/session_model.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/analysis/metrics_card.dart';

class AnalysisSummaryScreen extends StatefulWidget {
  final String sessionId;

  const AnalysisSummaryScreen({Key? key, required this.sessionId})
      : super(key: key);

  @override
  State<AnalysisSummaryScreen> createState() => _AnalysisSummaryScreenState();
}

class _AnalysisSummaryScreenState extends State<AnalysisSummaryScreen> {
  late Future<AnalysisResult?> _analysisFuture;

  @override
  void initState() {
    super.initState();
    _loadAnalysisData();
  }

  void _loadAnalysisData() {
    _analysisFuture = Provider.of<AnalysisProvider>(context, listen: false)
        .getSessionAnalysis(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('세션 분석 결과'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<AnalysisResult?>(
        future: _analysisFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '오류가 발생했습니다: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('분석 결과를 찾을 수 없습니다.'),
            );
          }

          final analysis = snapshot.data!;
          return _buildAnalysisContent(analysis);
        },
      ),
    );
  }

  Widget _buildAnalysisContent(AnalysisResult analysis) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSessionInfoSection(),
          const SizedBox(height: 24),
          _buildMetricsSection(analysis),
          const SizedBox(height: 24),
          _buildTranscriptionSection(analysis),
          const SizedBox(height: 24),
          _buildFeedbackSection(analysis),
          const SizedBox(height: 24),
          _buildTopicsSection(analysis),
          const SizedBox(height: 24),
          _buildActionButtonsSection(),
        ],
      ),
    );
  }

  Widget _buildSessionInfoSection() {
    return FutureBuilder<SessionModel>(
      future: Provider.of<SessionProvider>(context, listen: false)
          .fetchSessionDetails(widget.sessionId),
      builder: (context, snapshot) {
        final sessionName = snapshot.hasData
            ? (snapshot.data!.name ?? '이름 없는 세션')
            : '세션 불러오는 중...';

        final sessionDuration = snapshot.hasData
            ? '${snapshot.data!.duration.inMinutes}분 ${snapshot.data!.duration.inSeconds % 60}초'
            : '--:--';

        final sessionMode = snapshot.hasData
            ? _getSessionModeText(snapshot.data!.mode)
            : '알 수 없음';

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sessionName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildInfoItem(Icons.timer, '세션 시간: $sessionDuration'),
                    const SizedBox(width: 16),
                    _buildInfoItem(Icons.category, '모드: $sessionMode'),
                  ],
                ),
                const SizedBox(height: 8),
                _buildInfoItem(
                  Icons.calendar_today,
                  '날짜: ${snapshot.hasData ? _formatDate(snapshot.data!.createdAt) : '불러오는 중...'}',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.secondaryText),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricsSection(AnalysisResult analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '분석 결과',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            EmotionMetricsCard(
              emotionState: analysis.emotionData.emotionState,
            ),
            SpeedMetricsCard(
              speedValue: analysis.speakingMetrics.speakingSpeed,
            ),
            LikabilityMetricsCard(
              likabilityValue: analysis.emotionData.likability,
            ),
            InterestMetricsCard(
              interestValue: analysis.emotionData.interest,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTranscriptionSection(AnalysisResult analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '대화 내용',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            analysis.transcription,
            style: TextStyle(
              fontSize: 15,
              color: AppColors.text,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeedbackSection(AnalysisResult analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '피드백',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...analysis.feedback
            .map((feedback) => _buildFeedbackItem(feedback))
            .toList(),
      ],
    );
  }

  Widget _buildFeedbackItem(String feedback) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: AppColors.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              feedback,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopicsSection(AnalysisResult analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '대화 주제',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: analysis.suggestedTopics
              .map((topic) => _buildTopicChip(topic))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildTopicChip(String topic) {
    return Chip(
      label: Text(topic),
      backgroundColor: AppColors.primary.withOpacity(0.1),
      labelStyle: TextStyle(color: AppColors.primary),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withOpacity(0.3)),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildActionButtonsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton.icon(
          onPressed: () {
            // 공유 기능 구현
          },
          icon: const Icon(Icons.share),
          label: const Text('공유하기'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.check),
          label: const Text('완료'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  String _getSessionModeText(SessionMode mode) {
    switch (mode) {
      case SessionMode.dating:
        return '소개팅';
      case SessionMode.interview:
        return '면접';
      case SessionMode.business:
        return '비즈니스';
      case SessionMode.coaching:
        return '코칭';
      default:
        return '기타';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}년 ${date.month}월 ${date.day}일';
  }
}

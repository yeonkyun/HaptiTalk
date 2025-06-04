import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../constants/colors.dart';
import '../../models/analysis/analysis_result.dart';
import '../../models/session/session_model.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/session_provider.dart';
import '../../widgets/analysis/metrics_card.dart';
import '../../screens/analysis/detailed_report_screen.dart';

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
        title: const Text('분석 결과'),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1, // 분석 탭 선택
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment),
            label: '분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '기록',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
          ),
        ],
        onTap: (index) {
          // 메인 탭 화면으로 돌아가고 해당 탭 선택
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/main',
            (route) => false,
            arguments: {'initialTabIndex': index},
          );
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
          _buildEmotionChartSection(analysis),
          const SizedBox(height: 24),
          _buildMetricsSection(analysis),
          const SizedBox(height: 24),
          _buildSpeakingRatioSection(),
          const SizedBox(height: 24),
          _buildInsightsSection(),
          const SizedBox(height: 24),
          _buildSuggestionsSection(),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
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
                          const SizedBox(height: 4),
                          Text(
                            '${_formatDate(snapshot.hasData ? snapshot.data!.createdAt : DateTime.now())}',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (sessionMode == '소개팅')
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          '소개팅',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildInfoItem(
                  Icons.timer,
                  '총 대화 시간: $sessionDuration',
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
        Icon(icon, size: 18, color: AppColors.secondaryText),
        const SizedBox(width: 8),
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

  Widget _buildEmotionChartSection(AnalysisResult analysis) {
    // 피그마에서의 감정 변화 그래프 부분
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, size: 18, color: AppColors.text),
                const SizedBox(width: 8),
                Text(
                  '감정 변화 그래프',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 160,
              padding: const EdgeInsets.only(right: 16),
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 100,
                  minY: 0,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const labels = [
                            '0:00',
                            '0:15',
                            '0:30',
                            '0:45',
                            '1:00',
                            '1:15',
                            '1:30'
                          ];
                          if (value.toInt() < 0 ||
                              value.toInt() >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              labels[value.toInt()],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    horizontalInterval: 25,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: 60,
                          color: AppColors.primary,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: 75,
                          color: AppColors.primary,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: 80,
                          color: AppColors.primary,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 3,
                      barRods: [
                        BarChartRodData(
                          toY: 90,
                          color: AppColors.primary,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 4,
                      barRods: [
                        BarChartRodData(
                          toY: 85,
                          color: AppColors.primary,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 5,
                      barRods: [
                        BarChartRodData(
                          toY: 82,
                          color: AppColors.primary,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 6,
                      barRods: [
                        BarChartRodData(
                          toY: 70,
                          color: AppColors.primary,
                          width: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsSection(AnalysisResult analysis) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '주요 지표',
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
          childAspectRatio: 1.2,
          children: [
            _buildMetricCard(
              '말하기 속도',
              '${analysis.metrics.speakingMetrics.speechRate.toInt()}/분',
              Icons.speed,
              '적절한 속도로 말했습니다',
            ),
            _buildMetricCard(
              '톤 & 억양',
              '85%',
              Icons.graphic_eq,
              '자연스러운 억양',
            ),
            _buildMetricCard(
              '호감도',
              '${analysis.metrics.emotionMetrics.averageLikeability.toInt()}%',
              Icons.favorite,
              '매우 우호적인 반응',
            ),
            _buildMetricCard(
              '경청 지수',
              '92%',
              Icons.headset,
              '우수한 경청 능력',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, String description) {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Icon(icon, size: 16, color: Colors.grey[700]),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const Spacer(),
            Text(
              description,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakingRatioSection() {
    return Card(
      elevation: 0,
      color: Colors.grey[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(
                  color: Colors.grey[300]!,
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  '60%',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '나',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '60%',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        '상대방',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '40%',
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '핵심 인사이트',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildInsightItem(
          1,
          '여행과 사진에 관한 이야기를 나눌 때 상대방의 호감도가 가장 높았습니다.',
        ),
        _buildInsightItem(
          2,
          '대화 중 상대방의 질문에 대한 응답 시간이 빨라 대화 참여도가 높았습니다.',
        ),
        _buildInsightItem(
          3,
          '상대방의 말을 경청하고 관련 질문을 이어가는 패턴이 효과적이었습니다.',
        ),
      ],
    );
  }

  Widget _buildInsightItem(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '개선 제안',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSuggestionCard(
                '말 끊기 줄이기',
                '상대방의 말이 끝날 때까지 기다린 후 대화를 이어가면 더 긍정적인 인상을 줄 수 있습니다.',
              ),
              const SizedBox(width: 12),
              _buildSuggestionCard(
                '공감 표현 늘리기',
                '"정말요?", "그렇군요" 같은 공감 표현을 더 자주 사용하면 상대방이 더 편안하게 대화할 수 있습니다.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSuggestionCard(String title, String content) {
    return Container(
      width: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtonsSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // 🔥 전체 보고서 보기 기능 구현 - DetailedReportScreen으로 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DetailedReportScreen(
                    sessionId: widget.sessionId,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.analytics),
            label: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text('전체 보고서'),
                Text('보기'),
              ],
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // 내보내기 기능 구현
            },
            icon: const Icon(Icons.share),
            label: const Text('내보내기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey[100],
              foregroundColor: Colors.grey[800],
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
    return '${date.year}년 ${date.month}월 ${date.day}일 ${date.hour > 12 ? "오후" : "오전"} ${date.hour > 12 ? date.hour - 12 : date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}

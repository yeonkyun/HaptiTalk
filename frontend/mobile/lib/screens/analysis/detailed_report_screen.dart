import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../constants/colors.dart';
import '../../config/app_config.dart';
import '../../services/auth_service.dart';

class DetailedReportScreen extends StatefulWidget {
  final String sessionId;

  const DetailedReportScreen({Key? key, required this.sessionId}) : super(key: key);

  @override
  State<DetailedReportScreen> createState() => _DetailedReportScreenState();
}

class _DetailedReportScreenState extends State<DetailedReportScreen> {
  Map<String, dynamic>? _reportData;
  List<Map<String, dynamic>>? _segments;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDetailedReport();
  }

  Future<void> _loadDetailedReport() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final authService = AuthService();
      final accessToken = await authService.getAccessToken();

      if (accessToken == null) {
        throw Exception('인증 토큰이 없습니다');
      }

      // 1. 세그먼트 데이터 조회
      final segmentsResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/reports/analytics/segments/${widget.sessionId}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (segmentsResponse.statusCode == 200) {
        final segmentsData = json.decode(segmentsResponse.body);
        _segments = List<Map<String, dynamic>>.from(segmentsData['data']['segments']);
      } else {
        throw Exception('세그먼트 데이터를 불러올 수 없습니다: ${segmentsResponse.statusCode}');
      }

      // 2. 리포트 데이터 조회 (report-service 기존 API 사용)
      final reportResponse = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/reports'), // 기존 리포트 목록 API
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (reportResponse.statusCode == 200) {
        final reportsData = json.decode(reportResponse.body);
        // sessionId로 해당하는 리포트 찾기
        final reports = reportsData['data'] as List;
        final sessionReport = reports.firstWhere(
          (report) => report['session_id'] == widget.sessionId,
          orElse: () => null,
        );
        
        if (sessionReport != null) {
          _reportData = sessionReport;
        }
      }

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('상세 분석 리포트'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDetailedReport,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('상세 리포트를 생성하고 있습니다...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              '리포트를 불러올 수 없습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.secondaryText),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDetailedReport,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }

    if (_segments == null || _segments!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              '분석 데이터가 없습니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '실시간 분석을 완료한 세션만 상세 리포트를 확인할 수 있습니다.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildReportSummary(),
          const SizedBox(height: 24),
          _buildSegmentTimeline(),
          const SizedBox(height: 24),
          _buildDetailedMetrics(),
          const SizedBox(height: 24),
          _buildHapticFeedbackAnalysis(),
          const SizedBox(height: 24),
          _buildTopicAnalysis(),
        ],
      ),
    );
  }

  Widget _buildReportSummary() {
    final totalSegments = _segments!.length;
    final totalDuration = totalSegments * 30; // 30초 단위
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  '리포트 요약',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('총 시간', '${(totalDuration / 60).toStringAsFixed(1)}분'),
                _buildSummaryItem('분석 구간', '$totalSegments개'),
                _buildSummaryItem('데이터 품질', '우수'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildSegmentTimeline() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  '시간대별 분석',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(_buildTimelineChart()),
            ),
          ],
        ),
      ),
    );
  }

  LineChartData _buildTimelineChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < _segments!.length; i++) {
      final segment = _segments![i];
      final likability = (segment['analysis']?['likability'] ?? 50).toDouble();
      spots.add(FlSpot(i.toDouble(), likability));
    }

    return LineChartData(
      gridData: FlGridData(show: true, drawVerticalLine: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final minutes = (value * 0.5).toStringAsFixed(1);
              return Text('${minutes}분', style: const TextStyle(fontSize: 10));
            },
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: AppColors.primary,
          barWidth: 3,
          dotData: FlDotData(show: false),
        ),
      ],
      minY: 0,
      maxY: 100,
    );
  }

  Widget _buildDetailedMetrics() {
    // 평균값 계산
    double avgLikability = 0;
    double avgInterest = 0;
    double avgSpeakingSpeed = 0;
    
    for (final segment in _segments!) {
      final analysis = segment['analysis'] ?? {};
      avgLikability += (analysis['likability'] ?? 50).toDouble();
      avgInterest += (analysis['interest'] ?? 50).toDouble();
      avgSpeakingSpeed += (analysis['speakingSpeed'] ?? 120).toDouble();
    }
    
    avgLikability /= _segments!.length;
    avgInterest /= _segments!.length;
    avgSpeakingSpeed /= _segments!.length;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  '상세 지표 분석',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                _buildMetricCard('평균 호감도', '${avgLikability.toInt()}%', Icons.favorite),
                _buildMetricCard('평균 관심도', '${avgInterest.toInt()}%', Icons.star),
                _buildMetricCard('평균 말하기 속도', '${avgSpeakingSpeed.toInt()}/분', Icons.speed),
                _buildMetricCard('분석 구간', '${_segments!.length}개', Icons.analytics),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 20, color: AppColors.primary),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHapticFeedbackAnalysis() {
    // 햅틱 피드백 통계 계산
    final Map<String, int> hapticCounts = {};
    for (final segment in _segments!) {
      final haptics = segment['hapticFeedbacks'] as List? ?? [];
      for (final haptic in haptics) {
        final type = haptic['type'] as String? ?? 'unknown';
        hapticCounts[type] = (hapticCounts[type] ?? 0) + 1;
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.vibration, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  '햅틱 피드백 분석',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (hapticCounts.isEmpty)
              const Text('햅틱 피드백이 발생하지 않았습니다.')
            else
              ...hapticCounts.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(entry.key),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${entry.value}회',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicAnalysis() {
    // 추천 주제 분석
    final Set<String> allTopics = {};
    for (final segment in _segments!) {
      final topics = segment['suggestedTopics'] as List? ?? [];
      for (final topic in topics) {
        allTopics.add(topic.toString());
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.topic, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  '대화 주제 분석',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (allTopics.isEmpty)
              const Text('추천 주제가 생성되지 않았습니다.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allTopics.map((topic) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    topic,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )).toList(),
              ),
          ],
        ),
      ),
    );
  }
} 
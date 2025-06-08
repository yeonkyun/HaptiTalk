import 'package:flutter/material.dart';
import '../../models/analysis/analysis_result.dart';
import '../../models/analysis/metrics.dart';
import '../../constants/colors.dart';

class SessionDetailTabSpeaking extends StatelessWidget {
  final AnalysisResult analysisResult;

  const SessionDetailTabSpeaking({
    Key? key,
    required this.analysisResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(0),
      children: [
        // 🔥 상단 지표 카드들 (4개 카드 2x2 그리드)
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  // 말하기 속도 카드
                  Expanded(
                    child: _buildMetricCard(
                      title: '말하기 속도',
                      value: '${analysisResult.metrics.speakingMetrics.speechRate.toStringAsFixed(0)}WPM',
                      subtitle: '적절한 속도 (80-120WPM)',
                      backgroundColor: Color(0xFFE8F5E8),
                      progressColor: Color(0xFF4CAF50),
                      progress: (analysisResult.metrics.speakingMetrics.speechRate / 150).clamp(0.0, 1.0),
                    ),
                  ),
                  SizedBox(width: 12),
                  // 설득력 카드 (실제 API 데이터 사용)
                  Expanded(
                    child: _buildMetricCard(
                      title: '설득력',
                      value: '${_getPersuasionLevel()}%',
                      subtitle: '청중 설득 효과성',
                      backgroundColor: Color(0xFFFFEBEE),
                      progressColor: Color(0xFFE57373),
                      progress: _getPersuasionLevel() / 100,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                children: [
                  // 명확성 카드
                  Expanded(
                    child: _buildMetricCard(
                      title: '명확성',
                      value: '${_getClarityLevel()}%',
                      subtitle: '메시지 전달 명확성',
                      backgroundColor: Color(0xFFE8F5E8),
                      progressColor: Color(0xFF4CAF50),
                      progress: _getClarityLevel() / 100,
                    ),
                  ),
                  SizedBox(width: 12),
                  // 발표 주도도 카드 (실제 API 데이터 사용)
                  Expanded(
                    child: _buildMetricCard(
                      title: '발표 주도도',
                      value: '${_getEngagementLevel()}%',
                      subtitle: '더 주도적인 발표 필요',
                      backgroundColor: Color(0xFFE3F2FD),
                      progressColor: Color(0xFF2196F3),
                      progress: _getEngagementLevel() / 100,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 🔥 말하기 속도 변화 차트
        _buildSpeechRateChart(),

        // 🔥 발표 말하기 패턴 섹션
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '발표 말하기 패턴',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),
              
              // 습관적 패턴 섹션
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.loop,
                          size: 20,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          '습관적 패턴',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    
                    // 🔥 실제 API 데이터에서 습관적 표현 태그 생성
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildHabitualExpressionTags(),
                    ),
                    
                    SizedBox(height: 15),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Color(0xFF666666),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _getHabitualPatternsAnalysis(),
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 🔥 지표 카드 위젯
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color backgroundColor,
    required Color progressColor,
    required double progress,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF666666),
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: progressColor,
            ),
          ),
          SizedBox(height: 8),
          // 진행률 바
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
          SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Color(0xFF666666),
            ),
          ),
        ],
      ),
    );
  }

  // 🔥 실제 API 데이터에서 습관적 표현 태그 생성
  List<Widget> _buildHabitualExpressionTags() {
    final communicationPatterns = analysisResult.rawApiData['communicationPatterns'] as List<dynamic>? ?? [];
    
    // 습관적 표현들 추출
    final habitualPhrases = communicationPatterns
        .where((pattern) => pattern['type'] == 'habitual_phrase')
        .map((pattern) => {
          'content': pattern['content'] ?? '',
          'count': pattern['count'] ?? 0,
        })
        .where((phrase) => phrase['content'].toString().isNotEmpty)
        .toList();

    if (habitualPhrases.isEmpty) {
      return [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '습관적 표현 없음',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF666666),
            ),
          ),
        ),
      ];
    }

    // 카운트 기준으로 정렬
    habitualPhrases.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    return habitualPhrases.take(5).map((phrase) {
      final content = phrase['content'] as String;
      final count = phrase['count'] as int;
      
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              content,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
            SizedBox(width: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  // 🔥 실제 API 데이터 기반 분석 메서드들
  int _getPersuasionLevel() {
    final specializationInsights = analysisResult.rawApiData['specializationInsights'] as Map<String, dynamic>? ?? {};
    final persuasionTechniques = specializationInsights['persuasion_techniques'] as Map<String, dynamic>? ?? {};
    return (persuasionTechniques['persuasion_level'] ?? 60).toInt();
  }

  int _getClarityLevel() {
    final specializationInsights = analysisResult.rawApiData['specializationInsights'] as Map<String, dynamic>? ?? {};
    final presentationClarity = specializationInsights['presentation_clarity'] as Map<String, dynamic>? ?? {};
    final clarityScore = (presentationClarity['clarity_score'] ?? 0).toDouble();
    // clarity_score가 0이면 기본값 80% 사용
    return clarityScore > 0 ? (clarityScore * 100).toInt() : 80;
  }

  int _getEngagementLevel() {
    final specializationInsights = analysisResult.rawApiData['specializationInsights'] as Map<String, dynamic>? ?? {};
    final audienceEngagement = specializationInsights['audience_engagement'] as Map<String, dynamic>? ?? {};
    return (audienceEngagement['engagement_score'] ?? 30).toInt();
  }

  String _getHabitualPatternsAnalysis() {
    final communicationPatterns = analysisResult.rawApiData['communicationPatterns'] as List<dynamic>? ?? [];
    
    // 습관적 표현들 추출
    final habitualPhrases = communicationPatterns
        .where((pattern) => pattern['type'] == 'habitual_phrase')
        .toList();

    if (habitualPhrases.isEmpty) {
      return '발표 중 특별한 습관적 표현이 발견되지 않았습니다. 자연스러운 발표 패턴을 보이고 있습니다.';
    }

    // 🔧 타입 캐스팅 명시적으로 처리
    final totalCount = habitualPhrases
        .map((phrase) => (phrase['count'] ?? 0) as int)
        .fold(0, (sum, count) => sum + count);
    
    final mostUsed = habitualPhrases.reduce((a, b) => 
        ((a['count'] ?? 0) as int) > ((b['count'] ?? 0) as int) ? a : b);
    
    final mostUsedContent = mostUsed['content'] ?? '';
    final mostUsedCount = (mostUsed['count'] ?? 0) as int;
    
    if (totalCount >= 10) {
      return '"$mostUsedContent" 표현을 ${mostUsedCount}회 사용하여 습관적 패턴이 강합니다. 다양한 표현을 시도해보세요.';
    } else if (totalCount >= 5) {
      return '"$mostUsedContent" 표현을 ${mostUsedCount}회 사용했습니다. 적당한 수준의 습관적 표현입니다.';
    } else {
      return '습관적 표현 사용이 적절합니다. 자연스러운 발표 흐름을 유지하고 있습니다.';
    }
  }

  // 말하기 속도 차트 생성 (실제 데이터 기반)
  Widget _buildSpeechRateChart() {
    final emotionData = analysisResult.emotionData;
    final baseRate = analysisResult.metrics.speakingMetrics.speechRate;
    
    List<double> speechRates;
    
    if (emotionData.isNotEmpty) {
      // 감정 데이터를 기반으로 말하기 속도 변화 추정
      speechRates = emotionData.map((data) {
        // 감정이 높을 때 말하기 속도가 약간 빨라지는 경향 반영
        final emotionFactor = (data.value - 50) * 0.2; // -10 ~ +10 범위
        return (baseRate + emotionFactor).clamp(40.0, 180.0);
      }).toList();
    } else {
      // 기본 패턴 생성
      speechRates = List.generate(12, (index) {
        final variation = (index % 3 - 1) * 5; // -5, 0, +5 패턴
        return (baseRate + variation).clamp(40.0, 180.0);
      });
    }

    final maxHeight = 60.0;
    final minRate = 60.0;
    final maxRate = 140.0;

    // 🔧 오버플로우 방지를 위한 안전한 레이아웃
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final barCount = speechRates.length;
        final spacing = 4.0;
        final totalSpacing = spacing * (barCount - 1);
        final barWidth = (availableWidth - totalSpacing) / barCount;
        final safeBarWidth = barWidth.clamp(8.0, 20.0); // 최소 8, 최대 20

        return Wrap(
          spacing: spacing,
          alignment: WrapAlignment.spaceEvenly,
          children: speechRates.map((rate) {
            // 🔧 높이 계산 개선: 최소 높이 보장하고 더 선형적으로 표현
            final normalizedHeight = ((rate - minRate) / (maxRate - minRate)) * maxHeight;
            final height = normalizedHeight.clamp(15.0, maxHeight); // 🔧 최소 높이를 10 → 15로 증가
            
            return Container(
              width: safeBarWidth,
              height: height,
              decoration: BoxDecoration(
                color: _getSpeechRateColor(rate),
                borderRadius: BorderRadius.circular(3), // 🔧 모서리를 더 둥글게
                boxShadow: [ // 🔧 그림자 추가로 시각적 깊이감
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Color _getSpeechRateColor(double rate) {
    if (rate >= 80 && rate <= 120) return AppColors.primary;
    if (rate >= 60 && rate <= 140) return Colors.orange;
    return Colors.red;
  }
}

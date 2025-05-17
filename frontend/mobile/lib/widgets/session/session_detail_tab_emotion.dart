import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/analysis/analysis_result.dart';
import '../../models/analysis/emotion_data.dart';
import '../../models/analysis/metrics.dart';
import '../../constants/colors.dart';

class SessionDetailTabEmotion extends StatelessWidget {
  final AnalysisResult analysisResult;

  const SessionDetailTabEmotion({
    Key? key,
    required this.analysisResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final emotionMetrics = analysisResult.metrics.emotionMetrics;
    final screenWidth = MediaQuery.of(context).size.width;

    return ListView(
      padding: EdgeInsets.all(0),
      children: [
        // 평균 호감도 섹션
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '평균 호감도',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 호감도 게이지 카드
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // 호감도 게이지
                    SizedBox(
                      height: 180,
                      child: Center(
                        child: _buildEmotionGauge(context, emotionMetrics),
                      ),
                    ),
                    SizedBox(height: 10),

                    // 설명 텍스트
                    Text(
                      emotionMetrics.averageLikeability >= 70
                          ? '아주 좋은 호감도를 보였습니다'
                          : emotionMetrics.averageLikeability >= 50
                              ? '긍정적인 호감도를 보였습니다'
                              : '중립적인 호감도를 보였습니다',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 감정 지표 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '감정 지표',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 감정 지표 카드들 (2x2 그리드)
              Row(
                children: [
                  // 왼쪽 열
                  Expanded(
                    child: Column(
                      children: [
                        // 최고 호감도 카드
                        _buildMetricCard(
                          title: '최고 호감도',
                          value: '${emotionMetrics.peakLikeability.toInt()}%',
                          description: '제주도 여행 이야기 중',
                          icon: Icons.thumb_up,
                          color: AppColors.primary,
                        ),
                        SizedBox(height: 15),
                        // 관심도 카드
                        _buildMetricCard(
                          title: '평균 관심도',
                          value: '${emotionMetrics.averageInterest.toInt()}%',
                          description: '전체 대화에서의 관심도',
                          icon: Icons.visibility,
                          color: Color(0xFF7986CB),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 15),
                  // 오른쪽 열
                  Expanded(
                    child: Column(
                      children: [
                        // 최저 호감도 카드
                        _buildMetricCard(
                          title: '최저 호감도',
                          value: '${emotionMetrics.lowestLikeability.toInt()}%',
                          description: '음악 취향 토론 중',
                          icon: Icons.thumb_down,
                          color: Color(0xFFE57373),
                        ),
                        SizedBox(height: 15),
                        // 경청 지수 카드
                        _buildMetricCard(
                          title: '경청 지수',
                          value:
                              '${analysisResult.metrics.conversationMetrics.listeningScore.toInt()}%',
                          description: '상대방 이야기에 대한 반응',
                          icon: Icons.hearing,
                          color: Color(0xFF4DB6AC),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 주요 감정 변화 포인트 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '주요 감정 변화 포인트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 감정 변화 카드
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 카드 타이틀
                    Row(
                      children: [
                        Icon(
                          Icons.insights,
                          size: 20,
                          color: Color(0xFF212121),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '감정 변화',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),

                    // 감정 변화 항목들
                    _buildEmotionChangeItem(
                      time: '00:16:32',
                      description: '여행 대화로 전환되면서 공통 관심사를 발견했고, 호감도가 크게 상승했습니다.',
                      isPositive: true,
                    ),
                    SizedBox(height: 12),
                    _buildEmotionChangeItem(
                      time: '00:42:15',
                      description:
                          '제주도 여행 경험을 공유하면서 감정적 교감이 생겨 호감도가 최고점에 도달했습니다.',
                      isPositive: true,
                    ),
                    SizedBox(height: 12),
                    _buildEmotionChangeItem(
                      time: '01:05:48',
                      description:
                          '음악 취향에 대해 너무 자세히 설명하면서 상대방의 관심도가 약간 떨어졌습니다.',
                      isPositive: false,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 감정 피드백 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '감정 피드백',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 강점 피드백
              _buildFeedbackCard(
                title: '강점',
                icon: Icons.star,
                iconColor: Color(0xFFFFA000),
                description:
                    '여행과 사진에 대한 진정성 있는 대화로 공감대를 형성했습니다. 상대방의 반응에 적절히 호응하며 자연스러운 대화를 이끌어 냈습니다.',
              ),
              SizedBox(height: 15),

              // 개선점 피드백
              _buildFeedbackCard(
                title: '개선점',
                icon: Icons.build,
                iconColor: Color(0xFF7986CB),
                description:
                    '때로는 상대방이 말을 마치기 전에 대답하는 경향이 있습니다. 상대방의 말에 더 집중하고 충분한 반응 시간을 가지면 더 좋은 인상을 줄 수 있습니다.',
              ),
              SizedBox(height: 15),

              // 감정 이해 피드백
              _buildFeedbackCard(
                title: '감정 이해',
                icon: Icons.psychology,
                iconColor: Color(0xFF4DB6AC),
                description:
                    '전반적으로 상대방의 감정을 잘 이해하고 공감적인 태도를 보였습니다. 상대방이 관심을 보이는 주제에 더 집중하면 호감도를 더 높일 수 있습니다.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 감정 게이지 위젯
  Widget _buildEmotionGauge(BuildContext context, EmotionMetrics metrics) {
    final avgLikeability = metrics.averageLikeability;

    // 색상 설정
    Color gaugeColor;
    if (avgLikeability >= 70) {
      gaugeColor = AppColors.primary;
    } else if (avgLikeability >= 40) {
      gaugeColor = Color(0xFFFFA000);
    } else {
      gaugeColor = Color(0xFFE57373);
    }

    return Container(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 배경 게이지
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Color(0xFFE0E0E0),
                width: 15,
              ),
            ),
          ),

          // 채워진 게이지
          CustomPaint(
            size: Size(150, 150),
            painter: GaugePainter(
              percentage: avgLikeability / 100,
              color: gaugeColor,
              strokeWidth: 15,
            ),
          ),

          // 게이지 중앙 숫자
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${avgLikeability.toInt()}%',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: gaugeColor,
                ),
              ),
              Text(
                '호감도',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF757575),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 메트릭 카드 위젯
  Widget _buildMetricCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 아이콘과 제목
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: color,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          // 값
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 5),

          // 설명
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  // 감정 변화 아이템 위젯
  Widget _buildEmotionChangeItem({
    required String time,
    required String description,
    required bool isPositive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 아이콘
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPositive
                ? AppColors.primary.withOpacity(0.1)
                : Color(0xFFE57373).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 18,
            color: isPositive ? AppColors.primary : Color(0xFFE57373),
          ),
        ),
        SizedBox(width: 10),

        // 내용
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 시간
              Text(
                time,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPositive ? AppColors.primary : Color(0xFFE57373),
                ),
              ),
              SizedBox(height: 4),

              // 설명
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF616161),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 피드백 카드 위젯
  Widget _buildFeedbackCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required String description,
  }) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 제목과 아이콘
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor,
              ),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),

          // 피드백 내용
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }
}

// 원형 게이지를 그리기 위한 CustomPainter
class GaugePainter extends CustomPainter {
  final double percentage;
  final Color color;
  final double strokeWidth;

  GaugePainter({
    required this.percentage,
    required this.color,
    this.strokeWidth = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 각도를 라디안으로 변환 (시작은 상단, 시계 방향으로 진행)
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * percentage;

    // 아크 그리기
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant GaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage ||
      oldDelegate.color != color ||
      oldDelegate.strokeWidth != strokeWidth;
}

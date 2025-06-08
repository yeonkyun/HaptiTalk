import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../models/analysis/analysis_result.dart';

class SessionDetailTabTimeline extends StatelessWidget {
  final AnalysisResult analysisResult;

  const SessionDetailTabTimeline({Key? key, required this.analysisResult})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(0),
      children: [
        // 세션 요약 섹션
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '세션 요약',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 요약 카드
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: Color(0xFF212121),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${_getSessionTypeName()} 요약',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      _generateSessionSummary(),
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

        // 감정 변화 타임라인 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getSessionTypeMetricName()} 변화 타임라인',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 지표 그래프 컨테이너
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 그래프 제목
                    Row(
                      children: [
                        Icon(
                          _getSessionIcon(),
                          size: 20,
                          color: Color(0xFF212121),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${_getPrimaryMetricName()} 변화',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // 그래프 영역
                    Container(
                      height: 160,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _buildEmotionGraph(context),
                      ),
                    ),

                    // 시작/종료
                    Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '시작',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9E9E9E),
                            ),
                          ),
                          Text(
                            '종료',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9E9E9E),
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

        // 주요 변화 포인트 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '주요 변화 포인트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 타임라인 컨테이너
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 타임라인 제목
                    Row(
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 20,
                          color: Color(0xFF212121),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${_getPrimaryMetricName()} 변화 포인트',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),

                    // 타임라인 (세로선 + 포인트들)
                    Container(
                      child: Stack(
                        children: [
                          // 세로선
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 2,
                              color: Color(0xFFE0E0E0),
                            ),
                          ),

                          // 변화 포인트 아이템들
                          Column(
                            children: _buildChangePoints(),
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

        // 대화 키워드 섹션
        if (analysisResult.metrics.topicMetrics.topics.isNotEmpty)
          Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getSessionTypeName()} 키워드',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
                SizedBox(height: 15),

                // 키워드 컨테이너
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.tag,
                            size: 20,
                            color: Color(0xFF212121),
                          ),
                          SizedBox(width: 8),
                          Text(
                            '자주 언급된 단어',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF212121),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 15),

                      // 키워드 태그 클라우드 (실제 데이터 기반)
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _buildKeywordTags(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

        // 개선 포인트 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '개선 포인트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 개선점들 (실제 데이터 기반)
              ..._buildImprovementAreas(),
            ],
          ),
        ),
      ],
    );
  }

  // 감정 변화 그래프 위젯
  Widget _buildEmotionGraph(BuildContext context) {
    // 실제 구현에서는 분석 결과 데이터를 사용하여 Line Chart를 그릴 수 있음
    // 여기서는 커스텀 페인터 예시를 제공

    return CustomPaint(
      size: Size(MediaQuery.of(context).size.width, 150),
      painter: EmotionGraphPainter(),
    );
  }

  // 변화 포인트 아이템 위젯
  Widget _buildChangePointItem(
      String time, String title, String description, bool isPositive) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 타임라인 포인트
        Container(
          margin: EdgeInsets.only(right: 14),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isPositive ? AppColors.primary : Color(0xFFE57373),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),

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
                  fontWeight: FontWeight.w700,
                  color: isPositive ? AppColors.primary : Color(0xFFE57373),
                ),
              ),
              SizedBox(height: 2),

              // 제목
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424242),
                ),
              ),
              SizedBox(height: 5),

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

  // 키워드 태그 위젯
  Widget _buildKeywordTag(String keyword, int count,
      {bool isHighlight = false}) {
    final double size = isHighlight ? 1.0 : 0.85; // 강조 키워드는 더 크게 표시

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: isHighlight
            ? AppColors.primary.withOpacity(0.2)
            : Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$keyword ($count)',
        style: TextStyle(
          fontSize: 13 * size,
          fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
          color: isHighlight ? AppColors.primary : Color(0xFF616161),
        ),
      ),
    );
  }

  String _getSessionTypeName() {
    final category = analysisResult.category.toLowerCase();
    if (category.contains('발표') || category == 'presentation') return '발표';
    if (category.contains('면접') || category == 'interview') return '면접';
    if (category.contains('소개팅') || category == 'dating') return '소개팅';
    return '세션';
  }

  String _generateSessionSummary() {
    final sessionType = _getSessionTypeKey();
    final duration = (analysisResult.metrics.totalDuration / 60).round();
    final avgScore = (analysisResult.metrics.emotionMetrics.averageLikeability + 
                     analysisResult.metrics.emotionMetrics.averageInterest) / 2;
    
    String performanceDesc = avgScore >= 70 ? '우수한' : avgScore >= 50 ? '양호한' : '보통의';
    
    switch (sessionType) {
      case 'presentation':
        return '${duration}분간 진행된 발표에서 ${performanceDesc} 성과를 보였습니다. '
               '청중의 관심을 유지하며 명확한 메시지 전달에 집중했습니다. '
               '말하기 속도는 ${analysisResult.metrics.speakingMetrics.speechRate.toInt()}WPM으로 적절했으며, '
               '전반적으로 안정적인 발표를 진행했습니다.';
      
      case 'interview':
        return '${duration}분간 진행된 면접에서 ${performanceDesc} 답변을 제공했습니다. '
               '체계적인 답변 구조와 적절한 자신감을 보여주었으며, '
               '말하기 속도는 ${analysisResult.metrics.speakingMetrics.speechRate.toInt()}WPM으로 안정적이었습니다. '
               '전문성과 경험을 효과적으로 어필했습니다.';
               
      case 'dating':
        return '${duration}분간 진행된 대화에서 ${performanceDesc} 상호작용을 보였습니다. '
               '자연스러운 대화 흐름을 유지하며 상대방과의 공감대를 형성했습니다. '
               '경청 자세와 적절한 질문으로 긍정적인 분위기를 만들어냈으며, '
               '말하기 속도도 ${analysisResult.metrics.speakingMetrics.speechRate.toInt()}WPM으로 적절했습니다.';
               
      default:
        return '${duration}분간 진행된 세션에서 ${performanceDesc} 성과를 달성했습니다.';
    }
  }

  String _getSessionTypeKey() {
    final category = analysisResult.category.toLowerCase();
    if (category.contains('발표') || category == 'presentation') return 'presentation';
    if (category.contains('면접') || category == 'interview') return 'interview';
    if (category.contains('소개팅') || category == 'dating') return 'dating';
    return 'presentation';
  }

  String _getSessionTypeMetricName() {
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return '발표 자신감';
      case 'interview':
        return '면접관 평가';
      case 'dating':
        return '호감도';
      default:
        return '성과 지표';
    }
  }

  IconData _getSessionIcon() {
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return Icons.campaign;
      case 'interview':
        return Icons.work;
      case 'dating':
        return Icons.favorite_outline;
      default:
        return Icons.analytics;
    }
  }

  String _getPrimaryMetricName() {
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return '발표 자신감';
      case 'interview':
        return '면접관 평가';
      case 'dating':
        return '호감도';
      default:
        return '성과 지표';
    }
  }

  List<Widget> _buildChangePoints() {
    final emotionData = analysisResult.emotionData;
    final changePoints = <Widget>[];
    
    if (emotionData.isEmpty) {
      changePoints.add(_buildChangePointItem(
        '세션 전체',
        '안정적인 진행',
        '전반적으로 일정한 수준을 유지하며 진행되었습니다.',
        true,
      ));
      return changePoints;
    }

    // 실제 데이터에서 주요 변화점 찾기
    double maxValue = emotionData.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    double minValue = emotionData.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    
    int maxIndex = emotionData.indexWhere((e) => e.value == maxValue);
    int minIndex = emotionData.indexWhere((e) => e.value == minValue);
    
    // 최고점
    if (maxIndex >= 0) {
      String time = _formatTimeFromIndex(maxIndex, emotionData.length);
      changePoints.add(_buildChangePointItem(
        time,
        '${_getPrimaryMetricName()} 최고점',
        _getPositiveChangeDescription(maxValue),
        true,
      ));
      
      if (changePoints.length < 3) {
        changePoints.add(SizedBox(height: 15));
      }
    }
    
    // 최저점 (너무 낮지 않은 경우만)
    if (minIndex >= 0 && minValue < 60 && minIndex != maxIndex) {
      String time = _formatTimeFromIndex(minIndex, emotionData.length);
      changePoints.add(_buildChangePointItem(
        time,
        '주의 필요 구간',
        _getNegativeChangeDescription(minValue),
        false,
      ));
      
      if (changePoints.length < 5) {
        changePoints.add(SizedBox(height: 15));
      }
    }
    
    // 회복점 (최저점 이후 상승)
    if (minIndex < emotionData.length - 1) {
      for (int i = minIndex + 1; i < emotionData.length; i++) {
        if (emotionData[i].value > minValue + 10) {
          String time = _formatTimeFromIndex(i, emotionData.length);
          changePoints.add(_buildChangePointItem(
            time,
            '${_getPrimaryMetricName()} 회복',
            '적절한 조치로 상황이 개선되었습니다.',
            true,
          ));
          break;
        }
      }
    }
    
    return changePoints;
  }

  String _formatTimeFromIndex(int index, int totalPoints) {
    final totalSeconds = analysisResult.metrics.totalDuration;
    final segmentSeconds = totalSeconds / totalPoints;
    final currentSeconds = (index * segmentSeconds).round();
    
    final minutes = currentSeconds ~/ 60;
    final seconds = currentSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getPositiveChangeDescription(double value) {
    final sessionType = _getSessionTypeKey();
    switch (sessionType) {
      case 'presentation':
        return '발표 자신감이 최고조에 달했습니다. 안정적인 말하기 속도와 확신 있는 톤으로 효과적인 메시지 전달이 이루어졌습니다.';
      case 'interview':
        return '면접관의 평가가 가장 높았던 순간입니다. 체계적인 답변과 자신감 있는 태도가 좋은 인상을 남겼습니다.';
      case 'dating':
        return '상대방의 호감도가 가장 높았던 순간입니다. 공통 관심사 발견이나 자연스러운 유머가 효과적이었습니다.';
      default:
        return '가장 좋은 성과를 보인 구간입니다.';
    }
  }

  String _getNegativeChangeDescription(double value) {
    final sessionType = _getSessionTypeKey();
    switch (sessionType) {
      case 'presentation':
        return '발표 자신감이 다소 떨어진 구간입니다. 말하기 속도가 불안정하거나 망설임이 있었을 가능성이 있습니다.';
      case 'interview':
        return '답변에 확신이 부족해 보인 구간입니다. 더 구체적인 경험이나 사례를 제시하면 좋겠습니다.';
      case 'dating':
        return '대화 흐름이 다소 어색했던 순간입니다. 상대방의 관심사에 더 집중하거나 주제 전환이 필요했습니다.';
      default:
        return '개선이 필요한 구간입니다.';
    }
  }

  List<Widget> _buildKeywordTags() {
    final topics = analysisResult.metrics.topicMetrics.topics;
    final tags = <Widget>[];
    
    for (int i = 0; i < topics.length && i < 12; i++) {
      final topic = topics[i];
      final isHighlight = i < 3; // 상위 3개는 하이라이트
      tags.add(_buildKeywordTag(topic.name, topic.percentage.round(), isHighlight: isHighlight));
    }
    
    if (tags.isEmpty) {
      tags.add(Container(
        padding: EdgeInsets.all(12),
        child: Text(
          '키워드 분석 데이터가 충분하지 않습니다.',
          style: TextStyle(color: Colors.grey[600]),
        ),
      ));
    }
    
    return tags;
  }

  List<Widget> _buildImprovementAreas() {
    final areas = <Widget>[];
    final sessionType = _getSessionTypeKey();
    final speakingMetrics = analysisResult.metrics.speakingMetrics;
    final emotionMetrics = analysisResult.metrics.emotionMetrics;
    
    // 말하기 속도 개선
    if (speakingMetrics.speechRate < 100 || speakingMetrics.speechRate > 180) {
      areas.add(_buildImprovementCard(
        '말하기 속도 조절',
        speakingMetrics.speechRate < 100 
          ? '말하기 속도가 다소 느립니다. 더 활기차게 대화해보세요.'
          : '말하기 속도가 다소 빠릅니다. 천천히 또박또박 말해보세요.',
      ));
      areas.add(SizedBox(height: 15));
    }
    
    // 세션 타입별 개선사항
    switch (sessionType) {
      case 'presentation':
        if (emotionMetrics.averageInterest < 70) {
          areas.add(_buildImprovementCard(
            '발표 자신감 향상',
            '더 확신 있는 톤으로 발표해보세요. 핵심 메시지를 강조할 때는 목소리 톤을 높이고, 중요 포인트에서 잠시 멈춤을 활용하면 효과적입니다.',
          ));
          areas.add(SizedBox(height: 15));
        }
        break;
        
      case 'interview':
        if (emotionMetrics.averageLikeability < 70) {
          areas.add(_buildImprovementCard(
            '자신감 향상',
            '답변할 때 더 확신을 가지고 말해보세요. 구체적인 경험과 성과를 수치와 함께 제시하면 설득력이 높아집니다.',
          ));
          areas.add(SizedBox(height: 15));
        }
        break;
        
      case 'dating':
        if (analysisResult.metrics.conversationMetrics.listeningScore < 70) {
          areas.add(_buildImprovementCard(
            '경청 시간 늘리기',
            '상대방의 이야기를 충분히 듣고 반응할 시간을 더 가져보세요. 공감과 질문으로 대화를 이어나가는 것이 좋습니다.',
          ));
          areas.add(SizedBox(height: 15));
        }
        break;
    }
    
    // 기본 개선사항 (아무것도 없으면)
    if (areas.isEmpty) {
      areas.add(_buildImprovementCard(
        '전반적인 향상',
        '전반적으로 좋은 성과를 보였습니다. 지속적인 연습을 통해 더욱 자연스러운 소통 능력을 키워보세요.',
      ));
    }
    
    return areas;
  }

  Widget _buildImprovementCard(String title, String description) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xFFF5F5F5),
        border: Border(
          left: BorderSide(color: AppColors.primary, width: 4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
            ),
          ),
          SizedBox(height: 10),
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

// 감정 변화 그래프를 그리기 위한 CustomPainter
class EmotionGraphPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    // 배경 그리드 그리기
    final gridPaint = Paint()
      ..color = Color(0xFFE0E0E0)
      ..strokeWidth = 1;

    // 수평선
    for (int i = 1; i < 4; i++) {
      final y = height * i / 4;
      canvas.drawLine(Offset(0, y), Offset(width, y), gridPaint);
    }

    // 감정 변화 패스 그리기
    final path = Path();

    // 샘플 데이터 포인트 (실제로는 emotionData에서 가져와야 함)
    final dataPoints = [
      Offset(0, height * 0.6),
      Offset(width * 0.1, height * 0.55),
      Offset(width * 0.2, height * 0.5),
      Offset(width * 0.3, height * 0.4), // 호감도 상승
      Offset(width * 0.4, height * 0.25), // 호감도 최고점
      Offset(width * 0.5, height * 0.3),
      Offset(width * 0.6, height * 0.5), // 관심도 감소
      Offset(width * 0.7, height * 0.45),
      Offset(width * 0.8, height * 0.35), // 호감도 회복
      Offset(width * 0.9, height * 0.4),
      Offset(width, height * 0.35),
    ];

    // 경로 그리기
    path.moveTo(dataPoints[0].dx, dataPoints[0].dy);
    for (int i = 1; i < dataPoints.length; i++) {
      // 부드러운 곡선을 만들기 위해 quadraticBezierTo 사용
      final ctrl = Offset(
        (dataPoints[i - 1].dx + dataPoints[i].dx) / 2,
        dataPoints[i - 1].dy,
      );
      path.quadraticBezierTo(
        ctrl.dx,
        ctrl.dy,
        dataPoints[i].dx,
        dataPoints[i].dy,
      );
    }

    // 선 그리기
    final linePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawPath(path, linePaint);

    // 특정 포인트를 강조하기 위한 원 그리기
    final pointPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    // 주요 변화 포인트 강조
    canvas.drawCircle(dataPoints[3], 5, pointPaint); // 호감도 상승
    canvas.drawCircle(dataPoints[4], 5, pointPaint); // 호감도 최고점

    final negativePaint = Paint()
      ..color = Color(0xFFE57373)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(dataPoints[6], 5, negativePaint); // 관심도 감소
    canvas.drawCircle(dataPoints[8], 5, pointPaint); // 호감도 회복
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

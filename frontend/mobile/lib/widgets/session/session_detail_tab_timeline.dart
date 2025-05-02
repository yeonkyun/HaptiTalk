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
                          '대화 요약',
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
                      '이번 소개팅에서는 여행, 취미, 음식과 같은 다양한 주제로 대화가 진행되었습니다. 특히 제주도 여행 경험에 대한 이야기에서 호감도가 가장 높게 측정되었고, 상대방도 여행 취미를 공유하고 있어 자연스러운 대화 흐름을 이어갔습니다. 명확한 발음과 적절한 말하기 속도로 소통했으며, 경청 태도도 좋았습니다.',
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
                '감정 변화 타임라인',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 호감도 그래프 컨테이너
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
                          Icons.favorite_outline,
                          size: 20,
                          color: Color(0xFF212121),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '호감도 변화',
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
                          '감정 변화 포인트',
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
                            children: [
                              _buildChangePointItem(
                                '00:16:32',
                                '호감도 상승',
                                '여행 취미에 대해 이야기하면서 공통 관심사를 발견했습니다.',
                                true,
                              ),
                              SizedBox(height: 15),
                              _buildChangePointItem(
                                '00:42:15',
                                '호감도 최고점',
                                '제주도 여행 경험을 공유하면서 대화가 가장 활발해졌습니다.',
                                true,
                              ),
                              SizedBox(height: 15),
                              _buildChangePointItem(
                                '01:05:48',
                                '관심도 감소',
                                '음악 취향에 대해 너무 길게 설명하면서 상대방의 관심도가 감소했습니다.',
                                false,
                              ),
                              SizedBox(height: 15),
                              _buildChangePointItem(
                                '01:18:24',
                                '호감도 회복',
                                '상대방의 관심사에 다시 집중하면서 대화가 자연스럽게 흘러갔습니다.',
                                true,
                              ),
                            ],
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
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '대화 키워드',
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

                    // 키워드 태그 클라우드
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildKeywordTag('여행', 12, isHighlight: true),
                        _buildKeywordTag('제주도', 8, isHighlight: true),
                        _buildKeywordTag('사진', 7, isHighlight: true),
                        _buildKeywordTag('카페', 6),
                        _buildKeywordTag('영화', 5),
                        _buildKeywordTag('음식', 5),
                        _buildKeywordTag('음악', 4),
                        _buildKeywordTag('취미', 4),
                        _buildKeywordTag('여름', 3),
                        _buildKeywordTag('바다', 3),
                        _buildKeywordTag('경험', 3),
                        _buildKeywordTag('추억', 2),
                      ],
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

              // 경청 시간 개선
              Container(
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
                      '경청 시간 늘리기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '상대방의 이야기를 충분히 듣고 반응할 시간을 더 가져보세요. 가끔 상대의 말이 끝나기 전에 대답하는 경향이 있었습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              // 자기 주도 대화 조절
              Container(
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
                      '자기 주도 대화 조절하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '대화 전체에서 자신의 이야기 비중이 약 60%로, 상대방에게 말할 기회를 더 주는 것이 좋습니다. 상대방에게 더 많은 질문을 해보세요.',
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

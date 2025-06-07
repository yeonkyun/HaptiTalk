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
    final speakingMetrics = analysisResult.metrics.speakingMetrics;

    return ListView(
      padding: EdgeInsets.all(0),
      children: [
        // 상단 지표 카드들 (2x2 그리드)
        Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Row(
            children: [
              // 왼쪽 열
              Expanded(
                child: Column(
                  children: [
                    // 말하기 속도 카드
                    _buildMetricCard(
                      title: '말하기 속도',
                      value: '${speakingMetrics.speechRate.toInt()}WPM',
                      percentage:
                          speakingMetrics.speechRate / 120, // 최대 속도를 120으로 가정
                      description: '적절한 속도 (평균 80-120WPM)',
                    ),
                    SizedBox(height: 15),
                    // 명확성 카드
                    _buildMetricCard(
                      title: '명확성',
                      value: '${speakingMetrics.clarity.toInt()}%',
                      percentage: speakingMetrics.clarity / 100,
                      description: '매우 명확한 발음과 전달력',
                    ),
                  ],
                ),
              ),
              SizedBox(width: 15),
              // 오른쪽 열
              Expanded(
                child: Column(
                  children: [
                    // 목소리 톤 카드
                    _buildMetricCard(
                      title: '목소리 톤',
                      value: '${speakingMetrics.tonality.toInt()}%',
                      percentage: speakingMetrics.tonality / 100,
                      description: '자연스러운 억양과 톤 변화',
                    ),
                    SizedBox(height: 15),
                    // 대화 기여도 카드
                    _buildMetricCard(
                      title: '대화 기여도',
                      value:
                          '${analysisResult.metrics.conversationMetrics.contributionRatio.toInt()}%',
                      percentage: analysisResult
                              .metrics.conversationMetrics.contributionRatio /
                          100,
                      description: '약간 더 많은 대화 참여',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 말하기 속도 변화 차트
        Padding(
          padding: EdgeInsets.all(20),
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 제목 영역
                Row(
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 20,
                      color: Color(0xFF212121),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '말하기 속도 변화',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // 막대 그래프
                Container(
                  height: 60,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(
                      14, // 14개의 막대
                      (index) {
                        // 임의의 높이 생성 (실제로는 데이터에 따라 결정)
                        final heights = [
                          30,
                          36,
                          45,
                          51,
                          48,
                          42,
                          39,
                          45,
                          48,
                          54,
                          51,
                          42,
                          36,
                          33
                        ];
                        return Container(
                          width: 18,
                          height: heights[index].toDouble(),
                          color: AppColors.primary,
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(height: 15),

                // 시작/종료 라벨
                Row(
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
              ],
            ),
          ),
        ),

        // 습관적인 패턴 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                '습관적인 패턴',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 습관어 반복 카드
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목과 횟수
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 제목
                        Row(
                          children: [
                            Icon(
                              Icons.repeat,
                              size: 20,
                              color: Color(0xFF212121),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '습관어 반복',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF212121),
                              ),
                            ),
                          ],
                        ),
                        // 횟수
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '12회',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    // 설명
                    Text(
                      '대화 중 일부 단어나 구문을 반복적으로 사용하는 패턴이 감지되었습니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                      ),
                    ),
                    SizedBox(height: 10),

                    // 습관어 목록
                    Container(
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHabitListItem('음... 그러니까', 5),
                          SizedBox(height: 5),
                          _buildHabitListItem('확실히', 4),
                          SizedBox(height: 5),
                          _buildHabitListItem('아무래도', 3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              // 말 끊기 카드
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 제목과 횟수
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // 제목
                        Row(
                          children: [
                            Icon(
                              Icons.content_cut,
                              size: 20,
                              color: Color(0xFF212121),
                            ),
                            SizedBox(width: 8),
                            Text(
                              '말 끊기',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF212121),
                              ),
                            ),
                          ],
                        ),
                        // 횟수
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            '3회',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),

                    // 설명
                    Text(
                      '상대방의 말이 완전히 끝나기 전에 말을 시작한 경우가 있습니다.',
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

        // 대화 흐름 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                '대화 흐름',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 대화 기여도 시각화
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        // 대화 기여도 막대
                        Container(
                          margin: EdgeInsets.only(top: 36),
                          child: Row(
                            children: [
                              // 내 기여도 (60%)
                              Container(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                width:
                                    MediaQuery.of(context).size.width * 0.60 -
                                        70, // 60% 비율 (패딩 감안)
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(left: 10),
                                  child: Text(
                                    '나 (60%)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              // 상대방 기여도 (40%)
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF4081),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.only(left: 10),
                                    child: Text(
                                      '상대방 (40%)',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              // 대화 흐름 설명
              Text(
                '전체 대화에서 내가 60%, 상대방이 40%의 비율로 대화를 이끌었습니다. 질문과 답변의 교환이 자연스럽게 이루어졌으며, 적절한 답변 시간을 유지했습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF616161),
                ),
              ),
            ],
          ),
        ),

        // 개선 팁 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목
              Text(
                '개선 팁',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 습관어 줄이기 팁
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(0),
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '습관어 줄이기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '"음... 그러니까", "확실히"와 같은 습관어 사용을 줄이면 더 명확하고 자신감 있는 대화가 가능합니다. 말하기 전에 잠시 생각하는 시간을 가져보세요.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              // 상대방 말 경청하기 팁
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(0),
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '상대방의 말 경청하기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '상대방의 말이 완전히 끝난 후 1-2초 기다린 다음 응답하면 더 깊은 경청을 보여줄 수 있습니다. 이는 상대방에게 존중받는 느낌을 줍니다.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 15),

              // 대화 균형 맞추기 팁
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(0),
                  border: Border(
                    left: BorderSide(color: AppColors.primary, width: 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '대화 균형 맞추기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF212121),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      '상대방에게 더 많은 질문을 해서 대화 기여도의 균형을 50:50에 가깝게 맞추면 더 효과적인 소통이 가능합니다.',
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

  // 메트릭 카드 위젯
  Widget _buildMetricCard({
    required String title,
    required String value,
    required double percentage,
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
          // 제목
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
          SizedBox(height: 10),

          // 값
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: 5),

          // 프로그레스 바
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              widthFactor: percentage.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
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

  // 습관어 목록 아이템
  Widget _buildHabitListItem(String text, int count) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '•',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 10),
        Text(
          '"$text"($count회)',
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF424242),
          ),
        ),
      ],
    );
  }
}

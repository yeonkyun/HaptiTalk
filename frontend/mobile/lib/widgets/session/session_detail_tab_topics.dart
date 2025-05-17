import 'package:flutter/material.dart';
import '../../models/analysis/analysis_result.dart';
import '../../models/analysis/metrics.dart';
import '../../constants/colors.dart';

class SessionDetailTabTopics extends StatelessWidget {
  final AnalysisResult analysisResult;

  const SessionDetailTabTopics({
    Key? key,
    required this.analysisResult,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final topicMetrics = analysisResult.metrics.topicMetrics;

    return ListView(
      padding: EdgeInsets.all(0),
      children: [
        // 주요 대화 주제 섹션
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '주요 대화 주제',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 주제 태그 컨테이너
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  _buildTopicTag('여행', true),
                  _buildTopicTag('사진', true),
                  _buildTopicTag('제주도', false),
                  _buildTopicTag('음식', false),
                  _buildTopicTag('영화', false),
                  _buildTopicTag('취미', false),
                  _buildTopicTag('카페', false, isGrey: true),
                  _buildTopicTag('음악', false, isGrey: true),
                  _buildTopicTag('운동', false, isGrey: true),
                  _buildTopicTag('책', false, isGrey: true),
                ],
              ),
            ],
          ),
        ),

        // 대화 주제 분포 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '대화 주제 분포',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 파이 차트 컨테이너
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    // 원형 차트 (임시로 Container로 표현)
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                      child: Stack(
                        children: [
                          // 실제 구현시 PieChart 위젯 사용
                        ],
                      ),
                    ),
                    SizedBox(width: 20),

                    // 범례
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLegendItem('여행 & 사진 (35%)', AppColors.primary),
                          SizedBox(height: 8),
                          _buildLegendItem('음식 & 카페 (20%)', Color(0xFF7986CB)),
                          SizedBox(height: 8),
                          _buildLegendItem('영화 & 음악 (20%)', Color(0xFFC5CAE9)),
                          SizedBox(height: 8),
                          _buildLegendItem('기타 주제 (25%)', Color(0xFFE8EAF6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 대화 주제 흐름 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '대화 주제 흐름',
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
                    // 제목
                    Row(
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 20,
                          color: Color(0xFF212121),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '주제 타임라인',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),

                    // 타임라인 아이템들
                    Container(
                      height: 570, // 고정 높이
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

                          // 타임라인 내용
                          Column(
                            children: [
                              _buildTimelineItem(
                                '00:05:24',
                                '인사 및 첫 만남에 대한 가벼운 대화로 시작했습니다.',
                                [],
                              ),
                              SizedBox(height: 15),
                              _buildTimelineItem(
                                '00:15:38',
                                '여행과 사진 취미에 대한 이야기로 전환했습니다. 상대방도 여행에 관심이 많다는 공통점을 발견했습니다.',
                                ['여행', '사진'],
                              ),
                              SizedBox(height: 15),
                              _buildTimelineItem(
                                '00:38:52',
                                '제주도 여행 경험에 대해 이야기를 나누었습니다. 이 주제에서 호감도가 가장 높게 측정되었습니다.',
                                ['제주도'],
                              ),
                              SizedBox(height: 15),
                              _buildTimelineItem(
                                '00:52:15',
                                '좋아하는 음식과 카페에 대한 대화로 이어졌습니다.',
                                ['음식', '카페'],
                              ),
                              SizedBox(height: 15),
                              _buildTimelineItem(
                                '01:15:30',
                                '영화와 음악 취향에 대해 이야기했지만, 다소 길게 답변하면서 대화의 균형이 약간 깨졌습니다.',
                                ['영화', '음악'],
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

        // 주제별 인사이트 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '주제별 인사이트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 여행 & 사진 인사이트
              _buildInsightCard(
                '여행 & 사진',
                '여행과 사진에 관한 대화에서 상대방의 관심도와 호감도가 가장 높았습니다. 특히 제주도 여행 경험을 공유할 때 상호작용이 활발했습니다. 이 주제는 앞으로의 대화에서도 발전시킬 수 있는 좋은 공통 관심사입니다.',
              ),
              SizedBox(height: 15),

              // 음식 & 카페 인사이트
              _buildInsightCard(
                '음식 & 카페',
                '음식과 카페에 관한 대화는 자연스럽게 여행 주제에서 이어졌습니다. 상대방이 특히 카페 탐방에 관심이 있어 보였으며, 다음 만남을 위한 장소 제안으로 활용할 수 있는 주제입니다.',
              ),
              SizedBox(height: 15),

              // 영화 & 음악 인사이트
              _buildInsightCard(
                '영화 & 음악',
                '영화와 음악 취향에 대한 대화에서는 상대방의 반응이 다소 중립적이었습니다. 이 주제에 대해 더 구체적인 질문을 통해 공통점을 찾는 것이 도움이 될 수 있습니다.',
              ),
            ],
          ),
        ),

        // 다음 대화 추천 주제 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '다음 대화 추천 주제',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 여행 계획 추천
              _buildRecommendationCard(
                '여행 계획',
                '"다음에 가보고 싶은 여행지가 있으신가요?" 또는 "함께 가보면 좋을만한 국내 여행지 추천해주실 수 있을까요?"와 같은 질문으로 여행 대화를 이어갈 수 있습니다.',
              ),
              SizedBox(height: 15),

              // 카페 탐방 추천
              _buildRecommendationCard(
                '카페 탐방',
                '"특별히 좋아하시는 카페 스타일이 있으신가요?" 또는 "다음에 같이 가보면 좋을 만한 카페를 알고 계신가요?"와 같은 질문으로 다음 만남을 자연스럽게 제안할 수 있습니다.',
              ),
              SizedBox(height: 15),

              // 취미 활동 추천
              _buildRecommendationCard(
                '취미 활동',
                '"사진 말고도 다른 취미활동이 있으신가요?" 또는 "함께 해보고 싶은 취미나 활동이 있으신가요?"와 같은 질문으로 대화를 확장할 수 있습니다.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 주제 태그 위젯
  Widget _buildTopicTag(String text, bool isPrimary, {bool isGrey = false}) {
    final Color bgColor = isGrey
        ? Color(0xFF9E9E9E).withOpacity(0.1)
        : isPrimary
            ? AppColors.primary.withOpacity(0.25)
            : AppColors.primary.withOpacity(0.1);
    final Color textColor = isGrey ? Color(0xFF757575) : AppColors.primary;
    final double fontSize = isGrey ? 13 : (isPrimary ? 16 : 14);
    final FontWeight fontWeight = isGrey
        ? FontWeight.normal
        : isPrimary
            ? FontWeight.w600
            : FontWeight.normal;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 15,
        vertical: isPrimary ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
        ),
      ),
    );
  }

  // 파이차트 범례 아이템
  Widget _buildLegendItem(String text, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: Color(0xFF424242),
          ),
        ),
      ],
    );
  }

  // 타임라인 아이템
  Widget _buildTimelineItem(
      String time, String description, List<String> topics) {
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
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),

        // 타임라인 내용
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
                  color: AppColors.primary,
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

              // 주제 태그들
              if (topics.isNotEmpty) ...[
                SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  children: topics
                      .map((topic) => Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              topic,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // 인사이트 카드
  Widget _buildInsightCard(String title, String description) {
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

  // 추천 주제 카드
  Widget _buildRecommendationCard(String title, String description) {
    return Container(
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
                Icons.lightbulb_outline,
                size: 20,
                color: Color(0xFF212121),
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

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
        // 주제 분포 섹션
        Padding(
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getSessionTypeName()} 주제 분포',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 주제 분포 차트
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
                          Icons.pie_chart,
                          size: 20,
                          color: Color(0xFF212121),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '주제별 대화 비중',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),

                    // 주제 막대 차트 (실제 데이터 기반)
                    ...topicMetrics.topics.take(6).map((topic) => 
                      _buildTopicBar(topic, context)
                    ).toList(),
                    
                    if (topicMetrics.topics.isEmpty)
                      Container(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text(
                            '주제 분석 데이터가 충분하지 않습니다.',
                            style: TextStyle(
                              color: Color(0xFF616161),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 핵심 대화 포인트 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '핵심 대화 포인트',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 핵심 포인트 카드들 (실제 데이터 기반)
              ..._buildKeyPointCards(),
            ],
          ),
        ),

        // 대화 전개 패턴 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '대화 전개 패턴',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 대화 흐름 분석 카드
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
                          Icons.timeline,
                          size: 20,
                          color: Color(0xFF212121),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${_getSessionTypeName()} 흐름 분석',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF212121),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),

                    // 대화 흐름 분석 내용 (세션별 맞춤)
                    Text(
                      _getConversationFlowAnalysis(),
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF616161),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 주제별 인사이트 섹션
        if (topicMetrics.insights.isNotEmpty)
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

                // 인사이트 카드들 (실제 데이터 기반)
                ...topicMetrics.insights.take(3).map((insight) => Column(
                  children: [
                    _buildInsightCard(insight),
                    SizedBox(height: 15),
                  ],
                )).toList(),
              ],
            ),
          ),

        // 추천 주제 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getSessionTypeName()} 추천 주제',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 추천 주제 카드
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: Colors.blue[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          '다음에 시도해볼 주제',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),

                    // 추천 주제 목록 (세션별 맞춤)
                    ..._buildRecommendedTopics(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 세션 타입 키 정규화
  String _getSessionTypeKey() {
    final category = analysisResult.category.toLowerCase();
    if (category.contains('발표') || category == 'presentation') return 'presentation';
    if (category.contains('면접') || category == 'interview') return 'interview';
    if (category.contains('소개팅') || category == 'dating') return 'dating';
    return 'presentation'; // 기본값
  }

  // 세션 타입 표시명
  String _getSessionTypeName() {
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return '발표';
      case 'interview':
        return '면접';
      case 'dating':
        return '소개팅';
      default:
        return '세션';
    }
  }

  // 주제 막대 차트 위젯
  Widget _buildTopicBar(ConversationTopic topic, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width - 80; // 패딩 고려
    final barWidth = screenWidth * (topic.percentage / 100);
    
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  topic.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF424242),
                  ),
                ),
              ),
              Text(
                '${topic.percentage.toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Stack(
            children: [
              Container(
                width: screenWidth,
                height: 8,
                decoration: BoxDecoration(
                  color: Color(0xFFE0E0E0),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                width: barWidth,
                height: 8,
                decoration: BoxDecoration(
                  color: topic.isPrimary ? AppColors.primary : Colors.blue[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 핵심 포인트 카드들 생성
  List<Widget> _buildKeyPointCards() {
    final cards = <Widget>[];
    final sessionType = _getSessionTypeKey();
    final topicMetrics = analysisResult.metrics.topicMetrics;
    
    if (topicMetrics.topics.isNotEmpty) {
      final primaryTopic = topicMetrics.topics.firstWhere(
        (topic) => topic.isPrimary,
        orElse: () => topicMetrics.topics.first,
      );
      
      cards.add(_buildKeyPointCard(
        '주요 대화 주제',
        Icons.star,
        _getMainTopicAnalysis(primaryTopic),
        AppColors.primary,
      ));
      cards.add(SizedBox(height: 15));
    }

    // 세션별 특화 분석
    switch (sessionType) {
      case 'presentation':
        cards.add(_buildKeyPointCard(
          '청중 반응 포인트',
          Icons.groups,
          _getPresentationAudienceAnalysis(),
          Colors.blue,
        ));
        cards.add(SizedBox(height: 15));
        cards.add(_buildKeyPointCard(
          '전달 효과성',
          Icons.campaign,
          _getPresentationEffectivenessAnalysis(),
          Colors.green,
        ));
        break;
        
      case 'interview':
        cards.add(_buildKeyPointCard(
          '답변 강점',
          Icons.thumb_up,
          _getInterviewStrengthAnalysis(),
          Colors.green,
        ));
        cards.add(SizedBox(height: 15));
        cards.add(_buildKeyPointCard(
          '전문성 어필',
          Icons.work,
          _getInterviewExpertiseAnalysis(),
          Colors.purple,
        ));
        break;
        
      case 'dating':
        cards.add(_buildKeyPointCard(
          '공감대 형성',
          Icons.favorite,
          _getDatingRapportAnalysis(),
          Colors.pink,
        ));
        cards.add(SizedBox(height: 15));
        cards.add(_buildKeyPointCard(
          '관심사 교집합',
          Icons.favorite_border,
          _getDatingInterestAnalysis(),
          Colors.orange,
        ));
        break;
    }
    
    return cards;
  }

  // 대화 흐름 분석 생성
  String _getConversationFlowAnalysis() {
    final sessionType = _getSessionTypeKey();
    final duration = (analysisResult.metrics.totalDuration / 60).round();
    final contribution = analysisResult.metrics.conversationMetrics.contributionRatio;
    
    switch (sessionType) {
      case 'presentation':
        return '${duration}분간의 발표에서 체계적인 구조로 정보를 전달했습니다. '
               '청중과의 상호작용을 ${contribution > 80 ? '적절히' : '더 많이'} 유도하며, '
               '핵심 메시지에 집중한 전개가 효과적이었습니다. '
               '질의응답 시간에도 명확한 답변으로 전문성을 보여주었습니다.';
               
      case 'interview':
        return '${duration}분간의 면접에서 논리적이고 체계적인 답변을 제공했습니다. '
               '질문에 대한 이해도가 높았으며, STAR 기법을 활용한 구체적인 경험 공유가 인상적이었습니다. '
               '${contribution > 60 ? '적극적인' : '안정적인'} 답변 태도로 전문성과 열정을 어필했습니다.';
               
      case 'dating':
        return '${duration}분간의 대화에서 자연스러운 주제 전환과 상호 관심사 발견이 이루어졌습니다. '
               '${contribution > 60 ? '다소 주도적이지만' : '균형잡힌'} 대화 참여로 편안한 분위기를 조성했으며, '
               '상대방의 이야기에 적절히 반응하여 좋은 라포를 형성했습니다.';
               
      default:
        return '${duration}분간의 세션에서 체계적이고 자연스러운 대화 흐름을 유지했습니다.';
    }
  }

  // 주요 주제 분석
  String _getMainTopicAnalysis(ConversationTopic topic) {
    final sessionType = _getSessionTypeKey();
    switch (sessionType) {
      case 'presentation':
        return '"${topic.name}" 주제가 전체 발표의 ${topic.percentage.toInt()}%를 차지했습니다. '
               '이 주제에서 청중의 관심이 가장 높았으며, 명확한 정보 전달이 이루어졌습니다.';
      case 'interview':
        return '"${topic.name}" 관련 질문이 면접의 ${topic.percentage.toInt()}%를 차지했습니다. '
               '이 영역에서 전문성과 경험을 효과적으로 어필할 수 있었습니다.';
      case 'dating':
        return '"${topic.name}" 대화가 전체의 ${topic.percentage.toInt()}%를 차지했습니다. '
               '이 주제에서 상호 관심사를 발견하며 자연스러운 공감대를 형성했습니다.';
      default:
        return '"${topic.name}" 주제가 대화의 ${topic.percentage.toInt()}%를 차지했습니다.';
    }
  }

  // 세션별 분석 텍스트들
  String _getPresentationAudienceAnalysis() {
    final interest = analysisResult.metrics.emotionMetrics.averageInterest;
    if (interest >= 70) {
      return '청중의 적극적인 참여와 높은 관심도를 유지했습니다. 질문과 상호작용이 활발하게 이루어져 효과적인 소통이 가능했습니다.';
    } else if (interest >= 50) {
      return '청중의 기본적인 관심은 유지했으나, 더 다양한 참여 유도 기법을 활용하면 몰입도를 높일 수 있을 것 같습니다.';
    }
    return '청중의 참여를 더 적극적으로 유도해보세요. 질문이나 간단한 활동으로 관심을 끌어보는 것이 좋겠습니다.';
  }

  String _getPresentationEffectivenessAnalysis() {
    final clarity = analysisResult.metrics.speakingMetrics.clarity;
    if (clarity >= 80) {
      return '핵심 메시지가 명확하게 전달되었습니다. 체계적인 구성과 적절한 예시로 이해도를 높였습니다.';
    } else if (clarity >= 60) {
      return '전반적으로 좋은 전달력을 보였습니다. 일부 복잡한 내용은 더 간단히 설명하면 효과적일 것 같습니다.';
    }
    return '메시지 전달 방식에 개선이 필요합니다. 핵심 포인트를 더 명확히 정리해서 전달해보세요.';
  }

  String _getInterviewStrengthAnalysis() {
    final confidence = analysisResult.metrics.emotionMetrics.averageLikeability;
    if (confidence >= 70) {
      return '자신감 있는 답변과 구체적인 경험 공유로 좋은 인상을 남겼습니다. 논리적 구조와 명확한 표현이 강점입니다.';
    } else if (confidence >= 50) {
      return '기본적인 답변 역량은 갖추었습니다. 더 구체적인 성과와 수치를 포함하면 설득력이 높아질 것 같습니다.';
    }
    return '답변에 더 확신을 가져보세요. 구체적인 사례와 성과를 통해 역량을 어필해보는 것이 좋겠습니다.';
  }

  String _getInterviewExpertiseAnalysis() {
    final contribution = analysisResult.metrics.conversationMetrics.contributionRatio;
    if (contribution >= 60) {
      return '전문 분야에 대한 깊이 있는 지식과 열정을 잘 어필했습니다. 적극적인 답변 태도가 인상적이었습니다.';
    } else if (contribution >= 40) {
      return '전문성은 충분히 전달되었습니다. 더 적극적으로 경험과 역량을 어필해보는 것이 좋겠습니다.';
    }
    return '전문성을 더 자신있게 어필해보세요. 구체적인 프로젝트 경험과 성과를 강조해보는 것이 좋겠습니다.';
  }

  String _getDatingRapportAnalysis() {
    final likeability = analysisResult.metrics.emotionMetrics.averageLikeability;
    if (likeability >= 70) {
      return '상대방과 자연스러운 공감대를 형성했습니다. 진정성 있는 소통과 적절한 유머로 좋은 분위기를 만들었습니다.';
    } else if (likeability >= 50) {
      return '기본적인 호감대는 형성되었습니다. 더 개인적인 경험이나 감정을 공유하면 친밀감을 높일 수 있을 것 같습니다.';
    }
    return '상대방과의 공감대 형성을 위해 더 적극적으로 소통해보세요. 공통 관심사를 찾아 대화를 이어가보는 것이 좋겠습니다.';
  }

  String _getDatingInterestAnalysis() {
    final topics = analysisResult.metrics.topicMetrics.topics;
    final commonTopics = topics.where((topic) => topic.percentage > 10).length;
    
    if (commonTopics >= 3) {
      return '다양한 공통 관심사를 발견했습니다. 여러 주제에서 자연스러운 대화가 이어져 좋은 케미를 보여주었습니다.';
    } else if (commonTopics >= 2) {
      return '몇 가지 공통 관심사를 찾았습니다. 이를 바탕으로 더 깊이 있는 대화를 나누면 관계 발전에 도움이 될 것 같습니다.';
    }
    return '공통 관심사를 더 적극적으로 찾아보세요. 상대방의 취미나 관심사에 대해 질문해보는 것이 좋겠습니다.';
  }

  // 추천 주제 목록 생성
  List<Widget> _buildRecommendedTopics() {
    final sessionType = _getSessionTypeKey();
    final recommendations = <Widget>[];
    
    List<String> topicSuggestions;
    switch (sessionType) {
      case 'presentation':
        topicSuggestions = [
          '청중과의 Q&A 세션',
          '실제 사례 및 케이스 스터디',
          '인터랙티브 워크샵 요소',
          '시각적 자료 활용',
          '핵심 메시지 강화 방법',
        ];
        break;
      case 'interview':
        topicSuggestions = [
          '구체적인 프로젝트 성과',
          '문제 해결 경험 사례',
          '팀워크 및 리더십 경험',
          '업계 트렌드에 대한 견해',
          '장기적인 커리어 목표',
        ];
        break;
      case 'dating':
        topicSuggestions = [
          '여행 경험 및 계획',
          '취미와 관심사',
          '음식과 맛집 이야기',
          '영화, 음악 등 문화 활동',
          '라이프스타일과 가치관',
        ];
        break;
      default:
        topicSuggestions = [
          '개인적인 경험 공유',
          '관심사와 취미',
          '미래 계획과 목표',
          '일상 이야기',
        ];
    }

    for (int i = 0; i < topicSuggestions.length; i++) {
      recommendations.add(
        Container(
          margin: EdgeInsets.only(bottom: i == topicSuggestions.length - 1 ? 0 : 8),
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.blue[400],
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  topicSuggestions[i],
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF424242),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return recommendations;
  }

  // 핵심 포인트 카드 위젯
  Widget _buildKeyPointCard(String title, IconData icon, String content, Color color) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
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
            content,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF616161),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // 인사이트 카드 위젯
  Widget _buildInsightCard(TopicInsight insight) {
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
                Icons.lightbulb,
                size: 20,
                color: Colors.amber[600],
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  insight.topic,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF212121),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            insight.insight,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF616161),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

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
                      percentage: _getSpeechRatePercentage(speakingMetrics.speechRate),
                      description: _getSpeechRateDescription(speakingMetrics.speechRate),
                    ),
                    SizedBox(height: 15),
                    // 세션별 특화 지표 1
                    _buildMetricCard(
                      title: _getSpecializedMetric1Name(),
                      value: '${_getSpecializedMetric1Value().toInt()}%',
                      percentage: _getSpecializedMetric1Value() / 100,
                      description: _getSpecializedMetric1Description(),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 15),
              // 오른쪽 열
              Expanded(
                child: Column(
                  children: [
                    // 세션별 특화 지표 2
                    _buildMetricCard(
                      title: _getSpecializedMetric2Name(),
                      value: '${_getSpecializedMetric2Value().toInt()}%',
                      percentage: _getSpecializedMetric2Value() / 100,
                      description: _getSpecializedMetric2Description(),
                    ),
                    SizedBox(height: 15),
                    // 대화 기여도 카드
                    _buildMetricCard(
                      title: _getContributionMetricName(),
                      value: '${analysisResult.metrics.conversationMetrics.contributionRatio.toInt()}%',
                      percentage: analysisResult.metrics.conversationMetrics.contributionRatio / 100,
                      description: _getContributionDescription(),
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

                // 막대 그래프 (실제 데이터 기반)
                Container(
                  height: 60,
                  child: _buildSpeechRateChart(),
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
                '${_getSessionTypeName()} 말하기 패턴',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 습관어 반복 카드 (실제 데이터 기반)
              _buildHabitualPatternsCard(),
            ],
          ),
        ),

        // 세션별 특화 분석 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_getSessionTypeName()} 특화 분석',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 세션별 특화 분석 카드들
              ..._buildSpecializedAnalysisCards(),
            ],
          ),
        ),

        // 개선 제안 섹션
        Padding(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '말하기 개선 제안',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              SizedBox(height: 15),

              // 개선 제안 카드들 (실제 데이터 기반)
              ..._buildImprovementSuggestions(),
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

  // 말하기 속도 평가
  double _getSpeechRatePercentage(double rate) {
    // 80-120 WPM을 기준으로 평가
    if (rate >= 80 && rate <= 120) return 1.0;
    if (rate >= 60 && rate <= 140) return 0.8;
    if (rate >= 40 && rate <= 160) return 0.6;
    return 0.4;
  }

  String _getSpeechRateDescription(double rate) {
    if (rate >= 80 && rate <= 120) return '적절한 속도 (80-120WPM)';
    if (rate < 80) return '다소 느린 속도';
    return '다소 빠른 속도';
  }

  // 세션별 특화 지표들
  String _getSpecializedMetric1Name() {
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return '명확성';
      case 'interview':
        return '자신감';
      case 'dating':
        return '톤 & 억양';
      default:
        return '명확성';
    }
  }

  double _getSpecializedMetric1Value() {
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return analysisResult.metrics.speakingMetrics.clarity;
      case 'interview':
        return analysisResult.metrics.emotionMetrics.averageLikeability;
      case 'dating':
        return analysisResult.metrics.speakingMetrics.tonality;
      default:
        return analysisResult.metrics.speakingMetrics.clarity;
    }
  }

  String _getSpecializedMetric1Description() {
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return '메시지 전달 명확성';
      case 'interview':
        return '답변 시 자신감 수준';
      case 'dating':
        return '자연스러운 억양 변화';
      default:
        return '전달력 수준';
    }
  }

  String _getSpecializedMetric2Name() {
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return '설득력';
      case 'interview':
        return '안정감';
      case 'dating':
        return '친근감';
      default:
        return '전달력';
    }
  }

  double _getSpecializedMetric2Value() {
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return analysisResult.metrics.emotionMetrics.averageInterest;
      case 'interview':
        return analysisResult.metrics.speakingMetrics.tonality;
      case 'dating':
        return analysisResult.metrics.emotionMetrics.averageInterest;
      default:
        return analysisResult.metrics.speakingMetrics.tonality;
    }
  }

  String _getSpecializedMetric2Description() {
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return '청중 설득 효과성';
      case 'interview':
        return '답변 시 안정적 톤';
      case 'dating':
        return '상대방에게 친근한 인상';
      default:
        return '전반적 전달력';
    }
  }

  String _getContributionMetricName() {
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return '발표 주도도';
      case 'interview':
        return '답변 적극성';
      case 'dating':
        return '대화 기여도';
      default:
        return '참여도';
    }
  }

  String _getContributionDescription() {
    final ratio = analysisResult.metrics.conversationMetrics.contributionRatio;
    switch (_getSessionTypeKey()) {
      case 'presentation':
        return ratio > 80 ? '적절한 발표 주도' : '더 주도적인 발표 필요';
      case 'interview':
        return ratio > 50 ? '적극적인 답변 태도' : '더 적극적인 답변 필요';
      case 'dating':
        if (ratio > 60) return '다소 많은 대화 참여';
        if (ratio < 40) return '더 적극적인 대화 참여 필요';
        return '적절한 대화 균형';
      default:
        return '적절한 참여 수준';
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: speechRates.map((rate) {
        final normalizedHeight = ((rate - minRate) / (maxRate - minRate)) * maxHeight;
        final height = normalizedHeight.clamp(10.0, maxHeight);
        
        return Container(
          width: 18,
          height: height,
          decoration: BoxDecoration(
            color: _getSpeechRateColor(rate),
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }).toList(),
    );
  }

  Color _getSpeechRateColor(double rate) {
    if (rate >= 80 && rate <= 120) return AppColors.primary;
    if (rate >= 60 && rate <= 140) return Colors.orange;
    return Colors.red;
  }

  // 습관적 패턴 카드 생성
  Widget _buildHabitualPatternsCard() {
    final topics = analysisResult.metrics.topicMetrics.topics;
    
    // 주제에서 반복되는 단어들 찾기 (간단한 예시)
    Map<String, int> habitualWords = {};
    for (var topic in topics) {
      final words = topic.name.split(' ');
      for (var word in words) {
        if (word.length > 1) {
          habitualWords[word] = (habitualWords[word] ?? 0) + topic.percentage.round();
        }
      }
    }

    final sortedWords = habitualWords.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedWords.isEmpty) {
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
                Icon(Icons.repeat, size: 20, color: Color(0xFF212121)),
                SizedBox(width: 8),
                Text(
                  '말하기 패턴 분석',
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
              _getPatternAnalysisText(),
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF616161),
              ),
            ),
          ],
        ),
      );
    }

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
              Icon(Icons.repeat, size: 20, color: Color(0xFF212121)),
              SizedBox(width: 8),
              Text(
                '자주 사용한 표현',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          SizedBox(height: 15),
          
          // 습관어 태그들
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedWords.take(8).map((entry) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Text(
                  '${entry.key} (${entry.value}%)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 10),
          Text(
            _getHabitualWordsAnalysis(sortedWords),
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }

  String _getPatternAnalysisText() {
    final sessionType = _getSessionTypeKey();
    switch (sessionType) {
      case 'presentation':
        return '발표 중 일관된 말하기 패턴을 유지했습니다. 핵심 메시지 전달에 집중하여 반복적인 강조가 효과적이었습니다.';
      case 'interview':
        return '면접 답변에서 체계적인 말하기 패턴을 보였습니다. 논리적 구조와 명확한 표현이 돋보였습니다.';
      case 'dating':
        return '자연스러운 대화 패턴을 유지했습니다. 상대방과의 소통에서 편안한 말하기 스타일을 보여주었습니다.';
      default:
        return '안정적인 말하기 패턴을 유지했습니다.';
    }
  }

  String _getHabitualWordsAnalysis(List<MapEntry<String, int>> words) {
    if (words.isEmpty) return '';
    
    final topWord = words.first;
    final sessionType = _getSessionTypeKey();
    
    switch (sessionType) {
      case 'presentation':
        return '"${topWord.key}" 표현을 자주 사용하여 핵심 메시지를 강조했습니다. 일관된 용어 사용이 전달력을 높였습니다.';
      case 'interview':
        return '"${topWord.key}" 키워드를 반복 사용하여 전문성을 어필했습니다. 체계적인 답변 구조가 돋보였습니다.';
      case 'dating':
        return '"${topWord.key}" 관련 대화를 자주 나누며 공통 관심사를 형성했습니다. 자연스러운 대화 흐름이 좋았습니다.';
      default:
        return '일관된 표현 사용으로 메시지 전달이 명확했습니다.';
    }
  }

  // 특화 분석 카드들 생성
  List<Widget> _buildSpecializedAnalysisCards() {
    final sessionType = _getSessionTypeKey();
    final cards = <Widget>[];
    
    switch (sessionType) {
      case 'presentation':
        cards.addAll([
          _buildAnalysisCard(
            '청중 관심 유도',
            Icons.groups,
            _getPresentationEngagementAnalysis(),
            Colors.blue,
          ),
          SizedBox(height: 15),
          _buildAnalysisCard(
            '메시지 전달력',
            Icons.campaign,
            _getPresentationClarityAnalysis(),
            Colors.green,
          ),
        ]);
        break;
        
      case 'interview':
        cards.addAll([
          _buildAnalysisCard(
            '답변 구조화',
            Icons.format_list_numbered,
            _getInterviewStructureAnalysis(),
            Colors.purple,
          ),
          SizedBox(height: 15),
          _buildAnalysisCard(
            '전문성 어필',
            Icons.workspace_premium,
            _getInterviewExpertiseAnalysis(),
            Colors.orange,
          ),
        ]);
        break;
        
      case 'dating':
        cards.addAll([
          _buildAnalysisCard(
            '대화 자연스러움',
            Icons.chat_bubble_outline,
            _getDatingNaturalnessAnalysis(),
            Colors.pink,
          ),
          SizedBox(height: 15),
          _buildAnalysisCard(
            '감정 표현',
            Icons.sentiment_satisfied,
            _getDatingEmotionAnalysis(),
            Colors.teal,
          ),
        ]);
        break;
    }
    
    return cards;
  }

  String _getPresentationEngagementAnalysis() {
    final interest = analysisResult.metrics.emotionMetrics.averageInterest;
    if (interest >= 70) {
      return '청중의 관심을 효과적으로 유도했습니다. 적절한 제스처와 톤 변화로 몰입도를 높였습니다.';
    } else if (interest >= 50) {
      return '청중의 기본적인 관심은 유지했습니다. 더 다양한 표현 기법을 활용하면 도움이 될 것 같습니다.';
    }
    return '청중 참여를 더 적극적으로 유도해보세요. 질문이나 상호작용을 늘려보는 것이 좋겠습니다.';
  }

  String _getPresentationClarityAnalysis() {
    final clarity = analysisResult.metrics.speakingMetrics.clarity;
    if (clarity >= 80) {
      return '메시지가 매우 명확하게 전달되었습니다. 핵심 포인트가 잘 강조되어 이해하기 쉬웠습니다.';
    } else if (clarity >= 60) {
      return '대체로 명확한 전달이었습니다. 일부 복잡한 내용은 더 간단히 설명하면 좋겠습니다.';
    }
    return '메시지 전달에 개선이 필요합니다. 핵심 포인트를 더 명확히 정리해서 전달해보세요.';
  }

  String _getInterviewStructureAnalysis() {
    final contribution = analysisResult.metrics.conversationMetrics.contributionRatio;
    if (contribution >= 60) {
      return '체계적이고 논리적인 답변 구조를 보였습니다. STAR 기법 등을 잘 활용한 것 같습니다.';
    } else if (contribution >= 40) {
      return '기본적인 답변 구조는 갖추었습니다. 더 구체적인 사례와 결과를 포함하면 좋겠습니다.';
    }
    return '답변의 구조화가 필요합니다. 상황-행동-결과 순으로 정리해서 답변해보세요.';
  }

  String _getInterviewExpertiseAnalysis() {
    final confidence = analysisResult.metrics.emotionMetrics.averageLikeability;
    if (confidence >= 70) {
      return '전문 지식과 경험을 효과적으로 어필했습니다. 자신감 있는 태도가 좋은 인상을 주었습니다.';
    } else if (confidence >= 50) {
      return '기본적인 전문성은 전달되었습니다. 구체적인 성과와 수치를 더 포함하면 설득력이 높아질 것 같습니다.';
    }
    return '전문성 어필을 더 강화해보세요. 구체적인 프로젝트 경험과 성과를 강조해보는 것이 좋겠습니다.';
  }

  String _getDatingNaturalnessAnalysis() {
    final speechRate = analysisResult.metrics.speakingMetrics.speechRate;
    if (speechRate >= 80 && speechRate <= 120) {
      return '자연스럽고 편안한 말하기 속도로 대화했습니다. 상대방이 듣기 편했을 것 같습니다.';
    } else if (speechRate < 80) {
      return '차분하고 신중한 말투로 대화했습니다. 때로는 더 활기찬 톤으로 말해보는 것도 좋겠습니다.';
    }
    return '열정적인 말투로 대화했습니다. 때로는 속도를 조절해서 상대방이 따라올 수 있도록 해보세요.';
  }

  String _getDatingEmotionAnalysis() {
    final tonality = analysisResult.metrics.speakingMetrics.tonality;
    if (tonality >= 70) {
      return '풍부한 감정 표현으로 대화에 생동감을 불어넣었습니다. 상대방이 즐거워했을 것 같습니다.';
    } else if (tonality >= 50) {
      return '적절한 감정 표현으로 대화했습니다. 때로는 더 다양한 톤 변화를 시도해보는 것도 좋겠습니다.';
    }
    return '감정 표현을 더 풍부하게 해보세요. 웃음이나 놀라움 등을 자연스럽게 표현하면 대화가 더 생생해집니다.';
  }

  // 개선 제안 카드들 생성
  List<Widget> _buildImprovementSuggestions() {
    final suggestions = <Widget>[];
    final speakingMetrics = analysisResult.metrics.speakingMetrics;
    final sessionType = _getSessionTypeKey();

    // 말하기 속도 개선
    if (speakingMetrics.speechRate < 80 || speakingMetrics.speechRate > 120) {
      suggestions.add(_buildSuggestionCard(
        speakingMetrics.speechRate < 80 ? '말하기 속도 향상' : '말하기 속도 조절',
        speakingMetrics.speechRate < 80 
          ? '더 활기찬 톤으로 말해보세요. 핵심 메시지는 빠르게, 설명은 적당한 속도로 조절하면 좋겠습니다.'
          : '천천히 또박또박 말해보세요. 중요한 내용은 잠시 멈춤을 두어 강조하는 것이 효과적입니다.',
        Icons.speed,
      ));
      suggestions.add(SizedBox(height: 15));
    }

    // 세션별 특화 개선사항
    switch (sessionType) {
      case 'presentation':
        if (analysisResult.metrics.emotionMetrics.averageInterest < 70) {
          suggestions.add(_buildSuggestionCard(
            '청중 참여 증대',
            '질문을 던지거나 간단한 상호작용을 통해 청중의 참여를 유도해보세요. "여러분은 어떻게 생각하시나요?" 같은 질문이 효과적입니다.',
            Icons.groups,
          ));
          suggestions.add(SizedBox(height: 15));
        }
        break;
        
      case 'interview':
        if (analysisResult.metrics.emotionMetrics.averageLikeability < 70) {
          suggestions.add(_buildSuggestionCard(
            '자신감 향상',
            '답변 시 더 확신을 가지고 말해보세요. "확실히", "분명히" 같은 단어를 적절히 사용하면 자신감 있는 인상을 줄 수 있습니다.',
            Icons.psychology,
          ));
          suggestions.add(SizedBox(height: 15));
        }
        break;
        
      case 'dating':
        if (analysisResult.metrics.conversationMetrics.listeningScore < 70) {
          suggestions.add(_buildSuggestionCard(
            '경청 기술 향상',
            '상대방의 말을 끝까지 들어보세요. "정말요?", "그래서요?" 같은 반응으로 관심을 표현하면 대화가 더 자연스러워집니다.',
            Icons.hearing,
          ));
          suggestions.add(SizedBox(height: 15));
        }
        break;
    }

    // 기본 제안 (개선사항이 없으면)
    if (suggestions.isEmpty) {
      suggestions.add(_buildSuggestionCard(
        '지속적인 향상',
        '전반적으로 좋은 말하기 패턴을 보였습니다. 다양한 상황에서 연습을 통해 더욱 자연스러운 소통 능력을 키워보세요.',
        Icons.trending_up,
      ));
    }

    return suggestions;
  }

  Widget _buildAnalysisCard(String title, IconData icon, String content, Color color) {
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard(String title, String content, IconData icon) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: Colors.orange[600]),
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
            ),
          ),
        ],
      ),
    );
  }

  // 메트릭 카드 위젯
  Widget _buildMetricCard({
    required String title,
    required String value,
    required double percentage,
    required String description,
  }) {
    // 색상 결정
    Color color;
    if (percentage >= 0.8) {
      color = Colors.green;
    } else if (percentage >= 0.6) {
      color = AppColors.primary;
    } else if (percentage >= 0.4) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          
          // 진행률 바
          LinearProgressIndicator(
            value: percentage.clamp(0.0, 1.0),
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          SizedBox(height: 8),
          
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }
}

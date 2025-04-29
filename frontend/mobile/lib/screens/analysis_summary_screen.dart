import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hapti_talk/constants/colors.dart';
import 'dart:math' as math;
import 'package:hapti_talk/screens/main_tab.dart'; // MainTab 위젯 import

class AnalysisSummaryScreen extends StatefulWidget {
  final String sessionTitle;
  final String sessionTag;
  final String sessionDate;
  final String sessionDuration;

  const AnalysisSummaryScreen({
    Key? key,
    required this.sessionTitle,
    required this.sessionTag,
    required this.sessionDate,
    required this.sessionDuration,
  }) : super(key: key);

  @override
  State<AnalysisSummaryScreen> createState() => _AnalysisSummaryScreenState();
}

class _AnalysisSummaryScreenState extends State<AnalysisSummaryScreen> {
  // 감정 변화 그래프 데이터 (예시 데이터)
  final List<double> emotionData = [0.6, 0.68, 0.75, 0.9, 0.84, 0.88, 0.7];

  // 시간 인덱스
  final List<String> timePoints = [
    '0:00',
    '0:15',
    '0:30',
    '0:45',
    '1:00',
    '1:15',
    '1:30'
  ];

  // 분석 결과 데이터 (예시 데이터)
  final speakingSpeed = 78;
  final toneQuality = 85;
  final likeability = 88;
  final listeningScore = 92;

  // 대화 비율
  final userSpeakingRatio = 60;
  final otherSpeakingRatio = 40;

  // 핵심 인사이트
  final List<String> insights = [
    "여행과 사진에 관한 이야기를 나눌 때 상대방의 호감도가 가장 높았습니다.",
    "대화 중 상대방의 질문에 대한 응답 시간이 빨라 대화 참여도가 높았습니다.",
    "상대방의 말을 경청하고 관련 질문을 이어가는 패턴이 효과적이었습니다."
  ];

  // 개선 제안
  final List<Map<String, String>> improvements = [
    {
      'title': '말 끊기 줄이기',
      'description': '상대방의 말이 끝날 때까지 기다린 후 대화를 이어가면 더 긍정적인 인상을 줄 수 있습니다.'
    },
    {
      'title': '공감 표현 늘리기',
      'description':
          '"정말요?", "그렇군요" 같은 공감 표현을 더 자주 사용하면 상대방이 더 편안하게 대화할 수 있습니다.'
    },
    {
      'title': '질문 다양화하기',
      'description': '더 다양한 주제로 질문을 확장하면 대화가 더 풍부해지고 상대방의 관심사를 더 잘 파악할 수 있습니다.'
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '분석 결과',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              // 추가 옵션 메뉴
            },
          ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSessionHeader(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _buildEmotionGraph(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _buildMetrics(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _buildInsights(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _buildImprovements(),
            _buildActionButtons(),
            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSessionHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.sessionTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.sessionDate,
                    style: const TextStyle(
                      color: Color(0xFF757575),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.people,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.sessionTag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.access_time, size: 18, color: Color(0xFF757575)),
              const SizedBox(width: 8),
              Text(
                '총 대화 시간: ${widget.sessionDuration}',
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionGraph() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.show_chart, size: 18, color: Color(0xFF212121)),
              const SizedBox(width: 8),
              const Text(
                '감정 변화 그래프',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Color(0xFF212121),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 200,
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // 그리드 라인
                      _buildGridLines(),
                      // 그래프 선과 점만 보여줌
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: _buildGraphLine(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: timePoints
                        .map((time) => Text(
                              time,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF9E9E9E),
                              ),
                            ))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridLines() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Column(
        children: List.generate(
          5,
          (index) => Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Colors.black.withOpacity(0.1),
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraphLine() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomPaint(
        size: Size(double.infinity, 150),
        painter: GraphLinePainter(emotionData),
      ),
    );
  }

  Widget _buildMetrics() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '주요 지표',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard(
                title: '말하기 속도',
                value: '$speakingSpeed/분',
                description: '적절한 속도로 말했습니다',
                icon: Icons.speed,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                title: '톤 & 억양',
                value: '$toneQuality%',
                description: '자연스러운 억양',
                icon: Icons.multitrack_audio,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMetricCard(
                title: '호감도',
                value: '$likeability%',
                description: '매우 우호적인 반응',
                icon: Icons.favorite_border,
              ),
              const SizedBox(width: 16),
              _buildMetricCard(
                title: '경청 지수',
                value: '$listeningScore%',
                description: '우수한 경청 능력',
                icon: Icons.hearing,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSpeakingRatioCard(),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    color: Color(0xFF424242),
                  ),
                ),
                Icon(
                  icon,
                  size: 16,
                  color: const Color(0xFF424242),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: title == '말하기 속도' ? 23 : 24,
                color: AppColors.primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF757575),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakingRatioCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: DonutChartPainter(
                userRatio: userSpeakingRatio,
                otherRatio: otherSpeakingRatio,
                userColor: AppColors.primaryColor,
                otherColor: const Color(0xFFE0E0E0),
              ),
              child: Center(
                child: Text(
                  '$userSpeakingRatio%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 24),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '나',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$userSpeakingRatio%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    color: const Color(0xFFE0E0E0),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '상대방',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$otherSpeakingRatio%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF424242),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '핵심 인사이트',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            insights.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
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
                      insights[index],
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF424242),
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImprovements() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '개선 제안',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 130,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: improvements.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 250,
                  margin: EdgeInsets.only(
                    right: index < improvements.length - 1 ? 16 : 0,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        improvements[index]['title']!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: Text(
                          improvements[index]['description']!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF616161),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 72,
              child: ElevatedButton(
                onPressed: () {
                  // 전체 보고서 보기 기능
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.description, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '전체 보고서',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '보기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SizedBox(
              height: 72,
              child: ElevatedButton(
                onPressed: () {
                  // 내보내기 기능
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF5F5F5),
                  foregroundColor: const Color(0xFF424242),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                ),
                child: const Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.ios_share, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '내보내기',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: BottomNavigationBar(
        onTap: (index) {
          if (index == 0) {
            // 홈 탭으로 이동 (MainTab 위젯으로 직접 이동)
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainTab()),
            );
          } else if (index == 1) {
            // 현재 분석 탭이므로 아무 동작 안함
          }
        },
        currentIndex: 1, // 분석 탭이 활성화
        selectedItemColor: AppColors.primaryColor,
        unselectedItemColor: const Color(0xFFBDBDBD),
        backgroundColor: Colors.white,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '홈',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: '분석',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: '기록',
            activeIcon: SizedBox.shrink(),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '프로필',
            activeIcon: SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// 그래프 라인 그리기를 위한 커스텀 페인터
class GraphLinePainter extends CustomPainter {
  final List<double> points;

  GraphLinePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = AppColors.primaryColor
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final path = Path();

    // 각 포인트의 x 좌표 계산 (균등하게 분포)
    final segmentWidth = size.width / (points.length - 1);

    // 첫 번째 점부터 시작
    path.moveTo(0, size.height - (points[0] * size.height));

    // 나머지 점들을 연결
    for (int i = 1; i < points.length; i++) {
      final x = segmentWidth * i;
      final y = size.height - (points[i] * size.height);
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);

    // 각 포인트에 점 그리기
    for (int i = 0; i < points.length; i++) {
      final x = segmentWidth * i;
      final y = size.height - (points[i] * size.height);
      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// 도넛 차트를 그리기 위한 커스텀 페인터
class DonutChartPainter extends CustomPainter {
  final int userRatio;
  final int otherRatio;
  final Color userColor;
  final Color otherColor;

  DonutChartPainter({
    required this.userRatio,
    required this.otherRatio,
    required this.userColor,
    required this.otherColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.25; // 도넛 두께 (반지름의 25%)

    // 백그라운드 원 (상대방)
    final otherPaint = Paint()
      ..color = otherColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, otherPaint);

    // 사용자 부분 (호)
    final userPaint = Paint()
      ..color = userColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    final userSweepAngle = (userRatio / 100) * 2 * math.pi;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      -math.pi / 2, // 상단 중앙에서 시작
      userSweepAngle,
      false,
      userPaint,
    );

    // 내부 배경 흰색 원 (도넛 모양을 만들기 위함)
    final innerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius - strokeWidth, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

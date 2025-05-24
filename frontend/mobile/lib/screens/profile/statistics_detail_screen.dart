import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class StatisticsDetailScreen extends StatelessWidget {
  const StatisticsDetailScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '나의 통계',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('커뮤니케이션 분석'),
            const SizedBox(height: 20),
            _buildProgressItem('자신감', 0.85, Colors.blue),
            const SizedBox(height: 15),
            _buildProgressItem('명확성', 0.72, Colors.green),
            const SizedBox(height: 15),
            _buildProgressItem('공감성', 0.68, Colors.purple),
            const SizedBox(height: 15),
            _buildProgressItem('경청 능력', 0.91, Colors.orange),
            const SizedBox(height: 30),
            
            _buildSectionTitle('월별 활동'),
            const SizedBox(height: 20),
            _buildMonthlyChart(),
            const SizedBox(height: 30),
            
            _buildSectionTitle('최근 활동'),
            const SizedBox(height: 15),
            _buildRecentActivityList(),
            const SizedBox(height: 30),
            
            _buildSectionTitle('호감도 분포'),
            const SizedBox(height: 15),
            _buildSentimentDistribution(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildProgressItem(String title, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '${(value * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 10,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value,
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMonthlyChart() {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '최근 6개월 대화 시간 (시간)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _buildBarItem('12월', 3.5, AppColors.primaryColor),
                _buildBarItem('1월', 4.2, AppColors.primaryColor),
                _buildBarItem('2월', 2.8, AppColors.primaryColor),
                _buildBarItem('3월', 5.5, AppColors.primaryColor),
                _buildBarItem('4월', 4.0, AppColors.primaryColor),
                _buildBarItem('5월', 6.5, AppColors.primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarItem(String month, double hours, Color color) {
    final maxHeight = 120.0;
    final height = (hours / 8.0) * maxHeight; // 8시간을 최대로 가정
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 30,
          height: height,
          decoration: BoxDecoration(
            color: color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          month,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    final items = [
      {
        'title': '면접 시뮬레이션',
        'date': '5월 20일',
        'duration': '12분 35초',
        'sentiment': 0.91,
      },
      {
        'title': '발표 연습',
        'date': '5월 15일',
        'duration': '8분 42초',
        'sentiment': 0.85,
      },
      {
        'title': '친구와 대화',
        'date': '5월 10일',
        'duration': '15분 18초',
        'sentiment': 0.78,
      },
    ];
    
    return Column(
      children: items.map((item) => _buildActivityItem(item)).toList(),
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.lightGrayColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.mic,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'],
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${item['date']} • ${item['duration']}',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getSentimentColor(item['sentiment']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${(item['sentiment'] * 100).toInt()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _getSentimentColor(item['sentiment']),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSentimentColor(double sentiment) {
    if (sentiment >= 0.8) return Colors.green;
    if (sentiment >= 0.6) return Colors.blue;
    if (sentiment >= 0.4) return Colors.orange;
    return Colors.red;
  }

  Widget _buildSentimentDistribution() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSentimentItem(
                  label: '매우 긍정',
                  percentage: 45,
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildSentimentItem(
                  label: '긍정',
                  percentage: 30,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: _buildSentimentItem(
                  label: '중립',
                  percentage: 15,
                  color: Colors.orange,
                ),
              ),
              Expanded(
                child: _buildSentimentItem(
                  label: '부정',
                  percentage: 10,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSentimentItem({
    required String label,
    required int percentage,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
            Text(
              '$percentage%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';

class HapticPracticeScreen extends StatefulWidget {
  const HapticPracticeScreen({Key? key}) : super(key: key);

  @override
  State<HapticPracticeScreen> createState() => _HapticPracticeScreenState();
}

class _HapticPracticeScreenState extends State<HapticPracticeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '햅틱 패턴 연습',
          style: TextStyle(
            color: Color(0xFF3F51B5),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black54,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '다양한 햅틱 패턴을 연습해보세요',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 20),

              // 햅틱 패턴 카드들
              _buildHapticPatternCard(
                title: '기본 패턴',
                description: '기본적인 햅틱 피드백 패턴을 연습합니다',
                icon: Icons.touch_app,
              ),
              const SizedBox(height: 15),
              _buildHapticPatternCard(
                title: '복합 패턴',
                description: '여러 진동을 조합한 복합 패턴을 연습합니다',
                icon: Icons.vibration,
              ),
              const SizedBox(height: 15),
              _buildHapticPatternCard(
                title: '커스텀 패턴',
                description: '나만의 햅틱 패턴을 직접 만들어보세요',
                icon: Icons.tune,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHapticPatternCard({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // 각 패턴 연습 시작
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('$title 연습을 시작합니다')),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 36,
                  color: const Color(0xFF3F51B5),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF212121),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF616161),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF9E9E9E),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../constants/colors.dart';
import '../../constants/strings.dart';
import '../../widgets/profile/subscription_plan_card.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 예시 플랜 데이터
    final plans = [
      {
        'title': '무료',
        'price': '₩0',
        'features': ['기본 분석 제공', '세션 기록 제한', '광고 포함'],
        'isCurrent': false,
      },
      {
        'title': '프리미엄',
        'price': '₩4,900/월',
        'features': ['모든 분석 무제한', '세션 기록 무제한', '광고 제거', '우선 지원'],
        'isCurrent': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('구독 플랜'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.primaryColor,
        elevation: 0,
      ),
      backgroundColor: AppColors.lightGrayColor,
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '나에게 맞는 플랜을 선택하세요',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: plans.length,
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemBuilder: (context, idx) {
                  final plan = plans[idx];
                  return SubscriptionPlanCard(
                    title: plan['title'] as String,
                    price: plan['price'] as String,
                    features: List<String>.from(plan['features'] as List),
                    isCurrent: plan['isCurrent'] as bool,
                    onPressed: () {
                      // 결제/업그레이드/다운그레이드 로직
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${plan['title']} 플랜 선택')),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Text(
                '구독 관련 문의: support@haptitalk.com',
                style: TextStyle(
                    fontSize: 13, color: AppColors.secondaryTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

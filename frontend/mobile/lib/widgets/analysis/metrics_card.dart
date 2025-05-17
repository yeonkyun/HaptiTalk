import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class MetricsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final bool isTextValue;
  final double? progressValue;

  const MetricsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.isTextValue = false,
    this.progressValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkCardBackground,
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
                style: TextStyle(
                  color: AppColors.lightText,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              Icon(icon, size: 16, color: AppColors.lightText),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          if (progressValue != null) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class EmotionMetricsCard extends StatelessWidget {
  final String emotionState;
  final IconData icon;

  const EmotionMetricsCard({
    Key? key,
    required this.emotionState,
    this.icon = Icons.sentiment_satisfied_alt,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MetricsCard(
      title: '감정 상태',
      value: emotionState,
      icon: icon,
      isTextValue: true,
    );
  }
}

class SpeedMetricsCard extends StatelessWidget {
  final int speedValue;

  const SpeedMetricsCard({
    Key? key,
    required this.speedValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MetricsCard(
      title: '말하기 속도',
      value: '$speedValue%',
      icon: Icons.speed,
      progressValue: speedValue / 100,
    );
  }
}

class LikabilityMetricsCard extends StatelessWidget {
  final int likabilityValue;

  const LikabilityMetricsCard({
    Key? key,
    required this.likabilityValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MetricsCard(
      title: '호감도',
      value: '$likabilityValue%',
      icon: Icons.favorite,
      progressValue: likabilityValue / 100,
    );
  }
}

class InterestMetricsCard extends StatelessWidget {
  final int interestValue;

  const InterestMetricsCard({
    Key? key,
    required this.interestValue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MetricsCard(
      title: '관심도',
      value: '$interestValue%',
      icon: Icons.star,
      progressValue: interestValue / 100,
    );
  }
}

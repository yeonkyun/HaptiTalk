import 'dart:math' as math;

class AnalyticsUtils {
  // 감정 데이터의 퍼센트 계산
  static double calculatePercentage(int value, int total) {
    if (total == 0) return 0;
    return (value / total) * 100;
  }

  // 긍정 감정 비율 계산
  static double getPositiveEmotionRatio(
    int positive,
    int negative,
    int neutral,
  ) {
    final total = positive + negative + neutral;
    return calculatePercentage(positive, total);
  }

  // 부정 감정 비율 계산
  static double getNegativeEmotionRatio(
    int positive,
    int negative,
    int neutral,
  ) {
    final total = positive + negative + neutral;
    return calculatePercentage(negative, total);
  }

  // 중립 감정 비율 계산
  static double getNeutralEmotionRatio(
    int positive,
    int negative,
    int neutral,
  ) {
    final total = positive + negative + neutral;
    return calculatePercentage(neutral, total);
  }

  // 감정 강도 계산 (0~1 사이 값)
  static double calculateEmotionIntensity(
    double positiveScore,
    double negativeScore,
  ) {
    // 감정 점수의 절대값 사용 (0~1 사이 값이라고 가정)
    return (positiveScore.abs() + negativeScore.abs()) / 2;
  }

  // 감정 변화율 계산 (이전 데이터 대비 현재 데이터의 변화)
  static double calculateEmotionChangeRate(
    double currentValue,
    double previousValue,
  ) {
    if (previousValue == 0) return 0;
    return ((currentValue - previousValue) / previousValue) * 100;
  }

  // 세션 평균 감정 점수 계산
  static double calculateAverageEmotionScore(List<double> scores) {
    if (scores.isEmpty) return 0;
    return scores.reduce((a, b) => a + b) / scores.length;
  }

  // 감정 분포 계산 (감정별 발생 빈도)
  static Map<String, int> calculateEmotionDistribution(List<String> emotions) {
    final Map<String, int> distribution = {};

    for (final emotion in emotions) {
      distribution[emotion] = (distribution[emotion] ?? 0) + 1;
    }

    return distribution;
  }

  // 변화 포인트 감지 (임계값 이상 변화가 발생한 지점)
  static List<int> detectChangePoints(
    List<double> data,
    double threshold,
  ) {
    final List<int> changePoints = [];

    if (data.length < 2) return changePoints;

    for (int i = 1; i < data.length; i++) {
      final double change = (data[i] - data[i - 1]).abs();
      if (change >= threshold) {
        changePoints.add(i);
      }
    }

    return changePoints;
  }

  // 표준 편차 계산 (데이터의 변동성 측정)
  static double calculateStandardDeviation(List<double> values) {
    if (values.isEmpty) return 0;

    final double mean = values.reduce((a, b) => a + b) / values.length;
    final double variance = values
            .map((value) => math.pow(value - mean, 2))
            .reduce((a, b) => a + b) /
        values.length;

    return math.sqrt(variance);
  }
}

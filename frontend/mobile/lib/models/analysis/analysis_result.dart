import 'package:flutter/material.dart';
import 'emotion_data.dart';
import 'metrics.dart';

// 세션 분석 결과 모델
class AnalysisResult {
  final String sessionId; // 세션 ID
  final String title; // 세션 제목
  final DateTime date; // 세션 날짜
  final String category; // 세션 카테고리 (예: '소개팅', '면접', '발표' 등)
  final List<EmotionData> emotionData; // 감정 데이터
  final List<EmotionChangePoint> emotionChangePoints; // 감정 변화 포인트
  final SessionMetrics metrics; // 세션 지표

  AnalysisResult({
    required this.sessionId,
    required this.title,
    required this.date,
    required this.category,
    required this.emotionData,
    required this.emotionChangePoints,
    required this.metrics,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      sessionId: json['sessionId'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      category: json['category'] as String,
      emotionData: (json['emotionData'] as List<dynamic>)
          .map((e) => EmotionData.fromJson(e as Map<String, dynamic>))
          .toList(),
      emotionChangePoints: (json['emotionChangePoints'] as List<dynamic>)
          .map((e) => EmotionChangePoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      metrics: SessionMetrics.fromJson(json['metrics'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'title': title,
      'date': date.toIso8601String(),
      'category': category,
      'emotionData': emotionData.map((e) => e.toJson()).toList(),
      'emotionChangePoints':
          emotionChangePoints.map((e) => e.toJson()).toList(),
      'metrics': metrics.toJson(),
    };
  }

  // 오디오 시간 포맷 (초 -> MM:SS 형식)
  static String formatAudioTime(double seconds) {
    final int mins = (seconds / 60).floor();
    final int secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // 오디오 시간 포맷 (초 -> HH:MM:SS 형식)
  static String formatAudioTimeLong(double seconds) {
    final int hours = (seconds / 3600).floor();
    final int mins = ((seconds % 3600) / 60).floor();
    final int secs = (seconds % 60).floor();
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // 세션 날짜 포맷 (yyyy년 MM월 dd일 a h:mm 형식)
  String getFormattedDate() {
    final List<String> amPm = ['오전', '오후'];
    final String year = date.year.toString();
    final String month = date.month.toString();
    final String day = date.day.toString();
    final String hour =
        (date.hour > 12 ? date.hour - 12 : date.hour).toString();
    final String minute = date.minute.toString().padLeft(2, '0');
    final String period = date.hour < 12 ? amPm[0] : amPm[1];

    return '$year년 $month월 $day일 $period $hour:$minute';
  }

  // 세션 총 시간 포맷
  String getFormattedDuration() {
    final int hours = (metrics.totalDuration / 3600).floor();
    final int mins = ((metrics.totalDuration % 3600) / 60).floor();

    if (hours > 0) {
      return '$hours시간 $mins분';
    } else {
      return '$mins분';
    }
  }
}

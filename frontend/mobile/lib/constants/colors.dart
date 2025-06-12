import 'package:flutter/material.dart';

class AppColors {
  // 앱의 주요 색상
  static const Color primary = Color(0xFF3F51B5); // 주 색상 (파란색 계열)
  static const Color secondary = Color(0xFF90CAF9); // 보조 색상 (청록색 계열)
  static const Color accent = Color(0xFFF44336); // 강조 색상 (주황색 계열)
  static const Color accentLight = Color(0xFF90CAF9); // 밝은 강조 색상

  // 상태 색상
  static const Color success = Color(0xFF2ECC71); // 성공 상태
  static const Color warning = Color(0xFFF39C12); // 경고 상태
  static const Color error = Color(0xFFE74C3C); // 오류 상태
  static const Color info = Color(0xFF3498DB); // 정보 상태

  // 텍스트 색상
  static const Color textPrimary = Color(0xFF333333); // 주요 텍스트
  static const Color textSecondary = Color(0xFF666666); // 보조 텍스트
  static const Color textHint = Color(0xFF999999); // 힌트 텍스트

  // 배경 색상
  static const Color background = Color(0xFFFFFFFF); // 앱 배경
  static const Color cardBackground = Color(0xFF1E1E1E); // 카드 배경
  static const Color divider = Color(0xFFE0E0E0); // 구분선

  // 감정 관련 색상
  static const Color positive = Color(0xFF4CAF50); // 긍정적 감정
  static const Color neutral = Color(0xFFFFCA28); // 중립적 감정
  static const Color negative = Color(0xFFF44336); // 부정적 감정

  // 기존 코드와의 호환성을 위한 별칭
  static const Color primaryColor = primary;
  static const Color secondaryColor = secondary;
  static const Color kakaoColor = Color(0xFFFEE500); // 카카오 브랜드 색상
  static const Color lightGrayColor = Color(0xFFF5F5F5); // 연한 회색
  static const Color inputBackgroundColor = lightGrayColor; // 입력 필드 배경

  // 배경 색상
  static const Color darkBackground = Color(0xFF121212); // 다크 모드 배경
  static const Color darkCardBackground = Color(0xFF252525); // 더 어두운 카드 배경

  // 텍스트 색상
  static const Color text = Color(0xFF212121); // 주요 텍스트
  static const Color secondaryText = Color(0xFF757575); // 보조 텍스트
  static const Color disabledText = Color(0xFF9E9E9E); // 비활성화된 텍스트
  static const Color lightText = Color(0xFFE0E0E0); // 밝은 배경의 텍스트

  // 기존 코드와의 호환성을 위한 별칭
  static const Color textColor = text;
  static const Color secondaryTextColor = secondaryText;
  static const Color hintTextColor = disabledText;

  // 경계선 및 구분선
  static const Color border = Color(0xFFE0E0E0); // 경계선

  // 기존 코드와의 호환성을 위한 별칭
  static const Color dividerColor = divider;

  // 기존 코드와의 호환성을 위한 별칭
  static const Color errorColor = error;

  // 투명도가 있는 색상
  static Color primaryWithOpacity(double opacity) =>
      primary.withAlpha((opacity * 255).round());
  static Color darkBackgroundWithOpacity(double opacity) =>
      darkBackground.withAlpha((opacity * 255).round());
}

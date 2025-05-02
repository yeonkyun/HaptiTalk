import 'package:flutter/material.dart';

class AppColors {
  // 주요 색상
  static const Color primary = Color(0xFF3F51B5); // 앱의 주요 색상 (인디고)
  static const Color secondary = Color(0xFF90CAF9); // 보조 색상 (라이트 블루)
  static const Color accent = Color(0xFFF44336); // 강조 색상 (레드)
  static const Color accentLight = Color(0xFF90CAF9); // 라이트 액센트

  // 기존 코드와의 호환성을 위한 별칭
  static const Color primaryColor = primary;
  static const Color secondaryColor = secondary;
  static const Color kakaoColor = Color(0xFFFEE500); // 카카오 브랜드 색상
  static const Color lightGrayColor = Color(0xFFF5F5F5); // 연한 회색
  static const Color inputBackgroundColor = lightGrayColor; // 입력 필드 배경

  // 배경 색상
  static const Color background = Color(0xFFFFFFFF); // 밝은 모드 배경
  static const Color darkBackground = Color(0xFF121212); // 다크 모드 배경
  static const Color cardBackground = Color(0xFF1E1E1E); // 카드 배경 (다크 모드)
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
  static const Color divider = Color(0xFFE0E0E0); // 구분선
  static const Color border = Color(0xFFE0E0E0); // 경계선

  // 기존 코드와의 호환성을 위한 별칭
  static const Color dividerColor = divider;

  // 상태 색상
  static const Color success = Color(0xFF4CAF50); // 성공
  static const Color warning = Color(0xFFFFC107); // 경고
  static const Color error = Color(0xFFF44336); // 오류

  // 기존 코드와의 호환성을 위한 별칭
  static const Color errorColor = error;

  // 투명도가 있는 색상
  static Color primaryWithOpacity(double opacity) =>
      primary.withOpacity(opacity);
  static Color darkBackgroundWithOpacity(double opacity) =>
      darkBackground.withOpacity(opacity);
}

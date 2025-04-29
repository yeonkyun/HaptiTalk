import 'package:flutter/material.dart';
import 'package:hapti_talk/constants/colors.dart';

class AppTheme {
  // 라이트 테마
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primaryColor,
      primary: AppColors.primaryColor,
      secondary: AppColors.secondaryColor,
      background: Colors.white,
    ),

    // 앱바 테마
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: AppColors.textColor),
      titleTextStyle: TextStyle(
        color: AppColors.textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    ),

    // 버튼 테마
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(double.infinity, 55),
      ),
    ),

    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryColor,
        side: const BorderSide(color: AppColors.primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        minimumSize: const Size(double.infinity, 55),
      ),
    ),

    // 텍스트 테마
    textTheme: const TextTheme(
      displayLarge: TextStyle(
        color: AppColors.textColor,
        fontSize: 28,
        fontWeight: FontWeight.bold,
      ),
      displayMedium: TextStyle(
        color: AppColors.textColor,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
      displaySmall: TextStyle(
        color: AppColors.textColor,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      bodyLarge: TextStyle(
        color: AppColors.textColor,
        fontSize: 16,
      ),
      bodyMedium: TextStyle(
        color: AppColors.textColor,
        fontSize: 14,
      ),
      labelLarge: TextStyle(
        color: AppColors.textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),

    // 입력 필드 테마
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.inputBackgroundColor,
      hintStyle: TextStyle(color: AppColors.hintTextColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryColor),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 16,
      ),
    ),

    // 카드 테마
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),

    // 탭바 테마
    tabBarTheme: const TabBarTheme(
      labelColor: AppColors.primaryColor,
      unselectedLabelColor: AppColors.secondaryTextColor,
      indicatorColor: AppColors.primaryColor,
      labelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
    ),
  );

  // 다크 테마 (필요시 구현)
  static ThemeData darkTheme = ThemeData(
      // 다크 테마 설정
      );
}

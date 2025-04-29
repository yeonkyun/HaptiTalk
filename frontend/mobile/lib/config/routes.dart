import 'package:flutter/material.dart';
import 'package:hapti_talk/screens/auth/login_screen.dart';
import 'package:hapti_talk/screens/auth/signup_screen.dart';
// import 'package:hapti_talk/screens/onboarding/onboarding_screen.dart';
// import 'package:hapti_talk/screens/main/main_tab_screen.dart';
// import 'package:hapti_talk/screens/session/new_session_screen.dart';
// import 'package:hapti_talk/screens/session/session_details_screen.dart';
// import 'package:hapti_talk/screens/analysis/realtime_analysis_screen.dart';
// import 'package:hapti_talk/screens/analysis/analysis_summary_screen.dart';
// import 'package:hapti_talk/screens/history/sessions_history_screen.dart';
// import 'package:hapti_talk/screens/profile/profile_screen.dart';
// import 'package:hapti_talk/screens/profile/settings_screen.dart';
// import 'package:hapti_talk/screens/profile/subscription_screen.dart';

class AppRoutes {
  // 라우트 이름 정의
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String main = '/main';
  static const String newSession = '/session/new';
  static const String sessionDetails = '/session/details';
  static const String realtimeAnalysis = '/analysis/realtime';
  static const String analysisSummary = '/analysis/summary';
  static const String sessionsHistory = '/history';
  static const String profile = '/profile';
  static const String settings = '/profile/settings';
  static const String subscription = '/profile/subscription';

  // 라우트 생성 함수
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      signup: (context) => const SignUpScreen(),
      // onboarding: (context) => const OnboardingScreen(),
      // main: (context) => const MainTabScreen(),
      // newSession: (context) => const NewSessionScreen(),
      // sessionDetails: (context) => const SessionDetailsScreen(),
      // realtimeAnalysis: (context) => const RealtimeAnalysisScreen(),
      // analysisSummary: (context) => const AnalysisSummaryScreen(),
      // sessionsHistory: (context) => const SessionsHistoryScreen(),
      // profile: (context) => const ProfileScreen(),
      // settings: (context) => const SettingsScreen(),
      // subscription: (context) => const SubscriptionScreen(),
    };
  }
}

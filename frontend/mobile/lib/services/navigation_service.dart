import 'package:flutter/material.dart';

class NavigationService {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  // 다음 화면으로 이동 (이전 화면 유지)
  static Future<dynamic> navigateTo(String routeName, {Object? arguments}) {
    return navigator!.pushNamed(routeName, arguments: arguments);
  }

  // 다음 화면으로 이동 (이전 화면 제거)
  static Future<dynamic> navigateToReplacement(String routeName,
      {Object? arguments}) {
    return navigator!.pushReplacementNamed(routeName, arguments: arguments);
  }

  // 다음 화면으로 이동 (이전 화면들 모두 제거)
  static Future<dynamic> navigateToAndRemoveUntil(String routeName,
      {Object? arguments}) {
    return navigator!.pushNamedAndRemoveUntil(
      routeName,
      (Route<dynamic> route) => false,
      arguments: arguments,
    );
  }

  // 이전 화면으로 돌아가기
  static void goBack({dynamic result}) {
    return navigator!.pop(result);
  }

  // 특정 경로까지 이전 화면들 제거하기
  static void popUntil(String routeName) {
    navigator!.popUntil(ModalRoute.withName(routeName));
  }

  // 결과값을 반환하며 이전 화면으로 돌아가기
  static void goBackWithResult(dynamic result) {
    return navigator!.pop(result);
  }

  // 현재 경로 확인
  static String? getCurrentRoute() {
    String? currentRoute;
    navigator!.popUntil((route) {
      currentRoute = route.settings.name;
      return true;
    });
    return currentRoute;
  }

  // 이름 없는 라우트로 이동
  static Future<dynamic> navigateToWidget(Widget widget) {
    return navigator!.push(
      MaterialPageRoute(
        builder: (context) => widget,
      ),
    );
  }
}

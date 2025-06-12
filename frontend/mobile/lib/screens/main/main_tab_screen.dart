import 'package:flutter/material.dart';
import 'package:haptitalk/constants/colors.dart';
import 'package:haptitalk/screens/main/home_screen.dart';
import 'package:haptitalk/screens/history/history_screen.dart';
import 'package:haptitalk/screens/profile/profile_screen.dart';
import 'package:haptitalk/screens/settings/settings_screen.dart';

class MainTabScreen extends StatefulWidget {
  const MainTabScreen({super.key});

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // HomeScreen의 global callback 설정
    onMainTabIndexChange = (index) {
      if (index >= 0 && index < _screens.length) {
        setState(() {
          _currentIndex = index;
        });
      }
    };

    // 1프레임 후에 인자 확인 (화면이 빌드된 후)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleArguments();
    });
  }

  // 인자 처리 함수
  void _handleArguments() {
    final arguments = ModalRoute.of(context)?.settings.arguments;
    if (arguments != null && arguments is Map<String, dynamic>) {
      final initialIndex = arguments['initialTabIndex'];
      if (initialIndex != null &&
          initialIndex is int &&
          initialIndex >= 0 &&
          initialIndex < _screens.length) {
        setState(() {
          _currentIndex = initialIndex;
        });
      }
    }
  }

  @override
  void dispose() {
    // HomeScreen callback 해제
    onMainTabIndexChange = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.05),
              blurRadius: 10,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primaryColor,
          unselectedItemColor: AppColors.hintTextColor,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: '홈',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: '기록',
            ),            
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: '프로필',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: '설정',
            ),
          ],
        ),
      ),
    );
  }
}

// 전역 콜백 변수
Function(int)? onMainTabIndexChange;

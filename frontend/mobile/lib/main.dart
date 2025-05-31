import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:haptitalk/config/app_config.dart';
import 'package:haptitalk/config/routes.dart';
import 'package:haptitalk/config/theme.dart';
import 'package:haptitalk/constants/colors.dart';
import 'package:haptitalk/constants/strings.dart';
import 'package:haptitalk/providers/analysis_provider.dart';
import 'package:haptitalk/providers/session_provider.dart';
import 'package:haptitalk/repositories/analysis_repository.dart';
import 'package:haptitalk/repositories/session_repository.dart';
// 미사용 import 제거
import 'package:haptitalk/services/api_service.dart';
import 'package:haptitalk/services/local_storage_service.dart';
import 'package:haptitalk/services/navigation_service.dart';
import 'package:haptitalk/widgets/common/buttons/primary_button.dart';
import 'package:haptitalk/widgets/common/buttons/secondary_button.dart';
import 'package:haptitalk/services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 환경변수 로드
  await dotenv.load(fileName: '.env');

  // LocalStorageService 초기화
  await LocalStorageService.init();

  // 세로 방향만 지원
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 서비스 및 Repository 생성
  final apiService = ApiService.create();
  final localStorageService = LocalStorageService();

  // AuthService 초기화
  final authService = AuthService.create(apiService, localStorageService);

  final sessionRepository = SessionRepository(apiService, localStorageService);
  final analysisRepository =
      AnalysisRepository(apiService, localStorageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
            create: (_) => SessionProvider(sessionRepository)),
        ChangeNotifierProvider(
            create: (_) =>
                AnalysisProvider(analysisRepository: analysisRepository)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      navigatorKey: NavigationService.navigatorKey,
      initialRoute: AppRoutes.splash,
      routes: AppRoutes.getRoutes(),
      home: const StartScreen(),
    );
  }
}

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // 앱 로고 및 타이틀
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Center(
                        child: Text(
                          "H",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      AppStrings.appName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // 서브 텍스트
              const Text(
                AppStrings.appSlogan,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              const Spacer(),
              // 로그인 버튼
              PrimaryButton(
                text: AppStrings.login,
                onPressed: () {
                  // 실제 로그인 화면으로 이동하도록 변경
                  NavigationService.navigateTo(AppRoutes.login);
                },
              ),
              const SizedBox(height: 15),
              // 회원가입 버튼
              SecondaryButton(
                text: AppStrings.signup,
                onPressed: () {
                  // 실제 회원가입 화면으로 이동하도록 변경
                  NavigationService.navigateTo(AppRoutes.signup);
                },
              ),
              const SizedBox(height: 20),
              // 소셜 로그인 구분선
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.dividerColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      AppStrings.orLoginWith,
                      style: const TextStyle(
                        color: AppColors.hintTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.dividerColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // 소셜 로그인 버튼들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSocialLoginButton(
                    onPressed: () {},
                    backgroundColor: AppColors.lightGrayColor,
                    svgAsset: 'assets/icons/google.svg',
                  ),
                  _buildSocialLoginButton(
                    onPressed: () {},
                    backgroundColor: AppColors.lightGrayColor,
                    svgAsset: 'assets/icons/apple.svg',
                  ),
                  _buildSocialLoginButton(
                    onPressed: () {},
                    backgroundColor: AppColors.kakaoColor,
                    svgAsset: 'assets/icons/kakao.svg',
                  ),
                ],
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialLoginButton({
    required VoidCallback onPressed,
    required Color backgroundColor,
    required String svgAsset,
  }) {
    return SizedBox(
      width: 90,
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: SvgPicture.asset(
          svgAsset,
          width: 24,
          height: 24,
        ),
      ),
    );
  }
}

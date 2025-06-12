import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../constants/colors.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _analyticsEnabled = true;
  String _selectedLanguage = '한국어';
  String _selectedTheme = '시스템 설정';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '설정',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('앱 설정'),
          _buildSettingsGroup([
            _buildSwitchTile(
              '푸시 알림',
              '세션 완료 및 중요 업데이트 알림',
              Icons.notifications_outlined,
              _notificationsEnabled,
              (value) => setState(() => _notificationsEnabled = value),
            ),
            _buildSwitchTile(
              '소리',
              '앱 내 효과음 및 알림음',
              Icons.volume_up_outlined,
              _soundEnabled,
              (value) => setState(() => _soundEnabled = value),
            ),
            _buildSwitchTile(
              '진동',
              '햅틱 피드백 및 알림 진동',
              Icons.vibration_outlined,
              _vibrationEnabled,
              (value) => setState(() => _vibrationEnabled = value),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionTitle('개인화'),
          _buildSettingsGroup([
            _buildSelectTile(
              '언어',
              _selectedLanguage,
              Icons.language_outlined,
              () => _showLanguageSelector(),
            ),
            _buildSelectTile(
              '테마',
              _selectedTheme,
              Icons.palette_outlined,
              () => _showThemeSelector(),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionTitle('개인정보'),
          _buildSettingsGroup([
            _buildSwitchTile(
              '사용 통계 수집',
              '앱 개선을 위한 익명 데이터 수집',
              Icons.analytics_outlined,
              _analyticsEnabled,
              (value) => setState(() => _analyticsEnabled = value),
            ),
            _buildActionTile(
              '데이터 내보내기',
              '내 세션 데이터 다운로드',
              Icons.download_outlined,
              () => _exportData(),
            ),
            _buildActionTile(
              '계정 데이터 삭제',
              '모든 데이터를 영구적으로 삭제',
              Icons.delete_outline,
              () => _deleteAccountData(),
              isDestructive: true,
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionTitle('지원'),
          _buildSettingsGroup([
            _buildActionTile(
              '도움말',
              'FAQ 및 사용 가이드',
              Icons.help_outline,
              () => _openHelp(),
            ),
            _buildActionTile(
              '문의하기',
              '개발팀에 문의 및 피드백',
              Icons.mail_outline,
              () => _contactSupport(),
            ),
            _buildActionTile(
              '앱 정보',
              '버전 정보 및 라이센스',
              Icons.info_outline,
              () => _showAppInfo(),
            ),
          ]),

          const SizedBox(height: 24),
          _buildSectionTitle('계정'),
          _buildSettingsGroup([
            _buildActionTile(
              '로그아웃',
              '계정에서 로그아웃',
              Icons.logout,
              () => _logout(),
              isDestructive: true,
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.secondaryTextColor,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dividerColor),
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.secondaryTextColor,
        ),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.primaryColor,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildSelectTile(
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.secondaryTextColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.secondaryTextColor,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AppColors.primaryColor,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AppColors.secondaryTextColor,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right,
        color: AppColors.secondaryTextColor,
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    );
  }

  void _showLanguageSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '언어 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              '한국어',
              'English',
              '日本語',
              '中文',
            ].map((language) => ListTile(
              title: Text(language),
              trailing: _selectedLanguage == language
                  ? Icon(Icons.check, color: AppColors.primaryColor)
                  : null,
              onTap: () {
                setState(() => _selectedLanguage = language);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _showThemeSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '테마 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              '시스템 설정',
              '라이트 모드',
              '다크 모드',
            ].map((theme) => ListTile(
              title: Text(theme),
              trailing: _selectedTheme == theme
                  ? Icon(Icons.check, color: AppColors.primaryColor)
                  : null,
              onTap: () {
                setState(() => _selectedTheme = theme);
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  void _exportData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('데이터 내보내기'),
        content: const Text('세션 데이터를 다운로드하시겠습니까?\n데이터는 JSON 형식으로 제공됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('데이터 내보내기가 시작되었습니다.')),
              );
            },
            child: const Text('내보내기'),
          ),
        ],
      ),
    );
  }

  void _deleteAccountData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('계정 데이터 삭제'),
        content: const Text('모든 세션 데이터가 영구적으로 삭제됩니다.\n이 작업은 되돌릴 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('계정 데이터가 삭제되었습니다.')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }

  void _openHelp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('도움말 페이지로 이동합니다.')),
    );
  }

  void _contactSupport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('문의하기 페이지로 이동합니다.')),
    );
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('앱 정보'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HaptiTalk'),
            Text('버전: 0.6.0'),
            const SizedBox(height: 16),
            Text('© 2025 HaptiTalk Team'),
            const SizedBox(height: 8),
            Text('대화 분석 및 햅틱 피드백 서비스'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('로그아웃'),
        content: const Text('정말 로그아웃하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              
              // AuthService를 통해 로그아웃
              await AuthService().logout();
              
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('로그아웃되었습니다.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('로그아웃'),
          ),
        ],
      ),
    );
  }
} 
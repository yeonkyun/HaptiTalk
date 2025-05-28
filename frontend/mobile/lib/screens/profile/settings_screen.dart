import 'package:flutter/material.dart';
import 'package:haptitalk/constants/colors.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 테마 옵션
  String _selectedTheme = '시스템';

  // 언어 옵션
  String _selectedLanguage = '한국어';

  // 분석 민감도 값
  double _analysisSensitivity = 0.7;

  // 오디오 저장 정책
  String _audioRetentionPolicy = '7일';

  // 알림 설정
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = false;

  // 햅틱 알림 강도
  double _hapticIntensity = 0.85;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 계정 설정 섹션
            _buildSectionHeader('계정 설정'),
            _buildSettingItem(
              title: '프로필 편집',
              onTap: () {
                // 프로필 편집 화면으로 이동
              },
              showArrow: true,
            ),
            _buildSettingItem(
              title: '비밀번호 변경',
              onTap: () {
                // 비밀번호 변경 화면으로 이동
              },
              showArrow: true,
            ),
            _buildSettingItem(
              title: '연결된 계정 관리',
              onTap: () {
                // 연결된 계정 관리 화면으로 이동
              },
              showArrow: true,
              showDivider: false,
            ),

            // 앱 설정 섹션
            _buildSectionHeader('앱 설정'),
            _buildSettingItemWithValue(
              title: '테마',
              value: _selectedTheme,
              onTap: () {
                _showThemeOptions();
              },
            ),
            _buildSettingItemWithValue(
              title: '언어',
              value: _selectedLanguage,
              onTap: () {
                _showLanguageOptions();
              },
            ),
            _buildSettingItemWithSlider(
              title: '분석 민감도',
              value: _analysisSensitivity,
              onChanged: (value) {
                setState(() {
                  _analysisSensitivity = value;
                });
              },
            ),
            _buildSettingItemWithRadio(
              title: '오디오 저장 정책',
              options: ['저장 안함', '7일', '30일'],
              selectedOption: _audioRetentionPolicy,
              onChanged: (value) {
                setState(() {
                  _audioRetentionPolicy = value;
                });
              },
              showDivider: false,
            ),

            // 알림 설정 섹션
            _buildSectionHeader('알림 설정'),
            _buildSettingItemWithSwitch(
              title: '푸시 알림',
              value: _pushNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _pushNotificationsEnabled = value;
                });
              },
            ),
            _buildSettingItemWithSwitch(
              title: '이메일 알림',
              value: _emailNotificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _emailNotificationsEnabled = value;
                });
              },
            ),
            _buildSettingItemWithSlider(
              title: '햅틱 알림 강도',
              value: _hapticIntensity,
              onChanged: (value) {
                setState(() {
                  _hapticIntensity = value;
                });
              },
              showDivider: false,
            ),

            // 데이터 및 개인정보 섹션
            _buildSectionHeader('데이터 및 개인정보'),
            _buildSettingItem(
              title: '데이터 내보내기',
              onTap: () {
                // 데이터 내보내기 기능
              },
              showArrow: true,
            ),
            _buildSettingItem(
              title: '데이터 삭제',
              onTap: () {
                // 데이터 삭제 기능
              },
              showArrow: true,
            ),
            _buildSettingItem(
              title: '개인정보 설정',
              onTap: () {
                // 개인정보 설정 화면으로 이동
              },
              showArrow: true,
              showDivider: false,
            ),

            // 계정 삭제 버튼
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 53,
                child: ElevatedButton(
                  onPressed: () {
                    _showDeleteAccountConfirmation();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    foregroundColor: Colors.red,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '계정 삭제',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFF44336),
                    ),
                  ),
                ),
              ),
            ),

            // 지원 및 정보 섹션
            _buildSectionHeader('지움 및 정보'),
            _buildSettingItem(
              title: '도움말 센터',
              onTap: () {
                // 도움말 센터로 이동
              },
              showArrow: true,
            ),
            _buildSettingItem(
              title: '피드백 보내기',
              onTap: () {
                // 피드백 보내기 기능
              },
              showArrow: true,
            ),
            _buildSettingItem(
              title: '약관 및 정책',
              onTap: () {
                // 약관 및 정책 화면으로 이동
              },
              showArrow: true,
            ),
            _buildSettingItemWithValue(
              title: '버전 정보',
              value: '1.0.5',
              showArrow: false,
              showDivider: false,
            ),

            // 푸터
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: const Text(
                'HaptiTalk © 2025 All Rights Reserved',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // 섹션 헤더 위젯
  Widget _buildSectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  // 기본 설정 아이템 위젯
  Widget _buildSettingItem({
    required String title,
    required VoidCallback onTap,
    bool showArrow = true,
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF212121),
                  ),
                ),
                if (showArrow)
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }

  // 값이 있는 설정 아이템 위젯
  Widget _buildSettingItemWithValue({
    required String title,
    required String value,
    VoidCallback? onTap,
    bool showArrow = true,
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF212121),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF757575),
                      ),
                    ),
                    if (showArrow)
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }

  // 스위치가 있는 설정 아이템 위젯
  Widget _buildSettingItemWithSwitch({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF212121),
                ),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: AppColors.primaryColor,
                activeTrackColor: AppColors.primaryColor.withOpacity(0.5),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }

  // 슬라이더가 있는 설정 아이템 위젯
  Widget _buildSettingItemWithSlider({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primaryColor,
                        inactiveTrackColor: const Color(0xFFE0E0E0),
                        thumbColor: AppColors.primaryColor,
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayColor: AppColors.primaryColor.withOpacity(0.1),
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: value,
                        onChanged: onChanged,
                        min: 0.0,
                        max: 1.0,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }

  // 라디오 버튼이 있는 설정 아이템 위젯
  Widget _buildSettingItemWithRadio({
    required String title,
    required List<String> options,
    required String selectedOption,
    required ValueChanged<String> onChanged,
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF212121),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: options.map((option) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Radio<String>(
                        value: option,
                        groupValue: selectedOption,
                        onChanged: (value) {
                          if (value != null) {
                            onChanged(value);
                          }
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                      Text(
                        option,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF424242),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFF0F0F0),
          ),
      ],
    );
  }

  // 테마 선택 다이얼로그
  void _showThemeOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('테마 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRadioListTile('시스템', '시스템 설정에 따름'),
              _buildRadioListTile('라이트', '밝은 테마'),
              _buildRadioListTile('다크', '어두운 테마'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // 언어 선택 다이얼로그
  void _showLanguageOptions() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('언어 설정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRadioListTile('한국어', '한국어'),
              _buildRadioListTile('English', 'English'),
              _buildRadioListTile('日本語', '日本語'),
              _buildRadioListTile('中文', '中文'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  // 라디오 리스트 타일 위젯
  Widget _buildRadioListTile(String title, String subtitle) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: title,
      groupValue: title == '시스템'
          ? _selectedTheme
          : (title == '한국어' ? _selectedLanguage : null),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            if (title == '시스템' || title == '라이트' || title == '다크') {
              _selectedTheme = value;
            } else {
              _selectedLanguage = value;
            }
            Navigator.of(context).pop();
          });
        }
      },
      activeColor: AppColors.primaryColor,
    );
  }

  // 계정 삭제 확인 다이얼로그
  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('계정 삭제'),
          content: const Text(
            '계정을 삭제하면 모든 데이터가 영구적으로 삭제됩니다. 이 작업은 되돌릴 수 없습니다. 계속하시겠습니까?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () {
                // 계정 삭제 로직 구현
                Navigator.of(context).pop();
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('삭제'),
            ),
          ],
        );
      },
    );
  }
}

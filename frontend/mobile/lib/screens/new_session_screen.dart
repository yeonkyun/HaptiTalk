import 'package:flutter/material.dart';
import 'package:hapti_talk/constants/colors.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:hapti_talk/screens/smartwatch_manager_screen.dart';
import 'package:hapti_talk/services/service_locator.dart';
import 'package:hapti_talk/screens/realtime_analysis_screen.dart';

class NewSessionScreen extends StatefulWidget {
  const NewSessionScreen({Key? key}) : super(key: key);

  @override
  State<NewSessionScreen> createState() => _NewSessionScreenState();
}

class _NewSessionScreenState extends State<NewSessionScreen> {
  final _sessionNameController = TextEditingController();
  String _selectedMode = '소개팅';
  String _selectedAnalysisLevel = '표준';
  String _selectedRecordingSaving = '7일';
  bool _isSmartWatchConnected = true;
  bool _isPremiumUser = false; // 프리미엄 상태 저장

  @override
  void initState() {
    super.initState();
    _checkPremiumStatus();
  }

  // 프리미엄 상태 확인
  Future<void> _checkPremiumStatus() async {
    final currentUser = await serviceLocator.authService.getCurrentUser();
    if (currentUser != null) {
      setState(() {
        _isPremiumUser = currentUser.isPremium;
      });
    }
  }

  @override
  void dispose() {
    _sessionNameController.dispose();
    super.dispose();
  }

  // 정보 다이얼로그 표시 함수
  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Text(content),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '확인',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // 프리미엄 업그레이드 다이얼로그
  void _showPremiumUpgradeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            '프리미엄 기능',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: const Text(
            '고급 분석 수준은 프리미엄 사용자만 이용할 수 있습니다. 더 심층적인 대화 분석과 맞춤형 조언을 받으려면 프리미엄으로 업그레이드하세요.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                '취소',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 구독 화면으로 이동
              },
              child: const Text(
                '업그레이드',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '새 세션 시작',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 헤더 섹션
              const Text(
                '새로운 세션 시작하기',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '세션 모드와 설정을 선택하세요',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),

              // 세션 모드 섹션
              const Text(
                '세션 모드',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // 세션 모드 그리드
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.0,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                children: [
                  _buildSessionModeCard(
                    title: '소개팅',
                    description: '호감도와 대화 주제 분석',
                    isSelected: _selectedMode == '소개팅',
                    icon: Icons.favorite,
                    onTap: () {
                      setState(() {
                        _selectedMode = '소개팅';
                      });
                    },
                  ),
                  _buildSessionModeCard(
                    title: '면접',
                    description: '자신감과 명확성 분석',
                    isSelected: _selectedMode == '면접',
                    icon: Icons.work,
                    onTap: () {
                      setState(() {
                        _selectedMode = '면접';
                      });
                    },
                  ),
                  _buildSessionModeCard(
                    title: '비즈니스',
                    description: '설득력과 협상 분석',
                    isSelected: _selectedMode == '비즈니스',
                    icon: Icons.business,
                    onTap: () {
                      setState(() {
                        _selectedMode = '비즈니스';
                      });
                    },
                  ),
                  _buildSessionModeCard(
                    title: '코칭',
                    description: '감정 변화와 심리 분석',
                    isSelected: _selectedMode == '코칭',
                    icon: Icons.psychology,
                    onTap: () {
                      setState(() {
                        _selectedMode = '코칭';
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 세션 이름 섹션
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '세션 이름 (선택사항)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline,
                        size: 16, color: Colors.grey[600]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _showInfoDialog('세션 이름',
                          '세션 이름을 지정하면 나중에 기록에서 쉽게 찾을 수 있습니다. 특별한 모임이나 면접, 중요한 대화를 구분할 때 유용합니다. 입력하지 않아도 세션은 시간과 날짜로 자동 저장됩니다.');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sessionNameController,
                decoration: InputDecoration(
                  hintText: '나중에 쉽게 찾을 수 있는 이름',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: Colors.grey[100],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primaryColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 분석 수준 섹션
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '분석 수준',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline,
                        size: 16, color: Colors.grey[600]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _showInfoDialog('분석 수준',
                          '기본: 기본적인 대화 분석 (무료)\n\n표준: 더 상세한 감정 및 대화 분석 (무료)\n\n고급: 심층적인 대화 분석과 맞춤형 조언 (프리미엄)');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectionButton(
                      label: '기본',
                      isSelected: _selectedAnalysisLevel == '기본',
                      onTap: () {
                        setState(() {
                          _selectedAnalysisLevel = '기본';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSelectionButton(
                      label: '표준',
                      isSelected: _selectedAnalysisLevel == '표준',
                      onTap: () {
                        setState(() {
                          _selectedAnalysisLevel = '표준';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSelectionButton(
                      label: '고급',
                      isSelected: _selectedAnalysisLevel == '고급',
                      isPremium: true,
                      onTap: () {
                        if (_isPremiumUser) {
                          setState(() {
                            _selectedAnalysisLevel = '고급';
                          });
                        } else {
                          _showPremiumUpgradeDialog();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 녹음 저장 섹션
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '녹음 저장',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.info_outline,
                        size: 16, color: Colors.grey[600]),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      _showInfoDialog('녹음 저장',
                          '저장 안함: 대화는 분석되지만 녹음 파일은 저장되지 않습니다.\n\n7일 자동 삭제: 녹음이 7일 동안 저장되며 이후 자동 삭제됩니다.\n\n30일 자동 삭제: 녹음이 30일 동안 저장되며 이후 자동 삭제됩니다 (프리미엄).');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildSelectionButton(
                      label: '저장 안함',
                      isSelected: _selectedRecordingSaving == '저장 안함',
                      onTap: () {
                        setState(() {
                          _selectedRecordingSaving = '저장 안함';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSelectionButton(
                      label: '7일\n자동 삭제',
                      isSelected: _selectedRecordingSaving == '7일',
                      onTap: () {
                        setState(() {
                          _selectedRecordingSaving = '7일';
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSelectionButton(
                      label: '30일\n자동 삭제',
                      isSelected: _selectedRecordingSaving == '30일',
                      isPremium: true,
                      onTap: () {
                        if (_isPremiumUser) {
                          setState(() {
                            _selectedRecordingSaving = '30일';
                          });
                        } else {
                          _showPremiumUpgradeDialog();
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 스마트워치 섹션
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.watch,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '스마트워치',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Text(
                                '연결됨 (Apple Watch)',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // 스마트워치 관리 화면으로 이동
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const SmartWatchManagerScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Text(
                          '관리',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 세션 시작 버튼
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // 세션 시작 로직 구현
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RealtimeAnalysisScreen(
                          sessionTitle: _sessionNameController.text.isEmpty
                              ? "새 세션"
                              : _sessionNameController.text,
                          sessionTag: _selectedMode,
                          elapsedTime: "00:00:00",
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '세션 시작하기',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionModeCard({
    required String title,
    required String description,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryColor.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.primaryColor : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectionButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    bool isPremium = false,
  }) {
    final bool isDisabled = isPremium && !_isPremiumUser;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            height: 50,
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primaryColor.withOpacity(0.1)
                  : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? AppColors.primaryColor
                      : (isDisabled ? Colors.grey : Colors.grey[600]),
                ),
              ),
            ),
          ),
          if (isPremium && !_isPremiumUser)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber[700],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  '프리미엄',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

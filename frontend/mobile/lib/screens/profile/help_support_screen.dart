import 'package:flutter/material.dart';
import '../../constants/colors.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({Key? key}) : super(key: key);

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  // FAQ 항목들
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'HaptiTalk은 무엇인가요?',
      'answer': 'HaptiTalk은 햅틱 피드백을 통해 대화 중 감정과 맥락을 전달하는 앱입니다. 사용자의 음성과 텍스트를 분석하여 적절한 햅틱 피드백을 제공합니다.',
      'isExpanded': false,
    },
    {
      'question': '햅틱 알림은 어떻게 작동하나요?',
      'answer': '햅틱 알림은 사용자의 대화 내용을 분석하여 감정, 강조, 맥락 등을 파악한 후 적절한 진동 패턴으로 전달합니다. 이를 통해 메시지의 의도와 감정을 더 잘 이해할 수 있습니다.',
      'isExpanded': false,
    },
    {
      'question': '무료 계정과 프리미엄 계정의 차이점은 무엇인가요?',
      'answer': '무료 계정은 기본적인 기능과 하루 10분의 분석 시간을 제공합니다. 프리미엄 계정은 무제한 분석 시간, 고급 햅틱 패턴, 상세한 분석 리포트, 그리고 클라우드 저장소를 제공합니다.',
      'isExpanded': false,
    },
    {
      'question': '어떤 기기와 호환되나요?',
      'answer': 'HaptiTalk은 대부분의 최신 iOS 및 Android 기기와 호환됩니다. 특히 햅틱 피드백을 지원하는 기기에서 최적의 경험을 제공합니다. 애플 워치 및 특정 웨어러블 장치도 지원합니다.',
      'isExpanded': false,
    },
    {
      'question': '내 대화 내용은 어떻게 저장되나요?',
      'answer': '모든 대화 내용은 암호화되어 저장되며, 사용자가 설정한 저장 정책에 따라 관리됩니다. 기본적으로 7일간 저장되며, 설정에서 저장 기간을 변경하거나 자동 삭제를 설정할 수 있습니다.',
      'isExpanded': false,
    },
    {
      'question': '배터리 소모가 걱정됩니다.',
      'answer': 'HaptiTalk은 배터리 효율성을 고려하여 설계되었습니다. 설정에서 햅틱 강도를 조절하거나 배터리 절약 모드를 활성화하여 배터리 소모를 줄일 수 있습니다.',
      'isExpanded': false,
    },
    {
      'question': '분석 민감도를 조절할 수 있나요?',
      'answer': '네, 설정 메뉴에서 분석 민감도를 조절할 수 있습니다. 높은 민감도는 더 세밀한 감정 변화를 감지하지만 배터리 소모가 증가할 수 있습니다.',
      'isExpanded': false,
    },
    {
      'question': '프라이버시는 어떻게 보호되나요?',
      'answer': '사용자의 모든 데이터는 엄격한 프라이버시 정책에 따라 처리됩니다. 개인 식별 정보는 암호화되며, 제3자와 공유되지 않습니다. 설정에서 언제든지 데이터 삭제를 요청할 수 있습니다.',
      'isExpanded': false,
    },
  ];

  // 검색어
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    // 검색어에 따른 필터링
    final filteredFaqItems = _searchQuery.isEmpty
        ? _faqItems
        : _faqItems.where((item) =>
            item['question']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()) ||
            item['answer']
                .toString()
                .toLowerCase()
                .contains(_searchQuery.toLowerCase())).toList();

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
          '도움말 및 지원',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 검색 바
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: '질문 검색...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: AppColors.primaryColor),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 0,
                  horizontal: 16,
                ),
              ),
            ),
          ),

          // FAQ 목록
          Expanded(
            child: filteredFaqItems.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '검색 결과가 없습니다',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredFaqItems.length,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemBuilder: (context, index) {
                      final item = filteredFaqItems[index];
                      return _buildFaqItem(item, index);
                    },
                  ),
          ),

          // 문의하기 버튼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  // 문의하기 기능
                  _showContactUsDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '1:1 문의하기',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(Map<String, dynamic> item, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        initiallyExpanded: item['isExpanded'],
        onExpansionChanged: (expanded) {
          setState(() {
            // 현재 FAQ 항목 상태 변경
            if (_searchQuery.isEmpty) {
              _faqItems[index]['isExpanded'] = expanded;
            } else {
              // 검색 상태에서는 원본 데이터의 해당 항목을 찾아서 변경
              final originalIndex = _faqItems.indexWhere(
                  (originalItem) => originalItem['question'] == item['question']);
              if (originalIndex != -1) {
                _faqItems[originalIndex]['isExpanded'] = expanded;
              }
            }
          });
        },
        title: Text(
          item['question'],
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        iconColor: AppColors.primaryColor,
        collapsedIconColor: Colors.grey,
        childrenPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        children: [
          Text(
            item['answer'],
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                '도움이 되었나요?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () {
                  // 도움됨 기능
                  _showFeedbackSnackBar(true);
                },
                icon: const Icon(
                  Icons.thumb_up_outlined,
                  size: 16,
                ),
                label: const Text('네'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  // 도움안됨 기능
                  _showFeedbackSnackBar(false);
                },
                icon: const Icon(
                  Icons.thumb_down_outlined,
                  size: 16,
                ),
                label: const Text('아니오'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFeedbackSnackBar(bool isHelpful) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isHelpful ? '피드백 감사합니다!' : '더 나은 답변을 제공하기 위해 노력하겠습니다.',
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: isHelpful ? Colors.green : Colors.grey.shade700,
      ),
    );
  }

  void _showContactUsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('1:1 문의하기'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '문의사항이 있으신가요? 다음 방법으로 연락하시면 빠르게 답변해드리겠습니다.',
              ),
              const SizedBox(height: 16),
              _buildContactMethod(
                icon: Icons.email_outlined,
                title: '이메일',
                subtitle: 'support@haptitalk.com',
              ),
              const SizedBox(height: 10),
              _buildContactMethod(
                icon: Icons.headset_mic_outlined,
                title: '고객센터',
                subtitle: '1588-0000 (평일 9시-6시)',
              ),
              const SizedBox(height: 10),
              _buildContactMethod(
                icon: Icons.chat_outlined,
                title: '채팅 상담',
                subtitle: '앱 내 채팅으로 실시간 상담',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('닫기'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactMethod({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: AppColors.primaryColor,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(subtitle),
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }
}

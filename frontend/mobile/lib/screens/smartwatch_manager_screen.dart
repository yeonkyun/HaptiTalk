import 'package:flutter/material.dart';
import 'package:hapti_talk/constants/colors.dart';

class SmartWatchManagerScreen extends StatefulWidget {
  const SmartWatchManagerScreen({Key? key}) : super(key: key);

  @override
  State<SmartWatchManagerScreen> createState() =>
      _SmartWatchManagerScreenState();
}

class _SmartWatchManagerScreenState extends State<SmartWatchManagerScreen> {
  bool _isWatchConnected = true;
  bool _isSearching = false;
  final List<Map<String, dynamic>> _availableDevices = [
    {
      'name': 'Apple Watch',
      'id': 'AW-143256',
      'isConnected': true,
    },
    {
      'name': 'Galaxy Watch',
      'id': 'GW-987654',
      'isConnected': false,
    },
  ];

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
          '스마트워치 관리',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상태 표시
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
                      color: _isWatchConnected
                          ? AppColors.primaryColor
                          : Colors.grey[400],
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
                          '스마트워치 상태',
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
                                color: _isWatchConnected
                                    ? Colors.green
                                    : Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isWatchConnected
                                  ? '연결됨 (Apple Watch)'
                                  : '연결되지 않음',
                              style: TextStyle(
                                fontSize: 14,
                                color: _isWatchConnected
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 햅틱 피드백 설명
            const Text(
              '햅틱 피드백',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '실시간 대화 피드백',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '스마트워치를 통해 다음의 햅틱 패턴을 실시간으로 받아볼 수 있습니다:',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text('• 자세 교정 알림 (진동 패턴: 짧게 2회)',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                  SizedBox(height: 4),
                  Text('• 말하기 속도 조절 (진동 패턴: 길게 1회)',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                  SizedBox(height: 4),
                  Text('• 긍정적 반응 감지 (진동 패턴: 짧게-길게)',
                      style: TextStyle(fontSize: 14, color: Colors.black54)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 연결된 기기 섹션
            const Text(
              '연결된 기기',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // 기기 목록
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _availableDevices.length,
              itemBuilder: (context, index) {
                final device = _availableDevices[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: ListTile(
                    leading: Icon(
                      Icons.watch_outlined,
                      color: device['isConnected']
                          ? AppColors.primaryColor
                          : Colors.grey,
                    ),
                    title: Text(
                      device['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(device['id']),
                    trailing: TextButton(
                      onPressed: () {
                        // 연결/해제 로직
                        setState(() {
                          if (device['isConnected']) {
                            device['isConnected'] = false;
                            if (device['name'] == 'Apple Watch') {
                              _isWatchConnected = false;
                            }
                          } else {
                            // 다른 연결된 기기 모두 해제
                            for (var d in _availableDevices) {
                              d['isConnected'] = false;
                            }
                            device['isConnected'] = true;
                            _isWatchConnected = true;
                          }
                        });
                      },
                      child: Text(
                        device['isConnected'] ? '연결 해제' : '연결',
                        style: TextStyle(
                          color: device['isConnected']
                              ? Colors.red
                              : AppColors.primaryColor,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // 새 기기 검색 버튼
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isSearching = true;
                  });

                  // 검색 시뮬레이션
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text('기기 검색 중'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('주변 스마트워치 기기를 검색하고 있습니다...'),
                          ],
                        ),
                      );
                    },
                  );

                  // 3초 후 검색 완료 시뮬레이션
                  Future.delayed(const Duration(seconds: 3), () {
                    Navigator.of(context).pop(); // 로딩 다이얼로그 닫기
                    setState(() {
                      _isSearching = false;
                    });

                    // 새 기기 발견 시뮬레이션
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('검색 완료'),
                          content: const Text(
                              '새로운 기기를 찾지 못했습니다. 기기가 페어링 모드인지 확인해주세요.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('확인'),
                            ),
                          ],
                        );
                      },
                    );
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isSearching ? Colors.grey : AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _isSearching ? '검색 중...' : '새 기기 검색',
                  style: const TextStyle(
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
    );
  }
}

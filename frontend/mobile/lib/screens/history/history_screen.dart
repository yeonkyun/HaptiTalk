import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../constants/assets.dart';
import '../../constants/colors.dart';
import '../../widgets/session_card.dart';
import '../../models/session.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _selectedCategory = '전체';
  String _selectedSort = '최신순';
  final List<String> _categories = [
    '전체',
    '소개팅',
    '면접',
    '비즈니스',
    '코칭',
    '최근 일주일',
    '최근 한달'
  ];
  final List<String> _sortOptions = ['최신순', '평가순'];

  // 더미 데이터
  final List<Session> _sessions = [
    Session(
      id: '1',
      title: '첫번째 소개팅',
      date: '2024년 3월 23일',
      duration: '1:32:05',
      type: '소개팅',
      metrics: {
        '호감도': 88,
        '경청 지수': 92,
      },
      progress: 0.7,
    ),
    Session(
      id: '2',
      title: '팀 프로젝트 미팅',
      date: '2024년 3월 20일',
      duration: '45:12',
      type: '비즈니스',
      metrics: {
        '설득력': 82,
        '명확성': 85,
      },
      progress: 0.6,
    ),
    Session(
      id: '3',
      title: '영어 스피킹 연습',
      date: '2024년 3월 15일',
      duration: '35:48',
      type: '코칭',
      metrics: {
        '발음': 75,
        '유창성': 80,
      },
      progress: 0.5,
    ),
    Session(
      id: '4',
      title: '직무 면접 연습',
      date: '2024년 3월 10일',
      duration: '58:24',
      type: '면접',
      metrics: {
        '자신감': 78,
        '명확성': 83,
      },
      progress: 0.65,
    ),
    Session(
      id: '5',
      title: '두번째 소개팅',
      date: '2024년 3월 5일',
      duration: '1:05:19',
      type: '소개팅',
      metrics: {
        '호감도': 85,
        '경청 지수': 87,
      },
      progress: 0.75,
    ),
  ];

  List<Session> get filteredSessions {
    List<Session> filtered = List.from(_sessions);

    // 카테고리 필터링
    if (_selectedCategory != '전체' &&
        _selectedCategory != '최근 일주일' &&
        _selectedCategory != '최근 한달') {
      filtered = filtered
          .where((session) => session.type == _selectedCategory)
          .toList();
    } else if (_selectedCategory == '최근 일주일') {
      // 최근 일주일 필터링 로직 (실제로는 날짜 비교 필요)
      filtered = filtered.take(3).toList();
    } else if (_selectedCategory == '최근 한달') {
      // 최근 한달 필터링 로직 (실제로는 날짜 비교 필요)
      filtered = filtered;
    }

    // 정렬
    if (_selectedSort == '최신순') {
      // 이미 최신순으로 정렬되어 있다고 가정
    } else if (_selectedSort == '평가순') {
      // 평가 기준으로 정렬 (진행률 기준으로 임시 구현)
      filtered.sort((a, b) => b.progress.compareTo(a.progress));
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          '기록',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            color: AppColors.secondaryTextColor,
            onPressed: () {
              // 검색 기능 구현
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // 카테고리 필터 (가로 스크롤 가능한 토글 버튼)
          Container(
            height: 57,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primaryColor
                            : AppColors.lightGrayColor,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primaryColor
                              : AppColors.dividerColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : AppColors.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 세션 개수 및 정렬 옵션
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '총 ${filteredSessions.length}개 세션',
                  style: TextStyle(
                    color: AppColors.secondaryTextColor,
                    fontSize: 14,
                  ),
                ),
                Row(
                  children: _sortOptions.map((option) {
                    final isSelected = option == _selectedSort;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedSort = option;
                        });
                      },
                      child: Row(
                        children: [
                          Text(
                            option,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.primaryColor
                                  : AppColors.secondaryTextColor,
                              fontWeight: isSelected
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          if (option != _sortOptions.last)
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                              width: 1,
                              height: 14,
                              color: AppColors.dividerColor,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // 세션 목록
          Expanded(
            child: filteredSessions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          Assets.emptyState,
                          width: 120,
                          height: 120,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '세션 기록이 없습니다',
                          style: TextStyle(
                            color: AppColors.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '새로운 세션을 시작해보세요',
                          style: TextStyle(
                            color: AppColors.secondaryTextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, bottom: 20),
                    itemCount: filteredSessions.length,
                    itemBuilder: (context, index) {
                      final session = filteredSessions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15),
                        child: SessionCard(session: session),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

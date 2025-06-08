import 'package:flutter/material.dart';
import '../models/session.dart';
import '../constants/colors.dart';
import '../screens/session/session_details_screen.dart';

class SessionCard extends StatelessWidget {
  final Session session;
  final Function(String)? onDelete;

  const SessionCard({
    Key? key,
    required this.session,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 메트릭 항목 키 목록
    final metricKeys = session.metrics.keys.toList();

    Widget cardContent = GestureDetector(
      onTap: () {
        // 세션 상세 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SessionDetailsScreen(sessionId: session.id),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13), // 0.05 * 255 = ~13
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 제목, 날짜, 태그
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          session.date,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.lightGrayColor,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 5),
                        Text(
                          session.type,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // 메트릭 지표들
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 시간
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.duration,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '시간',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.hintTextColor,
                        ),
                      ),
                    ],
                  ),

                  // 첫 번째 메트릭
                  if (metricKeys.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${session.metrics[metricKeys[0]]}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          metricKeys[0],
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.hintTextColor,
                          ),
                        ),
                      ],
                    ),

                  // 두 번째 메트릭
                  if (metricKeys.length > 1)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${session.metrics[metricKeys[1]]}%',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          metricKeys[1],
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.hintTextColor,
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              const SizedBox(height: 15),

              // 진행 상태 바
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  height: 40,
                  width: double.infinity,
                  color: AppColors.lightGrayColor,
                  child: Stack(
                    children: [
                      // 진행 상태
                      FractionallySizedBox(
                        widthFactor: session.progress,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryColor,
                                AppColors.primaryColor
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // 삭제 기능이 있으면 Dismissible로 감싸기
    if (onDelete != null) {
      return Dismissible(
        key: Key(session.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          // 스와이프 시 삭제 확인 다이얼로그 표시
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                '세션 삭제',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textColor,
                ),
              ),
              content: Text(
                '${session.title}을(를) 삭제하시겠습니까?\n삭제된 데이터는 복구할 수 없습니다.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.secondaryTextColor,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    '취소',
                    style: TextStyle(
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    '삭제',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) {
          onDelete!(session.id);
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 30),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.delete_outline,
                color: Colors.white,
                size: 30,
              ),
              SizedBox(height: 4),
              Text(
                '삭제',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        child: cardContent,
      );
    }

    return cardContent;
  }
}

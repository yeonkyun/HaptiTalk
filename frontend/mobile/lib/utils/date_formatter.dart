import 'package:intl/intl.dart';

class DateFormatter {
  // 기본 날짜 표시 형식
  static String formatDate(DateTime date) {
    return DateFormat('yyyy.MM.dd').format(date);
  }

  // 상세 날짜 및 시간 표시 형식
  static String formatDateTime(DateTime date) {
    return DateFormat('yyyy.MM.dd HH:mm').format(date);
  }

  // 요일 포함 날짜 형식
  static String formatDateWithDay(DateTime date) {
    return DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(date);
  }

  // 시간만 표시
  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  // 세션 경과 시간 포맷팅 (초 단위)
  static String formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 지난 시간 표시 (방금 전, 1시간 전, 어제 등)
  static String timeAgo(DateTime date) {
    final difference = DateTime.now().difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}년 전';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}개월 전';
    } else if (difference.inDays > 0) {
      return difference.inDays == 1 ? '어제' : '${difference.inDays}일 전';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}시간 전';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}분 전';
    } else {
      return '방금 전';
    }
  }

  // 주간 날짜 범위 표시 (예: 2023.06.01 - 2023.06.07)
  static String formatWeekRange(DateTime startDate) {
    final endDate = startDate.add(const Duration(days: 6));
    return '${formatDate(startDate)} - ${formatDate(endDate)}';
  }

  // 월 전체 표시 (예: 2023년 6월)
  static String formatMonth(DateTime date) {
    return DateFormat('yyyy년 MM월', 'ko_KR').format(date);
  }

  // 세션 시간 표시 (예: 오전 10:30 - 오전 11:15)
  static String formatSessionTime(DateTime startTime, DateTime endTime) {
    return '${DateFormat('a h:mm', 'ko_KR').format(startTime)} - ${DateFormat('a h:mm', 'ko_KR').format(endTime)}';
  }
}

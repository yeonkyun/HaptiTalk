class StringUtils {
  // 문자열 자르기 (최대 길이 초과 시 말줄임표 추가)
  static String truncate(String text, int maxLength) {
    if (text.length <= maxLength) {
      return text;
    }
    return '${text.substring(0, maxLength)}...';
  }

  // 첫 글자만 대문자로 변환
  static String capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  // 모든 단어의 첫 글자를 대문자로 변환
  static String titleCase(String text) {
    if (text.isEmpty) return text;

    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // 문자열이 비어있는지 또는 null인지 확인
  static bool isNullOrEmpty(String? text) {
    return text == null || text.isEmpty;
  }

  // 문자열이 비어있지 않은지 확인
  static bool isNotNullOrEmpty(String? text) {
    return text != null && text.isNotEmpty;
  }

  // HTML 태그 제거
  static String stripHtmlTags(String htmlString) {
    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '');
  }

  // 이메일 마스킹 (예: a****@gmail.com)
  static String maskEmail(String email) {
    if (email.isEmpty || !email.contains('@')) return email;

    final parts = email.split('@');
    final username = parts[0];
    final domain = parts[1];

    if (username.length <= 1) return email;

    final maskedUsername = '${username[0]}${'*' * (username.length - 1)}';
    return '$maskedUsername@$domain';
  }

  // 전화번호 마스킹 (예: 010-****-5678)
  static String maskPhoneNumber(String phoneNumber) {
    // 하이픈 제거
    final cleanNumber = phoneNumber.replaceAll('-', '');

    if (cleanNumber.length != 11) return phoneNumber;

    return '${cleanNumber.substring(0, 3)}-****-${cleanNumber.substring(7)}';
  }

  // 문자열 내 특정 단어 하이라이트
  static String highlightText(
      String text, String query, String prefix, String suffix) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return text;
    }

    final int startIndex = text.toLowerCase().indexOf(query.toLowerCase());
    final int endIndex = startIndex + query.length;

    return text.substring(0, startIndex) +
        prefix +
        text.substring(startIndex, endIndex) +
        suffix +
        text.substring(endIndex);
  }

  // 숫자에 천 단위 구분자 추가
  static String formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }
}

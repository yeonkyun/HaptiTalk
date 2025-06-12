class Validators {
  // 이메일 유효성 검사
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '이메일을 입력해주세요';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return '유효한 이메일 주소를 입력해주세요';
    }

    return null;
  }

  // 비밀번호 유효성 검사
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 입력해주세요';
    }

    if (value.length < 8) {
      return '비밀번호는 8자 이상이어야 합니다';
    }

    // 영문, 숫자, 특수문자 포함 검사
    final hasUppercase = RegExp(r'[A-Z]').hasMatch(value);
    final hasLowercase = RegExp(r'[a-z]').hasMatch(value);
    final hasDigits = RegExp(r'[0-9]').hasMatch(value);
    final hasSpecialCharacters =
        RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value);

    if (!(hasUppercase || hasLowercase) ||
        !hasDigits ||
        !hasSpecialCharacters) {
      return '비밀번호는 영문, 숫자, 특수문자를 포함해야 합니다';
    }

    return null;
  }

  // 비밀번호 확인 유효성 검사
  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return '비밀번호를 다시 입력해주세요';
    }

    if (value != password) {
      return '비밀번호가 일치하지 않습니다';
    }

    return null;
  }

  // 이름 유효성 검사
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '이름을 입력해주세요';
    }

    if (value.length < 2) {
      return '이름은 2자 이상이어야 합니다';
    }

    return null;
  }

  // 필수 입력 필드 유효성 검사
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName을(를) 입력해주세요';
    }

    return null;
  }

  // 세션 이름 유효성 검사
  static String? validateSessionName(String? value) {
    if (value == null || value.isEmpty) {
      return '세션 이름을 입력해주세요';
    }

    if (value.length < 2 || value.length > 50) {
      return '세션 이름은 2-50자 사이여야 합니다';
    }

    return null;
  }

  // 세션 시간 유효성 검사 (분 단위)
  static String? validateSessionDuration(String? value) {
    if (value == null || value.isEmpty) {
      return '세션 시간을 입력해주세요';
    }

    final duration = int.tryParse(value);
    if (duration == null) {
      return '유효한 숫자를 입력해주세요';
    }

    if (duration < 1 || duration > 180) {
      return '세션 시간은 1-180분 사이여야 합니다';
    }

    return null;
  }

  // 휴대폰 번호 유효성 검사
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return null; // 선택적 필드인 경우
    }

    final phoneRegex = RegExp(r'^010-?[0-9]{4}-?[0-9]{4}$');
    if (!phoneRegex.hasMatch(value)) {
      return '유효한 휴대폰 번호를 입력해주세요 (예: 010-1234-5678)';
    }

    return null;
  }
}

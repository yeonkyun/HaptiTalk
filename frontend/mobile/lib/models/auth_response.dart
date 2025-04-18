import 'package:hapti_talk/models/user.dart';

class AuthResponse {
  final bool success;
  final String? token;
  final User? user;
  final String? errorMessage;

  AuthResponse({
    required this.success,
    this.token,
    this.user,
    this.errorMessage,
  });
}

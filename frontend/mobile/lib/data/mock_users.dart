import 'package:hapti_talk/models/user.dart';

// 목업 사용자 데이터
List<User> mockUsers = [
  User(
    id: '1',
    email: 'test@example.com',
    name: '테스트 사용자',
    isPremium: false,
  ),
  User(
    id: '2',
    email: 'premium@example.com',
    name: '프리미엄 사용자',
    isPremium: true,
  ),
];

// 사용자 이메일로 찾기
User? findUserByEmail(String email) {
  try {
    return mockUsers.firstWhere((user) => user.email == email);
  } catch (e) {
    return null;
  }
}

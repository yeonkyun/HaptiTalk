class UserModel {
  final String id;
  final String email;
  final String name;
  final String? profileImage;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // first_name과 last_name을 조합하여 name 생성
    String name = '';
    if (json['first_name'] != null && json['last_name'] != null) {
      name = '${json['first_name']} ${json['last_name']}'.trim();
    } else if (json['first_name'] != null) {
      name = json['first_name'];
    } else if (json['last_name'] != null) {
      name = json['last_name'];
    } else if (json['name'] != null) {
      name = json['name'];
    } else if (json['username'] != null) {
      name = json['username'];
    } else if (json['email'] != null) {
      // 이메일의 @ 앞부분을 이름으로 사용
      final email = json['email'] as String;
      final atIndex = email.indexOf('@');
      if (atIndex > 0) {
        name = email.substring(0, atIndex);
      } else {
        name = '사용자';
      }
    } else {
      name = '사용자'; // 기본값
    }

    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: name,
      profileImage: json['profile_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profileImage': profileImage,
    };
  }
}

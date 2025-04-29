class User {
  final String id;
  final String email;
  final String name;
  final String? profileImage;
  final bool isPremium;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
    this.isPremium = false,
  });
}

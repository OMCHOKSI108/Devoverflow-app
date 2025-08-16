// lib/common/models/user_model.dart

enum UserRole { guest, user, moderator, admin }

class UserModel {
  final String id;
  final String name;
  final String username;
  final String email;
  final String profileImageUrl;
  final UserRole role;
  final int reputation;
  final String? bio;
  final String? mobileNumber;
  final List<String> friendIds; // <-- ADD THIS NEW FIELD

  UserModel({
    required this.id,
    required this.name,
    required this.username,
    required this.email,
    required this.profileImageUrl,
    this.role = UserRole.user,
    this.reputation = 0,
    this.bio,
    this.mobileNumber,
    this.friendIds = const [], // Default to an empty list
  });
}

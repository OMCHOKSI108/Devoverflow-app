// lib/common/models/user_model.dart

// Your API docs mention isAdmin, so we can represent roles like this.
enum UserRole { user, admin }

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? bio;
  final String? location;
  final String? website;
  final String profileImageUrl;
  final UserRole role;
  final int reputation;
  final List<String> friendIds; // Assuming your API provides this
  final List<String> bookmarkedQuestionIds;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.bio,
    this.location,
    this.website,
    required this.profileImageUrl,
    this.role = UserRole.user,
    this.reputation = 0,
    this.friendIds = const [],
    this.bookmarkedQuestionIds = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> map) {
    return UserModel(
      id: map['_id'] ?? map['id'] ?? '',
      username: map['username'] ?? 'Unknown User',
      email: map['email'] ?? '',
      bio: map['bio'],
      location: map['location'],
      website: map['website'],
      profileImageUrl: map['profileImageUrl'] ?? 'https://i.pravatar.cc/150',
      role: (map['isAdmin'] == true) ? UserRole.admin : UserRole.user,
      reputation: map['reputation'] ?? 0,
      friendIds: List<String>.from(map['friends'] ?? []),
      bookmarkedQuestionIds: List<String>.from(map['bookmarks'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'bio': bio,
      'location': location,
      'website': website,
      'profileImageUrl': profileImageUrl,
      'isAdmin': role == UserRole.admin,
      'reputation': reputation,
      'friends': friendIds,
      'bookmarks': bookmarkedQuestionIds,
    };
  }
}

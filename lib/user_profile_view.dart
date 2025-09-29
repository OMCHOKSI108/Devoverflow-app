import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'gamification.dart';
import 'api_service.dart';
import 'api_config.dart';
import 'image_viewer_dialog.dart';

class UserProfileViewScreen extends StatefulWidget {
  final String userEmail;

  const UserProfileViewScreen({super.key, required this.userEmail});

  @override
  State<UserProfileViewScreen> createState() => _UserProfileViewScreenState();
}

class _UserProfileViewScreenState extends State<UserProfileViewScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _isFriend = false;
  Map<String, dynamic> _reputation = {
    'reputation': 0,
    'level': 'Beginner',
    'nextLevelPoints': 100,
  };
  List<Map<String, dynamic>> _badges = [];
  List<Map<String, dynamic>> _privileges = [];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();

    try {
      // Try API: find user by email via users endpoint (assuming GET /users?email=... supported)
      final resp = await ApiService().get(
        '${ApiConfig.getAllUsers}?email=${Uri.encodeComponent(widget.userEmail)}',
      );
      Map<String, dynamic> userData = {};
      if (resp is Map && resp['user'] is Map) {
        userData = resp['user'];
      } else if (resp is Map && resp['data'] is List) {
        final users = ApiService().extractList(resp, ['data', 'users']);
        if (users.isNotEmpty) {
          userData = users[0];
        }
      }

      if (userData.isNotEmpty) {
        _userProfile = userData;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'last_viewed_user_${widget.userEmail}',
            json.encode(_userProfile),
          );
        } catch (_) {}
      }

      // Check friendship status from API if endpoint exists
      try {
        final friendsResp = await ApiService().getFriends(page: 1, limit: 200);
        List<dynamic> friendsList = ApiService().extractList(friendsResp, [
          'friends',
          'data',
        ]);

        // Handle nested data structure: response.data.friends
        if (friendsList.isEmpty) {
          final data = friendsResp['data'];
          if (data is Map<String, dynamic> && data['friends'] is List) {
            friendsList = data['friends'] as List<dynamic>;
          }
        }

        _isFriend = friendsList.cast<Map<String, dynamic>>().any(
          (f) => f['email'] == widget.userEmail,
        );
        await prefs.setString('friends', json.encode(friendsList));
      } catch (_) {
        // ignore - fallback below
      }

      // Load additional profile fields if present from API
      if (_userProfile == null || _userProfile!.isEmpty) {
        // fallback to prefs below
      }
    } catch (e) {
      // Fallback to SharedPreferences for offline or API failure
      final rawUsers = prefs.getString('all_users');
      if (rawUsers != null) {
        final allUsers = (json.decode(rawUsers) as List)
            .cast<Map<String, dynamic>>();
        _userProfile = allUsers.firstWhere(
          (user) => user['email'] == widget.userEmail,
          orElse: () => <String, dynamic>{},
        );
      }

      final rawFriends = prefs.getString('friends');
      if (rawFriends != null) {
        final friends = (json.decode(rawFriends) as List)
            .cast<Map<String, dynamic>>();
        _isFriend = friends.any(
          (friend) => friend['email'] == widget.userEmail,
        );
      }

      // Load additional profile data if available (bio, profile_image)
      final userBio = prefs.getString('${widget.userEmail}_bio');
      final userImage = prefs.getString('${widget.userEmail}_profile_image');
      final userPhone = prefs.getString('${widget.userEmail}_phone');

      if (_userProfile != null) {
        if (userBio != null) _userProfile!['bio'] = userBio;
        if (userImage != null) _userProfile!['profile_image'] = userImage;
        if (userPhone != null) _userProfile!['phone'] = userPhone;
      }
    }

    // Load gamification data
    _reputation = await ReputationSystem.getReputation();
    _badges = await BadgeSystem.getUserBadges();
    _privileges = await PrivilegeSystem.getUserPrivileges();

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _toggleFriend() async {
    final prefs = await SharedPreferences.getInstance();
    String message;

    try {
      // Try using API endpoints for friend management if available
      if (_isFriend) {
        await ApiService().delete(
          '${ApiConfig.removeFriend}/${widget.userEmail}',
        );
        setState(() => _isFriend = false);
        message = 'Removed from friends';
      } else {
        await ApiService().post(
          '${ApiConfig.addFriend}',
          data: {'email': widget.userEmail},
        );
        setState(() => _isFriend = true);
        message = 'Added to friends';
      }
      // refresh cached friends
      try {
        final fr = await ApiService().getFriends(page: 1, limit: 200);
        if (fr['friends'] is List) {
          await prefs.setString('friends', json.encode(fr['friends']));
        }
      } catch (_) {}
    } catch (e) {
      // Fallback to local persistence
      final rawFriends = prefs.getString('friends') ?? '[]';
      final friends = (json.decode(rawFriends) as List)
          .cast<Map<String, dynamic>>();

      if (_isFriend) {
        friends.removeWhere((friend) => friend['email'] == widget.userEmail);
        setState(() {
          _isFriend = false;
        });
        message = 'Removed from friends';
      } else {
        friends.add({'name': _userProfile!['name'], 'email': widget.userEmail});
        setState(() {
          _isFriend = true;
        });
        message = 'Added to friends';
      }

      await prefs.setString('friends', json.encode(friends));
    }

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  void _showProfileImageDialog(String base64Image, String userName) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text('$userName\'s Profile Picture'),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.white,
                          size: 48,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage() {
    final profileImage = _userProfile?['profile_image'];
    final userName = _userProfile?['name'] ?? 'User';

    if (profileImage != null && profileImage.isNotEmpty) {
      return GestureDetector(
        onTap: () => _showProfileImageDialog(profileImage, userName),
        child: Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF667eea), width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF667eea).withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.memory(
              base64Decode(profileImage),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFF667eea),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                    style: const TextStyle(fontSize: 40, color: Colors.white),
                  ),
                );
              },
            ),
          ),
        ),
      );
    } else {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF667eea),
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Center(
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
            style: const TextStyle(
              fontSize: 40,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
          title: const Text('Profile'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_userProfile == null || _userProfile!.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF667eea),
          foregroundColor: Colors.white,
          title: const Text('Profile'),
        ),
        body: const Center(child: Text('User not found')),
      );
    }

    final userName = _userProfile!['name'] ?? 'Unknown User';
    final userEmail = _userProfile!['email'] ?? '';
    final userBio = _userProfile!['bio'] ?? '';
    final userPhone = _userProfile!['phone'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF667eea),
        foregroundColor: Colors.white,
        title: Text(userName),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with gradient background
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  _buildProfileImage(),
                  const SizedBox(height: 16),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (userBio.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        userBio,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Friend action button
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _toggleFriend,
                      icon: Icon(
                        _isFriend ? Icons.person_remove : Icons.person_add,
                      ),
                      label: Text(_isFriend ? 'Remove Friend' : 'Add Friend'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFriend
                            ? Colors.red[400]
                            : Colors.white,
                        foregroundColor: _isFriend
                            ? Colors.white
                            : const Color(0xFF667eea),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            // Profile details section
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Contact Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoCard(
                    icon: Icons.email,
                    title: 'Email',
                    content: userEmail,
                  ),
                  if (userPhone.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      icon: Icons.phone,
                      title: 'Phone',
                      content: userPhone,
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Gamification section
                  const Text(
                    'Reputation & Achievements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Reputation card
                  _buildReputationCard(),

                  const SizedBox(height: 16),

                  // Badges section
                  if (_badges.isNotEmpty) ...[
                    const Text(
                      'Badges Earned',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildBadgesGrid(),
                    const SizedBox(height: 16),
                  ],

                  // Privileges section
                  if (_privileges.isNotEmpty) ...[
                    const Text(
                      'Privileges Unlocked',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildPrivilegesList(),
                    const SizedBox(height: 24),
                  ],

                  // Activity section (placeholder for future features)
                  const Text(
                    'Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatsCard(
                          'Questions',
                          '12',
                          Icons.help_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatsCard(
                          'Answers',
                          '8',
                          Icons.chat_bubble_outline,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatsCard(
                          'Reputation',
                          '45',
                          Icons.star_outline,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.timeline,
                            color: Color(0xFF667eea),
                            size: 24,
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Recent activity will appear here',
                              style: TextStyle(
                                color: Color(0xFF666666),
                                fontSize: 14,
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
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF667eea).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF667eea), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF999999),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF333333),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(String title, String count, IconData icon) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF667eea), size: 24),
            const SizedBox(height: 8),
            Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReputationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF667eea).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up,
              color: Color(0xFF667eea),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_reputation['reputation']}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF667eea),
                  ),
                ),
                const Text(
                  'Reputation Points',
                  style: TextStyle(fontSize: 14, color: Color(0xFF666666)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: _badges.length,
      itemBuilder: (context, index) {
        final badge = _badges[index];

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                spreadRadius: 1,
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                badge['icon'] as IconData,
                color: badge['color'] as Color,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                badge['name'] as String,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrivilegesList() {
    return Column(
      children: _privileges.map((privilege) {
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            children: [
              Icon(
                privilege['icon'] as IconData,
                color: Colors.green.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      privilege['name'] as String,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                      ),
                    ),
                    Text(
                      privilege['description'] as String,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
            ],
          ),
        );
      }).toList(),
    );
  }
}

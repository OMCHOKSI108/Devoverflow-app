import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'api_config.dart';

class AllFriendsScreen extends StatefulWidget {
  const AllFriendsScreen({super.key});

  @override
  State<AllFriendsScreen> createState() => _AllFriendsScreenState();
}

class _AllFriendsScreenState extends State<AllFriendsScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _filtered = [];
  final Set<String> _processing = {};
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      // Prefer API for fresh data
      final usersResp = await ApiService().getAllUsers(page: 1, limit: 200);
      List<dynamic> usersList = ApiService().extractList(usersResp, [
        'users',
        'data',
      ]);

      // Handle nested data structure: response.data.users
      if (usersList.isEmpty) {
        final data = usersResp['data'];
        if (data is Map<String, dynamic> && data['users'] is List) {
          usersList = data['users'] as List<dynamic>;
        }
      }

      _allUsers = usersList.cast<Map<String, dynamic>>();

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

      _friends = friendsList.cast<Map<String, dynamic>>();

      // cache to prefs for offline - store as plain lists for consumers
      await prefs.setString('all_users', json.encode(_allUsers));
      await prefs.setString('friends', json.encode(_friends));
    } catch (e) {
      // Fallback to local storage when API is unavailable
      final rawUsers = prefs.getString('all_users');
      final rawFriends = prefs.getString('friends');
      if (rawUsers != null) {
        _allUsers = (json.decode(rawUsers) as List)
            .cast<Map<String, dynamic>>();
      }
      if (rawFriends != null) {
        _friends = (json.decode(rawFriends) as List)
            .cast<Map<String, dynamic>>();
      }
    }
    _filtered = List.from(_allUsers);
    setState(() {});
  }

  bool _isFriend(String userId) => _friends.any((f) => f['_id'] == userId);

  Future<void> _toggleFriend(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = user['_id'] as String?;
    final email = user['email'] as String?;
    if (userId == null || email == null) return;

    if (_processing.contains(userId)) return; // already processing
    setState(() => _processing.add(userId));

    try {
      if (_isFriend(userId)) {
        // Call API to remove friend
        await ApiService().delete('${ApiConfig.removeFriend}/$userId');
        setState(() => _friends.removeWhere((f) => f['_id'] == userId));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Removed from friends')));
        }
      } else {
        // Call API to add friend
        await ApiService().post('${ApiConfig.addFriend}/$userId');
        setState(() => _friends.add(user));
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Added to friends')));
        }
      }

      // Refresh cached friends from API
      try {
        final fr = await ApiService().getFriends(page: 1, limit: 200);
        final refreshed = ApiService().extractList(fr, [
          'friends',
          'data',
        ]).cast<Map<String, dynamic>>();
        await prefs.setString('friends', json.encode(refreshed));
        _friends = refreshed;
        setState(() {});
      } catch (_) {
        // ignore refresh errors - local cache already updated above
      }
    } catch (e) {
      // Fallback to local persistence when API is unavailable
      final rawFriends = prefs.getString('friends') ?? '[]';
      final friends = (json.decode(rawFriends) as List)
          .cast<Map<String, dynamic>>();

      if (_isFriend(userId)) {
        friends.removeWhere((f) => f['_id'] == userId);
        setState(() {
          _friends.removeWhere((f) => f['_id'] == userId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Removed from friends (offline)')),
          );
        }
      } else {
        friends.add({
          '_id': userId,
          'name': user['name'] ?? '',
          'email': email,
        });
        setState(() {
          _friends.add({
            '_id': userId,
            'name': user['name'] ?? '',
            'email': email,
          });
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Added to friends (offline)')),
          );
        }
      }

      await prefs.setString('friends', json.encode(friends));
    }
    setState(() => _processing.remove(userId));
  }

  void _onSearch(String q) {
    final term = q.trim().toLowerCase();
    if (term.isEmpty) {
      _filtered = List.from(_allUsers);
    } else {
      _filtered = _allUsers.where((u) {
        return u['name'].toString().toLowerCase().contains(term) ||
            u['email'].toString().toLowerCase().contains(term);
      }).toList();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search users by name or email',
                border: OutlineInputBorder(),
              ),
              onChanged: _onSearch,
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('No users'))
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final u = _filtered[index];
                      final userEmail = (u['email'] ?? '').toString();
                      final userId = (u['_id'] ?? '').toString();
                      final isFriend = _isFriend(userId);
                      final isProcessing = _processing.contains(userId);
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.pushNamed(
                              context,
                              '/user_profile_view',
                              arguments: u['email'],
                            );
                          },
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF667eea),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 24,
                              backgroundColor: const Color(0xFF667eea),
                              child: Text(
                                ((u['name'] ?? '').toString().isNotEmpty
                                        ? (u['name'] ?? '').toString()[0]
                                        : '?')
                                    .toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            (u['name'] ?? '').toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            userEmail,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: isFriend
                                  ? Colors.red[50]
                                  : const Color.fromARGB(26, 102, 126, 234),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: isProcessing
                                  ? null
                                  : () => _toggleFriend(u),
                              icon: isProcessing
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    )
                                  : Icon(
                                      isFriend
                                          ? Icons.person_remove
                                          : Icons.person_add,
                                      size: 18,
                                    ),
                              label: Text(
                                isProcessing
                                    ? 'Processing'
                                    : (isFriend ? 'Remove' : 'Add'),
                                style: const TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isFriend
                                    ? Colors.red[400]
                                    : const Color(0xFF667eea),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

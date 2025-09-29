import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

class MyFriendsScreen extends StatefulWidget {
  const MyFriendsScreen({super.key});

  @override
  State<MyFriendsScreen> createState() => _MyFriendsScreenState();
}

class _MyFriendsScreenState extends State<MyFriendsScreen> {
  List<Map<String, dynamic>> _friends = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final resp = await ApiService().getFriends(page: 1, limit: 200);
      List<dynamic> friendsData = ApiService().extractList(resp, [
        'friends',
        'data',
      ]);

      // Handle nested data structure: response.data.friends
      if (friendsData.isEmpty) {
        final data = resp['data'];
        if (data is Map<String, dynamic> && data['friends'] is List) {
          friendsData = data['friends'] as List<dynamic>;
        }
      }

      _friends = friendsData
          .where((friend) => friend != null && friend is Map<String, dynamic>)
          .cast<Map<String, dynamic>>()
          .toList();
      // cache
      try {
        await prefs.setString('friends', json.encode(_friends));
      } catch (_) {}
      setState(() {});
    } catch (e) {
      final raw = prefs.getString('friends');
      if (raw != null) {
        final List decoded = json.decode(raw);
        setState(() {
          _friends = decoded.cast<Map<String, dynamic>>();
        });
      }
    }
  }

  Future<void> _removeFriend(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Friend'),
        content: const Text('Are you sure you want to remove this friend?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _friends.removeAt(index);
    });
    await prefs.setString('friends', json.encode(_friends));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Friends'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: _friends.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No friends yet',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start connecting with people!',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/allfriends');
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Find Friends'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final f = _friends[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    onTap: () {
                      final email = f['email'];
                      if (email != null) {
                        Navigator.pushNamed(
                          context,
                          '/user_profile_view',
                          arguments: email,
                        );
                      }
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
                          (f['name'] != null &&
                                  (f['name'] as String).isNotEmpty)
                              ? (f['name'] as String)[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      f['name'] ?? 'Unknown User',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      f['email'] ?? 'No email',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.person_remove,
                          color: Colors.red[400],
                          size: 20,
                        ),
                        onPressed: () => _removeFriend(index),
                        tooltip: 'Remove Friend',
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}

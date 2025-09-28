import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MyFriendsScreen extends StatefulWidget {
  const MyFriendsScreen({Key? key}) : super(key: key);

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
    final raw = prefs.getString('friends');
    if (raw != null) {
      final List decoded = json.decode(raw);
      setState(() {
        _friends = decoded.cast<Map<String, dynamic>>();
      });
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
          ? const Center(child: Text('No friends yet'))
          : ListView.builder(
              itemCount: _friends.length,
              itemBuilder: (context, index) {
                final f = _friends[index];
                return ListTile(
                  leading: CircleAvatar(child: Text(f['name'][0])),
                  title: Text(f['name']),
                  subtitle: Text(f['email'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () => _removeFriend(index),
                  ),
                );
              },
            ),
    );
  }
}

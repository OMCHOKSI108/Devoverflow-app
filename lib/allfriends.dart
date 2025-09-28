import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AllFriendsScreen extends StatefulWidget {
  const AllFriendsScreen({Key? key}) : super(key: key);

  @override
  State<AllFriendsScreen> createState() => _AllFriendsScreenState();
}

class _AllFriendsScreenState extends State<AllFriendsScreen> {
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _filtered = [];
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final rawUsers = prefs.getString('all_users');
    final rawFriends = prefs.getString('friends');
    if (rawUsers != null) {
      _allUsers = (json.decode(rawUsers) as List).cast<Map<String, dynamic>>();
    }
    if (rawFriends != null) {
      _friends = (json.decode(rawFriends) as List).cast<Map<String, dynamic>>();
    }
    _filtered = List.from(_allUsers);
    setState(() {});
  }

  bool _isFriend(String email) => _friends.any((f) => f['email'] == email);

  Future<void> _toggleFriend(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    if (_isFriend(user['email'])) {
      _friends.removeWhere((f) => f['email'] == user['email']);
    } else {
      _friends.add(user);
    }
    await prefs.setString('friends', json.encode(_friends));
    setState(() {});
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
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final u = _filtered[index];
                      final isFriend = _isFriend(u['email']);
                      return ListTile(
                        leading: CircleAvatar(child: Text(u['name'][0])),
                        title: Text(u['name']),
                        subtitle: Text(u['email']),
                        trailing: ElevatedButton(
                          onPressed: () => _toggleFriend(u),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFriend
                                ? Colors.red
                                : const Color(0xFF667eea),
                          ),
                          child: Text(isFriend ? 'Remove' : 'Add'),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  String _name = '';
  String? _imageBase64;
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _loadProfile();
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentUserEmail = prefs.getString('current_user_email');

      if (currentUserEmail != null) {
        // Prefer API for current user profile
        try {
          final resp = await ApiService().getCurrentUser();
          final user = resp['user'] ?? {};
          if (user is Map && user.isNotEmpty) {
            setState(() {
              _name = user['name'] ?? user['username'] ?? 'User';
              _imageBase64 =
                  user['profile_image'] ?? prefs.getString('profile_image');
            });
            return;
          }
        } catch (_) {
          // ignore and fallback to prefs
        }

        // Fallback to prefs (seeded data)
        String userName =
            prefs.getString('current_user_name') ??
            prefs.getString('name') ??
            '';

        if (userName.isEmpty) {
          final allUsersRaw = prefs.getString('all_users');
          if (allUsersRaw != null) {
            final allUsers = (json.decode(allUsersRaw) as List)
                .cast<Map<String, dynamic>>();
            final user = allUsers.firstWhere(
              (u) => u['email'] == currentUserEmail,
              orElse: () => {},
            );
            if (user.isNotEmpty) {
              userName = user['name'] ?? user['username'] ?? 'User';
            }
          }
        }

        setState(() {
          _name = userName.isEmpty ? 'User' : userName;
          _imageBase64 = prefs.getString('profile_image');
        });
      } else {
        setState(() {
          _name = 'User';
        });
      }
    } catch (_) {
      setState(() {
        _name = 'User';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? avatar;
    if (_imageBase64 != null) {
      try {
        avatar = MemoryImage(base64Decode(_imageBase64!));
      } catch (_) {
        avatar = null;
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(
                16,
                MediaQuery.of(context).padding.top + 16,
                16,
                20,
              ),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: avatar,
                    backgroundColor: Colors.white24,
                    child: avatar == null
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 6),
                        const Text('', style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              onTap: () => Navigator.pushNamed(context, '/notifications'),
            ),
            ListTile(
              leading: const Icon(Icons.bookmark),
              title: const Text('Bookmarks'),
              onTap: () => Navigator.pushNamed(context, '/bookmarks'),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Advanced Search'),
              onTap: () => Navigator.pushNamed(context, '/search'),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profile'),
              onTap: () => Navigator.pushNamed(context, '/profile'),
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('My Friends'),
              onTap: () => Navigator.pushNamed(context, '/myfriends'),
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('All Friends'),
              onTap: () => Navigator.pushNamed(context, '/allfriends'),
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('AI ChatBot'),
              onTap: () => Navigator.pushNamed(context, '/aichatbot'),
            ),
            ListTile(
              leading: const Icon(Icons.account_tree),
              title: const Text('AI Flowchart'),
              onTap: () => Navigator.pushNamed(context, '/flowchart'),
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('Group Lobby'),
              onTap: () => Navigator.pushNamed(context, '/groups'),
            ),
            // Groups entry removed from drawer (accessible via Quick Actions)
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.of(context).padding.top + 20,
                  20,
                  20,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundImage: avatar,
                      backgroundColor: Colors.white24,
                      child: avatar == null
                          ? const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello $_name',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Find solutions, share knowledge',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/questions'),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Open Questions'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF667eea),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('See All', style: TextStyle(color: Colors.blueAccent)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.search,
                          color: Color(0xFF667eea),
                        ),
                        title: const Text('Advanced Search'),
                        subtitle: const Text('Find questions with filters'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(context, '/search'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.bookmark,
                          color: Color(0xFF667eea),
                        ),
                        title: const Text('Bookmarks'),
                        subtitle: const Text('Saved problems and links'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(context, '/bookmarks'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.group,
                          color: Color(0xFF667eea),
                        ),
                        title: const Text('Community'),
                        subtitle: const Text('See and manage friends'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            Navigator.pushNamed(context, '/allfriends'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.smart_toy,
                          color: Color(0xFF667eea),
                        ),
                        title: const Text('AI Chat'),
                        subtitle: const Text('Ask the assistant for help'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(context, '/aichatbot'),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.account_tree,
                          color: Color(0xFF667eea),
                        ),
                        title: const Text('AI Flowchart'),
                        subtitle: const Text('Generate flowcharts with AI'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(context, '/flowchart'),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.smart_toy,
                          color: Color(0xFF667eea),
                        ),
                        title: const Text('Group Lobby'),
                        subtitle: const Text('Group discussion'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pushNamed(context, '/groups'),
                      ),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/bookmarks'),
              icon: const Icon(Icons.bookmark),
              color: const Color(0xFF667eea),
              tooltip: 'Bookmarks',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/search'),
              icon: const Icon(Icons.search),
              color: const Color(0xFF667eea),
              tooltip: 'Search',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/myfriends'),
              icon: const Icon(Icons.person),
              color: const Color(0xFF667eea),
              tooltip: 'My Friends',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/allfriends'),
              icon: const Icon(Icons.group),
              color: const Color(0xFF667eea),
              tooltip: 'All Friends',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/aichatbot'),
              icon: const Icon(Icons.smart_toy),
              color: const Color(0xFF667eea),
              tooltip: 'AI ChatBot',
            ),
            IconButton(
              onPressed: () => Navigator.pushNamed(context, '/flowchart'),
              icon: const Icon(Icons.account_tree),
              color: const Color(0xFF667eea),
              tooltip: 'AI Flowchart',
            ),
          ],
        ),
      ),
    );
  }
}

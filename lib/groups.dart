import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

// Simple group model
class Group {
  final String id;
  final String name;
  final String description;

  Group({required this.id, required this.name, required this.description});

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
  };

  static Group fromJson(Map<String, dynamic> j) =>
      Group(id: j['id'], name: j['name'], description: j['description']);
}

// Question model for group Q&A
class GroupQuestion {
  final String id;
  final String title;
  final String body;
  final String author;
  final DateTime createdAt;
  int votes;

  GroupQuestion({
    required this.id,
    required this.title,
    required this.body,
    required this.author,
    DateTime? createdAt,
    this.votes = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'author': author,
    'createdAt': createdAt.toIso8601String(),
    'votes': votes,
  };

  static GroupQuestion fromJson(Map<String, dynamic> j) => GroupQuestion(
    id: j['id'],
    title: j['title'],
    body: j['body'],
    author: j['author'],
    createdAt: DateTime.parse(j['createdAt']),
    votes: j['votes'] ?? 0,
  );
}

// Discussion thread message
class DiscussionMessage {
  final String id;
  final String author;
  final String text;
  final DateTime createdAt;

  DiscussionMessage({
    required this.id,
    required this.author,
    required this.text,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'author': author,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
  };

  static DiscussionMessage fromJson(Map<String, dynamic> j) =>
      DiscussionMessage(
        id: j['id'],
        author: j['author'],
        text: j['text'],
        createdAt: DateTime.parse(j['createdAt']),
      );
}

// Main Groups screen: list and create groups
class GroupListScreen extends StatefulWidget {
  const GroupListScreen({super.key});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  List<Group> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService().getAllGroups();
      List<dynamic> list = ApiService().extractList(response, [
        'groups',
        'data',
      ]);

      // Handle nested data structure: response.data.groups
      if (list.isEmpty) {
        final data = response['data'];
        if (data is Map<String, dynamic> && data['groups'] is List) {
          list = data['groups'] as List<dynamic>;
        }
      }
      final parsed = list.map((g) => g as Map<String, dynamic>).map((g) {
        final id =
            g['id'] ??
            g['_id'] ??
            g['name']?.toString().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
        return Group.fromJson({
          'id': id.toString(),
          'name': g['name'] ?? g['title'] ?? 'Unnamed',
          'description': g['description'] ?? '',
        });
      }).toList();

      setState(() {
        _groups = parsed;
      });

      // Cache groups to prefs for offline fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'groups',
          json.encode(_groups.map((g) => g.toJson()).toList()),
        );
      } catch (_) {}
    } catch (e) {
      // Fallback to local storage on error
      await _loadGroupsFromLocal();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadGroupsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey('groups')) {
      final defaultGroups = [
        Group(id: 'aiml', name: 'AIML', description: 'AI & Machine Learning'),
      ];
      await prefs.setString(
        'groups',
        json.encode(defaultGroups.map((g) => g.toJson()).toList()),
      );
    }
    final raw = prefs.getString('groups')!;
    final list = json.decode(raw) as List;
    setState(() {
      _groups = list.map((e) => Group.fromJson(e)).toList();
    });
  }

  Future<void> _createGroup() async {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Create Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Group name'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final response = await ApiService().createGroup(
        nameCtrl.text.trim(),
        descCtrl.text.trim(),
      );

      if (response['success'] == true) {
        // Reload groups to get the updated list
        await _loadGroups();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Group created successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to create group'),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback to local creation if API fails
      final id = nameCtrl.text.trim().toLowerCase().replaceAll(
        RegExp(r'\s+'),
        '_',
      );
      final g = Group(
        id: id,
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim(),
      );
      _groups.add(g);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'groups',
        json.encode(_groups.map((e) => e.toJson()).toList()),
      );
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group created locally (offline mode)')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
            )
          : _groups.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.group_off, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No groups yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first group to get started!',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _groups.length,
              itemBuilder: (c, i) {
                final g = _groups[i];
                return ListTile(
                  leading: CircleAvatar(child: Text(g.name[0])),
                  title: Text(g.name),
                  subtitle: Text(g.description),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => GroupDetailScreen(group: g),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF667eea),
        onPressed: _createGroup,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Group detail: tabs for Questions and Discussions
class GroupDetailScreen extends StatefulWidget {
  final Group group;
  const GroupDetailScreen({super.key, required this.group});

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GroupQuestion> _questions = [];
  List<DiscussionMessage> _messages = [];
  bool _isLoadingQuestions = true;
  bool _isLoadingMessages = true;
  bool _isMember = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingQuestions = true;
      _isLoadingMessages = true;
    });

    // Load group details and membership status
    try {
      final groupResponse = await ApiService().getGroupDetails(widget.group.id);
      if (groupResponse['success'] == true) {
        final groupData = groupResponse['group'];
        setState(() => _isMember = groupData['isMember'] ?? false);
      }
    } catch (e) {
      // Group details failed, continue with local data
    }

    // Load questions
    try {
      final questionsResponse = await ApiService().getGroupQuestions(
        widget.group.id,
      );
      if (questionsResponse['success'] == true) {
        final questionsData = questionsResponse['questions'] as List? ?? [];
        setState(() {
          _questions = questionsData
              .map((q) => GroupQuestion.fromJson(q as Map<String, dynamic>))
              .toList();
        });
      } else {
        // Fallback to local questions
        await _loadQuestionsFromLocal();
      }
    } catch (e) {
      // Fallback to local questions on error
      await _loadQuestionsFromLocal();
    } finally {
      setState(() => _isLoadingQuestions = false);
    }

    // Load discussions (for now, keep local since API might not have this endpoint)
    await _loadMessagesFromLocal();
    setState(() => _isLoadingMessages = false);
  }

  Future<void> _loadQuestionsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final qKey = 'group_${widget.group.id}_questions';
    if (prefs.containsKey(qKey)) {
      final qRaw = prefs.getString(qKey)!;
      final qList = json.decode(qRaw) as List;
      _questions = qList.map((e) => GroupQuestion.fromJson(e)).toList();
    }
  }

  Future<void> _loadMessagesFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final dKey = 'group_${widget.group.id}_discussions';
    if (prefs.containsKey(dKey)) {
      final dRaw = prefs.getString(dKey)!;
      final dList = json.decode(dRaw) as List;
      _messages = dList.map((e) => DiscussionMessage.fromJson(e)).toList();
    }
  }

  Future<void> _postQuestion() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Post Question'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: bodyCtrl,
              decoration: const InputDecoration(labelText: 'Details'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(c).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(c).pop(true),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      final response = await ApiService().postGroupQuestion(
        widget.group.id,
        titleCtrl.text.trim(),
        bodyCtrl.text.trim(),
      );

      if (response['success'] == true) {
        // Reload questions to get the updated list
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question posted successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to post question'),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback to local posting if API fails
      final q = GroupQuestion(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: titleCtrl.text.trim(),
        body: bodyCtrl.text.trim(),
        author: 'You',
      );
      _questions.insert(0, q);
      final prefs = await SharedPreferences.getInstance();
      final qKey = 'group_${widget.group.id}_questions';
      await prefs.setString(
        qKey,
        json.encode(_questions.map((e) => e.toJson()).toList()),
      );
      setState(() {});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question posted locally (offline mode)'),
          ),
        );
      }
    }
  }

  Future<void> _joinGroup() async {
    try {
      final response = await ApiService().joinGroup(widget.group.id);

      if (response['success'] == true) {
        setState(() => _isMember = true);
        // Reload data to get updated member count
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined group successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to join group'),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback to local join if API fails
      setState(() => _isMember = true);
      final prefs = await SharedPreferences.getInstance();
      final mKey = 'group_${widget.group.id}_member';
      await prefs.setBool(mKey, true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Joined group locally (offline mode)')),
        );
      }
    }
  }

  Future<void> _leaveGroup() async {
    try {
      final response = await ApiService().leaveGroup(widget.group.id);

      if (response['success'] == true) {
        setState(() => _isMember = false);
        // Reload data to get updated member count
        await _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Left group successfully!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to leave group'),
            ),
          );
        }
      }
    } catch (e) {
      // Fallback to local leave if API fails
      setState(() => _isMember = false);
      final prefs = await SharedPreferences.getInstance();
      final mKey = 'group_${widget.group.id}_member';
      await prefs.setBool(mKey, false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Left group locally (offline mode)')),
        );
      }
    }
  }

  Future<void> _postMessage(String text) async {
    final m = DiscussionMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      author: 'You',
      text: text,
    );
    _messages.add(m);
    final prefs = await SharedPreferences.getInstance();
    final dKey = 'group_${widget.group.id}_discussions';
    await prefs.setString(
      dKey,
      json.encode(_messages.map((e) => e.toJson()).toList()),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.group.name),
        backgroundColor: const Color(0xFF667eea),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Questions'),
            Tab(text: 'Discussions'),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton(
              onPressed: _isMember ? _leaveGroup : _joinGroup,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isMember ? Colors.red : Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(_isMember ? 'Leave Group' : 'Join Group'),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Questions tab
          Column(
            children: [
              if (_isLoadingQuestions)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF667eea),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: _questions.isEmpty
                      ? const Center(child: Text('No questions yet'))
                      : ListView.builder(
                          itemCount: _questions.length,
                          itemBuilder: (c, i) {
                            final q = _questions[i];
                            return Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: ListTile(
                                title: Text(q.title),
                                subtitle: Text(q.body),
                                trailing: Text('${q.votes} votes'),
                              ),
                            );
                          },
                        ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _postQuestion,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF667eea),
                        ),
                        child: const Text('Post Question'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Discussions tab
          Column(
            children: [
              if (_isLoadingMessages)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF667eea),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: _messages.isEmpty
                      ? const Center(child: Text('No messages yet'))
                      : ListView.builder(
                          itemCount: _messages.length,
                          itemBuilder: (c, i) {
                            final m = _messages[i];
                            return ListTile(
                              title: Text(m.author),
                              subtitle: Text(m.text),
                              trailing: Text(
                                '${m.createdAt.hour}:${m.createdAt.minute.toString().padLeft(2, '0')}',
                              ),
                            );
                          },
                        ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'Write a message...',
                        ),
                        onSubmitted: (v) {
                          if (v.trim().isEmpty) return;
                          _postMessage(v.trim());
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

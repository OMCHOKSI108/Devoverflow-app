import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  const GroupListScreen({Key? key}) : super(key: key);

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  List<Group> _groups = [];

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Groups'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: ListView.builder(
        itemCount: _groups.length,
        itemBuilder: (c, i) {
          final g = _groups[i];
          return ListTile(
            leading: CircleAvatar(child: Text(g.name[0])),
            title: Text(g.name),
            subtitle: Text(g.description),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => GroupDetailScreen(group: g)),
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
  const GroupDetailScreen({Key? key, required this.group}) : super(key: key);

  @override
  State<GroupDetailScreen> createState() => _GroupDetailScreenState();
}

class _GroupDetailScreenState extends State<GroupDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<GroupQuestion> _questions = [];
  List<DiscussionMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final qKey = 'group_${widget.group.id}_questions';
    final dKey = 'group_${widget.group.id}_discussions';
    if (prefs.containsKey(qKey)) {
      final qRaw = prefs.getString(qKey)!;
      final qList = json.decode(qRaw) as List;
      _questions = qList.map((e) => GroupQuestion.fromJson(e)).toList();
    }
    if (prefs.containsKey(dKey)) {
      final dRaw = prefs.getString(dKey)!;
      final dList = json.decode(dRaw) as List;
      _messages = dList.map((e) => DiscussionMessage.fromJson(e)).toList();
    }
    setState(() {});
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
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Questions tab
          Column(
            children: [
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

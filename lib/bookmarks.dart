import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({Key? key}) : super(key: key);

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Map<String, dynamic>> _bookmarks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('bookmarks');
    if (raw != null) {
      _bookmarks = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      setState(() {});
    }
  }

  Future<void> _removeBookmark(int index) async {
    final prefs = await SharedPreferences.getInstance();
    _bookmarks.removeAt(index);
    await prefs.setString('bookmarks', json.encode(_bookmarks));
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: _bookmarks.isEmpty
          ? const Center(child: Text('No bookmarks yet'))
          : ListView.builder(
              itemCount: _bookmarks.length,
              itemBuilder: (context, index) {
                final b = _bookmarks[index];
                return ListTile(
                  title: Text(b['title'] ?? ''),
                  subtitle: Text(b['excerpt'] ?? ''),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _removeBookmark(index),
                  ),
                  onTap: () {
                    // open link externally later
                  },
                );
              },
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'api_config.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  List<Map<String, dynamic>> _bookmarks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    try {
      final response = await ApiService().get(ApiConfig.getBookmarks);

      List<dynamic> list = ApiService().extractList(response, [
        'bookmarks',
        'data',
      ]);

      // Handle nested data structure: response.data.bookmarks
      if (list.isEmpty) {
        final data = response['data'];
        if (data is Map<String, dynamic> && data['bookmarks'] is List) {
          list = data['bookmarks'] as List<dynamic>;
        }
      }

      _bookmarks = list.cast<Map<String, dynamic>>();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('bookmarks', json.encode(_bookmarks));
      } catch (_) {}
    } catch (e) {
      // If API fails, try to load from local storage as fallback
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('bookmarks');
      if (raw != null) {
        _bookmarks = (json.decode(raw) as List).cast<Map<String, dynamic>>();
      } else {
        _bookmarks = [];
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _removeBookmark(int index) async {
    final bookmark = _bookmarks[index];

    try {
      await ApiService().delete('${ApiConfig.deleteBookmark}${bookmark['id']}');

      setState(() {
        _bookmarks.removeAt(index);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Bookmark removed')));
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to remove bookmark';
        if (e is ApiException) {
          errorMessage = e.message;
        } else if (e.toString().contains('SocketException')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookmarks.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No bookmarks yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Bookmark questions to read them later',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _bookmarks.length,
              itemBuilder: (context, index) {
                final b = _bookmarks[index];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    title: Text(
                      b['title'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2c3e50),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          b['excerpt'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF34495e),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              'by ${b['author'] ?? 'Unknown'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.thumb_up, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              '${b['votes'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.visibility,
                              size: 14,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${b['views'] ?? 0}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        if (b['tags'] != null &&
                            (b['tags'] as List).isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: List<Widget>.from(
                              (b['tags'] as List).map(
                                (t) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF667eea,
                                    ).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    t,
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Color(0xFF667eea),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeBookmark(index),
                      tooltip: 'Remove bookmark',
                    ),
                    onTap: () {
                      // TODO: Navigate to question detail
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Question detail view coming soon!'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}

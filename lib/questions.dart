import 'package:flutter/material.dart';
import 'question_detail.dart';
import 'api_service.dart';
import 'api_config.dart';

class QuestionsScreen extends StatefulWidget {
  const QuestionsScreen({super.key});

  @override
  State<QuestionsScreen> createState() => _QuestionsScreenState();
}

class _QuestionsScreenState extends State<QuestionsScreen> {
  List<Map<String, dynamic>> _questions = [];
  List<Map<String, dynamic>> _bookmarks = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _currentPage = 1;
  bool _hasNextPage = true;
  final int _limit = 20;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadQuestions();
    _loadBookmarks();
  }

  Future<void> _loadQuestions({bool loadMore = false}) async {
    if (loadMore && (!_hasNextPage || _isLoadingMore)) return;

    setState(() {
      if (loadMore) {
        _isLoadingMore = true;
      } else {
        _isLoading = true;
        _currentPage = 1;
        _questions.clear();
      }
    });

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage.toString(),
        'limit': _limit.toString(),
        'sortBy': 'newest',
      };

      final response = await ApiService().get(
        ApiConfig.getAllQuestions,
        queryParams: queryParams,
        includeAuth: false, // Public endpoint
      );

      // Debug: Print the raw response and base URL used
      print('Questions API Response: $response');
      print('Using base URL: ${ApiConfig.baseUrl}');

      // Be tolerant of different backend response shapes. The API may return:
      // - { success: true, questions: [...] }
      // - { success: true, data: { questions: [...] } }
      // - { data: [...] } or directly a List
      List<dynamic> questionsData = ApiService().extractList(response, [
        'questions',
        'data',
        'items',
      ]);

      // Try common alternative paths if extractList returned empty
      if (questionsData.isEmpty) {
        if (response is List) {
          questionsData = response;
        } else if (response is Map<String, dynamic>) {
          // If there's a top-level 'data' object that is a Map with 'questions'
          final data = response['data'];
          if (data is Map<String, dynamic> && data['questions'] is List) {
            questionsData = data['questions'] as List<dynamic>;
          }
        }
      }

      print('Normalized questions data: $questionsData');
      print('Questions count: ${questionsData.length}');

      final newQuestions = questionsData
          .map((q) => q as Map<String, dynamic>)
          .toList();

      print('Successfully parsed ${newQuestions.length} questions');

      // Pagination: try several common locations
      Map<String, dynamic> pagination = {};
      if (response is Map<String, dynamic>) {
        if (response['pagination'] is Map<String, dynamic>) {
          pagination = response['pagination'] as Map<String, dynamic>;
        } else if (response['meta'] is Map<String, dynamic>) {
          pagination = response['meta'] as Map<String, dynamic>;
        } else if (response['data'] is Map<String, dynamic>) {
          final data = response['data'] as Map<String, dynamic>;
          if (data['pagination'] is Map<String, dynamic>) {
            pagination = data['pagination'] as Map<String, dynamic>;
          } else if (data['meta'] is Map<String, dynamic>) {
            pagination = data['meta'] as Map<String, dynamic>;
          }
        }
      }

      setState(() {
        if (loadMore) {
          _questions.addAll(newQuestions);
          _currentPage++;
        } else {
          _questions = newQuestions;
          _errorMessage = null; // Clear any previous error
        }

        print('UI updated: now showing ${_questions.length} questions');

        // If the backend provides hasNextPage, use it; otherwise infer by page size
        _hasNextPage =
            pagination['hasNextPage'] ??
            pagination['has_next'] ??
            (newQuestions.length == _limit);
      });
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to load questions';
        if (e is ApiException) {
          errorMessage = e.message;
        } else if (e.toString().contains('SocketException')) {
          errorMessage = 'Network error. Please check your connection.';
        }

        setState(() {
          _errorMessage = errorMessage;
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    } finally {
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadBookmarks() async {
    try {
      final response = await ApiService().get(ApiConfig.getBookmarks);

      if (response['success'] == true) {
        final bookmarksData = response['bookmarks'] as List? ?? [];
        _bookmarks = bookmarksData
            .map((b) => b as Map<String, dynamic>)
            .toList();
      } else {
        _bookmarks = [];
      }
    } catch (e) {
      // If API fails, keep bookmarks empty
      _bookmarks = [];
    }
    setState(() {}); // Refresh to update bookmark icons
  }

  void _showAskQuestionDialog() {
    showDialog(
      context: context,
      builder: (context) => const AskQuestionDialog(),
    ).then((result) {
      if (result != null) {
        _addNewQuestion(result);
      }
    });
  }

  Future<void> _addNewQuestion(Map<String, dynamic> question) async {
    try {
      final requestData = {
        'title': question['title'],
        'body': question['body'],
        'tags': question['tags'] ?? [],
      };

      final response = await ApiService().post(
        ApiConfig.createQuestion,
        data: requestData,
      );

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question posted successfully!')),
          );

          // If the API returns the created question, add it to the top of the list immediately
          if (response['question'] != null || response['data'] != null) {
            final newQuestion = response['question'] ?? response['data'];
            if (newQuestion is Map<String, dynamic>) {
              setState(() {
                _questions.insert(0, newQuestion); // Add to top of list
              });
            } else {
              // Fallback: refresh the entire list
              await _loadQuestions();
            }
          } else {
            // Fallback: refresh the entire list
            await _loadQuestions();
          }
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to post question');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to post question';
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

  Future<void> _bookmarkQuestion(Map<String, dynamic> question) async {
    try {
      // Check if already bookmarked
      final isBookmarked = _bookmarks.any((b) => b['_id'] == question['_id']);

      if (isBookmarked) {
        // Remove bookmark
        await ApiService().delete(
          '${ApiConfig.removeQuestionBookmark}${question['_id']}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Question removed from bookmarks')),
          );
        }
      } else {
        // Add bookmark
        await ApiService().post(
          '${ApiConfig.addQuestionBookmark}${question['_id']}',
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Question bookmarked!')));
        }
      }

      await _loadBookmarks(); // Refresh bookmark status
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to update bookmark';
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
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Questions'),
          backgroundColor: const Color(0xFF667eea),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Questions'),
        backgroundColor: const Color(0xFF667eea),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Implement search
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filtering
            },
          ),
        ],
      ),
      body: _errorMessage != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 80, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to load questions',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _errorMessage = null;
                        _isLoading = true;
                      });
                      _loadQuestions();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            )
          : _questions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.question_answer, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No questions yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Be the first to ask a question!',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _errorMessage = null; // Clear error on refresh
                });
                await _loadQuestions();
                await _loadBookmarks();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  return QuestionCard(
                    question: q,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              QuestionDetailScreen(question: q),
                        ),
                      );
                    },
                    onBookmark: () => _bookmarkQuestion(q),
                    isBookmarked: _bookmarks.any((b) => b['_id'] == q['_id']),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAskQuestionDialog,
        backgroundColor: const Color(0xFF667eea),
        icon: const Icon(Icons.add),
        label: const Text('Ask Question'),
      ),
    );
  }
}

class QuestionCard extends StatelessWidget {
  final Map<String, dynamic> question;
  final VoidCallback onTap;
  final VoidCallback? onBookmark;
  final bool isBookmarked;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onTap,
    this.onBookmark,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    final isAnswered = question['isAnswered'] ?? false;
    final topAnswer = question['topAnswer'];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isAnswered ? Colors.green.shade200 : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with votes and status
              Row(
                children: [
                  // Vote count
                  Column(
                    children: [
                      Text(
                        '${question['votes'] ?? 0}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: (question['votes'] ?? 0) > 0
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
                      const Text(
                        'votes',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),

                  // Answer count with status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isAnswered
                          ? Colors.green.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${(question['answers'] as List<dynamic>? ?? []).length}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isAnswered
                                ? Colors.green.shade800
                                : Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'answers',
                          style: TextStyle(
                            fontSize: 12,
                            color: isAnswered
                                ? Colors.green.shade800
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Views and comments
                  Row(
                    children: [
                      Icon(Icons.comment, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${(question['comments'] as List<dynamic>? ?? []).length}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: Icon(
                          isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                          size: 16,
                          color: isBookmarked
                              ? const Color(0xFF667eea)
                              : Colors.grey,
                        ),
                        onPressed: onBookmark,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        tooltip: isBookmarked
                            ? 'Remove bookmark'
                            : 'Bookmark question',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Question title
              Text(
                question['title'] ?? 'Untitled Question',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2c3e50),
                ),
              ),

              const SizedBox(height: 8),

              // Question excerpt (using body field from API)
              Text(
                question['body'] ?? 'No description available',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF34495e),
                  height: 1.4,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),

              // Tags
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: List<Widget>.from(
                  (question['tags'] as List<dynamic>? ?? []).map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF667eea).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        t?.toString() ?? 'tag',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF667eea),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Top answer preview (if answered)
              if (isAnswered && topAnswer != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accepted Answer',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              topAnswer,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF2c3e50),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Footer with author and timestamp
              Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: const Color(0xFF667eea),
                    child: Text(
                      (question['user']?['username'] as String? ?? 'A')[0]
                          .toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'asked by ${question['user']?['username'] ?? 'Anonymous'}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    _formatTimestamp(question['createdAt'] ?? ''),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'just now';
      }
    } catch (e) {
      return 'recently';
    }
  }
}

class AskQuestionDialog extends StatefulWidget {
  const AskQuestionDialog({super.key});

  @override
  State<AskQuestionDialog> createState() => _AskQuestionDialogState();
}

class _AskQuestionDialogState extends State<AskQuestionDialog> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  void _submitQuestion() {
    if (_formKey.currentState!.validate()) {
      final tags = _tagsCtrl.text
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();

      final question = {
        'title': _titleCtrl.text.trim(),
        'body': _bodyCtrl.text.trim(),
        'tags': tags,
      };

      Navigator.of(context).pop(question);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.question_answer, color: Color(0xFF667eea)),
                  const SizedBox(width: 12),
                  const Text(
                    'Ask a Question',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Title field
              const Text(
                'Title',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  hintText: 'What is your question?',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a question title';
                  }
                  if (value.length < 10) {
                    return 'Title should be at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Body field
              const Text(
                'Details',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _bodyCtrl,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Provide more details about your question...',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide question details';
                  }
                  if (value.length < 20) {
                    return 'Please provide more details (at least 20 characters)';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Tags field
              const Text(
                'Tags',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tagsCtrl,
                decoration: const InputDecoration(
                  hintText: 'flutter, dart, state-management (comma separated)',
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please add at least one tag';
                  }
                  final tags = value
                      .split(',')
                      .map((tag) => tag.trim())
                      .where((tag) => tag.isNotEmpty);
                  if (tags.isEmpty) {
                    return 'Please add at least one tag';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 32),

              // Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _submitQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Post Question'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

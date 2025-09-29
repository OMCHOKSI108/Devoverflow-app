import 'package:flutter/material.dart';
import 'api_service.dart';
import 'api_config.dart';
import 'rich_text_content.dart';

class QuestionDetailScreen extends StatefulWidget {
  final Map<String, dynamic> question;
  const QuestionDetailScreen({super.key, required this.question});

  @override
  State<QuestionDetailScreen> createState() => _QuestionDetailScreenState();
}

class _QuestionDetailScreenState extends State<QuestionDetailScreen> {
  final _commentCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  List<Map<String, dynamic>> _answers = [];

  @override
  void initState() {
    super.initState();
    _loadAnswers();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAnswers() async {
    // setState(() => _isLoadingAnswers = true);

    try {
      final questionId = widget.question['_id'];
      if (questionId == null) {
        print('Error: Question ID is null');
        return;
      }

      final response = await ApiService().get(
        '${ApiConfig.getSingleQuestion}$questionId',
      );

      if (response['success'] == true) {
        Map<String, dynamic> questionData = {};

        // Handle different response structures
        if (response['question'] is Map<String, dynamic>) {
          questionData = response['question'] as Map<String, dynamic>;
        } else if (response['data'] is Map<String, dynamic>) {
          final data = response['data'] as Map<String, dynamic>;
          if (data['question'] is Map<String, dynamic>) {
            questionData = data['question'] as Map<String, dynamic>;
          }
        }

        List<dynamic> answersData = [];
        if (questionData['answers'] is List) {
          answersData = questionData['answers'] as List<dynamic>;
        }

        setState(() {
          _answers = answersData
              .map((answer) => answer as Map<String, dynamic>)
              .toList();
        });
      } else {
        // Fallback to the answers passed with the question
        _answers = (widget.question['answers'] as List<dynamic>? ?? []).map((
          answer,
        ) {
          return {
            'id': answer['id'] ?? DateTime.now().millisecondsSinceEpoch,
            'body': answer['body'] ?? '',
            'author': answer['author'] ?? 'Unknown',
            'votes': answer['votes'] ?? 0,
            'timestamp': answer['timestamp'] ?? DateTime.now().toString(),
            'isAccepted': answer['isAccepted'] ?? false,
          };
        }).toList();
      }
    } catch (e) {
      // If API fails, use the answers from the question object
      _answers = (widget.question['answers'] as List<dynamic>? ?? []).map((
        answer,
      ) {
        return {
          'id': answer['id'] ?? DateTime.now().millisecondsSinceEpoch,
          'body': answer['body'] ?? '',
          'author': answer['author'] ?? 'Unknown',
          'votes': answer['votes'] ?? 0,
          'timestamp': answer['timestamp'] ?? DateTime.now().toString(),
          'isAccepted': answer['isAccepted'] ?? false,
        };
      }).toList();
    } finally {
      // setState(() => _isLoadingAnswers = false);
    }
  }

  void _addComment() {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;
    // TODO: Implement comment posting to API
    setState(() {
      // For now, just clear the field
      _commentCtrl.clear();
    });
  }

  void _addAnswer() async {
    final text = _answerCtrl.text.trim();
    if (text.isEmpty) return;

    final questionId = widget.question['_id'];
    if (questionId == null) {
      print('Error: Cannot add answer to question with null ID');
      return;
    }

    try {
      final response = await ApiService().post(
        '${ApiConfig.postAnswer}$questionId',
        data: {'body': text},
      );

      if (response['success'] == true) {
        setState(() {
          _answerCtrl.clear();
        });

        // Reload answers to get the new one
        await _loadAnswers();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Answer posted successfully!')),
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to post answer');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to post answer';
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

  Future<void> _voteOnQuestion(bool isUpvote) async {
    final questionId = widget.question['_id'];
    if (questionId == null) {
      print('Error: Cannot vote on question with null ID');
      return;
    }

    try {
      final response = await ApiService().post(
        '${ApiConfig.voteOnQuestion}$questionId/vote',
        data: {'voteType': isUpvote ? 'up' : 'down'},
      );

      if (response['success'] == true) {
        // Update the question votes in the local state
        setState(() {
          widget.question['votes'] =
              (widget.question['votes'] ?? 0) + (isUpvote ? 1 : -1);
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to vote on question');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to vote on question';
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

  Future<void> _voteOnAnswer(String answerId, bool isUpvote) async {
    if (answerId.isEmpty) {
      print('Error: Cannot vote on answer with empty ID');
      return;
    }

    try {
      final response = await ApiService().post(
        '${ApiConfig.voteOnAnswer}$answerId/vote',
        data: {'voteType': isUpvote ? 'up' : 'down'},
      );

      if (response['success'] == true) {
        // Update the answer votes in the local state
        setState(() {
          final answerIndex = _answers.indexWhere((a) => a['_id'] == answerId);
          if (answerIndex != -1) {
            _answers[answerIndex]['votes'] =
                (_answers[answerIndex]['votes'] ?? 0) + (isUpvote ? 1 : -1);
          }
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to vote on answer');
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to vote on answer';
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
    final q = widget.question;

    // Debug: Print question data
    print('Question data: $q');
    print('Question ID: ${q['_id']}');
    print('Question title: ${q['title']}');

    return Scaffold(
      appBar: AppBar(
        title: Text(q['title'] ?? 'Question'),
        backgroundColor: const Color(0xFF667eea),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Question header
              Row(
                children: [
                  Column(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.thumb_up, size: 16),
                        onPressed: () => _voteOnQuestion(true),
                        color: Colors.grey.shade400,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      Text(
                        '${q['votes'] ?? 0}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.thumb_down, size: 16),
                        onPressed: () => _voteOnQuestion(false),
                        color: Colors.grey.shade400,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const Text(
                        'votes',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          q['title'] ?? 'Untitled Question',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        RichTextContent(
                          content:
                              q['body']?.toString() ??
                              'No description available',
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          children: List<Widget>.from(
                            ((q['tags'] is List) ? q['tags'] as List : []).map(
                              (t) => Chip(label: Text(t?.toString() ?? 'tag')),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      Text(
                        '${_answers.length}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Text(
                        'answers',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 32),
              // Comments section (placeholder)
              const Text(
                'Comments',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Comments feature coming soon!',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(),
                      ),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _addComment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667eea),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Post'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Answers section
              Row(
                children: [
                  Text(
                    'Answers (${_answers.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  if (_answers.isNotEmpty) ...[
                    Text(
                      '${_answers.where((a) => a['isAccepted'] == true).length} accepted',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Post answer section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Answer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF667eea),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _answerCtrl,
                        decoration: InputDecoration(
                          hintText: 'Write your answer here...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF667eea),
                              width: 2,
                            ),
                          ),
                        ),
                        minLines: 4,
                        maxLines: 8,
                        textInputAction: TextInputAction.newline,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Spacer(),
                          ElevatedButton.icon(
                            onPressed: _addAnswer,
                            icon: const Icon(Icons.send),
                            label: const Text('Post Answer'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF667eea),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Display answers
              if (_answers.isEmpty) ...[
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.question_answer,
                        size: 48,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No answers yet',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Be the first to answer this question!',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                ..._answers.map((answer) => _buildAnswerCard(answer)),
              ],

              const SizedBox(height: 32),
              // Related questions (mock)
              const Text(
                'Related Questions',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 1,
                child: ListTile(
                  title: const Text('How to use Provider in Flutter?'),
                  subtitle: const Text(
                    'Discussion on using Provider for state management.',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
              Card(
                elevation: 1,
                child: ListTile(
                  title: const Text('Bloc vs Provider: Which to choose?'),
                  subtitle: const Text('Comparison between Bloc and Provider.'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnswerCard(Map<String, dynamic> answer) {
    final isAccepted = answer['isAccepted'] == true;
    final isCurrentUser = answer['author'] == 'You';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isAccepted ? Colors.green.shade300 : Colors.transparent,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Answer header
            Row(
              children: [
                if (isAccepted) ...[
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.green.shade700,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                CircleAvatar(
                  radius: 16,
                  backgroundColor: isCurrentUser
                      ? const Color(0xFF667eea)
                      : Colors.grey.shade300,
                  child: Text(
                    (answer['author'] as String?)
                            ?.substring(0, 1)
                            .toUpperCase() ??
                        'U',
                    style: TextStyle(
                      color: isCurrentUser ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        answer['author'] ?? 'Unknown',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        _formatTimestamp(answer['timestamp']),
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Vote buttons
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.thumb_up, size: 16),
                      onPressed: () => _voteOnAnswer(answer['_id'] ?? '', true),
                      color: Colors.grey.shade400,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Text(
                      '${answer['votes'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.thumb_down, size: 16),
                      onPressed: () =>
                          _voteOnAnswer(answer['_id'] ?? '', false),
                      color: Colors.grey.shade400,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Answer content
            Text(
              answer['body'] ?? '',
              style: const TextStyle(fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 12),
            // Answer actions
            Row(
              children: [
                if (isAccepted) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Accepted Answer',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement answer editing
                  },
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Edit'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    // TODO: Implement answer deletion
                  },
                  icon: const Icon(Icons.delete, size: 14),
                  label: const Text('Delete'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Just now';

    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown time';
    }
  }
}

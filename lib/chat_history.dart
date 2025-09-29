import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'aichatbot.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<Map<String, dynamic>> _chatSessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatSessions();
  }

  Future<void> _loadChatSessions() async {
    final prefs = await SharedPreferences.getInstance();

    // Load saved chat sessions
    final savedSessionsRaw = prefs.getString('chat_sessions');
    List<Map<String, dynamic>> savedSessions = [];
    if (savedSessionsRaw != null) {
      try {
        savedSessions = (json.decode(savedSessionsRaw) as List)
            .cast<Map<String, dynamic>>();
      } catch (e) {
        // Ignore corrupted data
      }
    }

    // Sort by timestamp (most recent first)
    savedSessions.sort((a, b) {
      final aTime = DateTime.parse(a['timestamp']);
      final bTime = DateTime.parse(b['timestamp']);
      return bTime.compareTo(aTime);
    });

    setState(() {
      _chatSessions = savedSessions;
      _isLoading = false;
    });
  }

  Future<void> _deleteChatSession(String sessionId) async {
    final prefs = await SharedPreferences.getInstance();

    // Remove from saved sessions
    final savedSessionsRaw = prefs.getString('chat_sessions');
    if (savedSessionsRaw != null) {
      try {
        final savedSessions = (json.decode(savedSessionsRaw) as List)
            .cast<Map<String, dynamic>>();
        savedSessions.removeWhere((session) => session['id'] == sessionId);
        await prefs.setString('chat_sessions', json.encode(savedSessions));
      } catch (e) {
        // Ignore errors
      }
    }

    _loadChatSessions(); // Refresh the list
  }

  void _openChatSession(Map<String, dynamic> session) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AIChatBotScreen(
          initialMessages: (session['messages'] as List<dynamic>)
              .cast<Map<String, dynamic>>(),
          sessionId: session['id'],
          isReadOnly: true, // All saved sessions are read-only
        ),
      ),
    ).then((_) => _loadChatSessions()); // Refresh when returning
  }

  void _startNewConversation() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AIChatBotScreen()),
    ).then((_) => _loadChatSessions());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat History'),
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: _startNewConversation,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('New Chat'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF667eea),
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _chatSessions.isEmpty
            ? _buildEmptyState()
            : _buildChatSessionsList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1 * 255),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No conversations yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Start a new chat to begin your conversation with Devoverflow',
            style: TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          const Text(
            'Tap the "New Chat" button above to get started',
            style: TextStyle(fontSize: 14, color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildChatSessionsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _chatSessions.length,
      itemBuilder: (context, index) {
        final session = _chatSessions[index];
        final messages = session['messages'] as List<dynamic>;
        final messageCount = messages.length;
        final lastMessageTime = _formatTimestamp(session['timestamp']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            onTap: () => _openChatSession(session),
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session['title'],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$messageCount messages • $lastMessageTime',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Preview of last message
                        if (messages.isNotEmpty) ...[
                          Text(
                            _getLastMessagePreview(messages.last),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Delete button
                  IconButton(
                    onPressed: () => _showDeleteDialog(session),
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    tooltip: 'Delete conversation',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteDialog(Map<String, dynamic> session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this conversation? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteChatSession(session['id']);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getLastMessagePreview(Map<String, dynamic> lastMessage) {
    final text = lastMessage['text'] as String;
    final isBot = lastMessage['from'] == 'bot';
    final prefix = isBot ? 'AI: ' : 'You: ';
    final preview = text.length > 50 ? '${text.substring(0, 50)}...' : text;
    return '$prefix$preview';
  }

  String _formatTimestamp(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'chat_history.dart';
import 'api_service.dart';
import 'api_config.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AIChatBotScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? initialMessages;
  final String? sessionId;
  final bool isReadOnly;

  const AIChatBotScreen({
    super.key,
    this.initialMessages,
    this.sessionId,
    this.isReadOnly = false,
  });

  @override
  State<AIChatBotScreen> createState() => _AIChatBotScreenState();
}

class _AIChatBotScreenState extends State<AIChatBotScreen>
    with TickerProviderStateMixin {
  final List<Map<String, dynamic>> _messages = [];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isLoading = false;
  String? _currentSessionId;
  late AnimationController _typingAnimationController;
  late Animation<double> _typingAnimation;

  // Mock AI responses for different types of queries (debug only)
  final Map<String, List<String>> _mockResponses = {
    'greeting': [
      "Hello! I'm your AI assistant for Devoverflow. I can help you with Flutter development, coding questions, debugging, and best practices. What would you like to know?",
      "Hi there! Welcome to Devoverflow's AI assistant. I'm here to help you with programming questions, code reviews, and development guidance. How can I assist you today?",
      "Greetings! I'm Devoverflow's AI coding assistant. I specialize in Flutter, Dart, and mobile development. Feel free to ask me anything about your projects!",
    ],
    'flutter': [
      "For Flutter development, I recommend using Provider or Riverpod for state management. Here's a quick example:\n\n```dart\nclass MyApp extends StatelessWidget {\n  @override\n  Widget build(BuildContext context) {\n    return ChangeNotifierProvider(\n      create: (context) => MyModel(),\n      child: MaterialApp(home: MyHomePage()),\n    );\n  }\n}\n```\n\nThis pattern provides clean separation of concerns and makes testing easier.",
      "Flutter's hot reload feature is incredibly powerful for rapid development. When building complex UIs, consider using:\n\n1. **Custom widgets** for reusable components\n2. **Keys** for preserving state during rebuilds\n3. **const constructors** for performance optimization\n4. **LayoutBuilder** for responsive designs\n\nWould you like me to elaborate on any of these?",
    ],
    'debug': [
      "When debugging Flutter apps, I always start by:\n\n1. **Checking the console** for error messages\n2. **Using Flutter DevTools** for performance profiling\n3. **Adding print statements** or breakpoints strategically\n4. **Testing on different devices** to catch platform-specific issues\n\nThe most common issues I see are:\n- Null pointer exceptions from uninitialized variables\n- BuildContext issues in async operations\n- State management problems in complex widget trees\n\nWhat's the specific error you're encountering?",
    ],
    'default': [
      "That's an interesting question! While I don't have specific information about that topic in my current knowledge base, I can suggest some general approaches:\n\n1. **Research official documentation** - Always start with the official docs\n2. **Check community resources** - Stack Overflow, GitHub issues, and forums often have solutions\n3. **Break down the problem** - Divide complex issues into smaller, manageable parts\n4. **Test incrementally** - Build and test small changes rather than large refactors\n\nWould you like me to help you formulate a more specific question or explore related topics?",
    ],
  };

  @override
  void initState() {
    super.initState();

    _typingAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _typingAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_typingAnimationController);

    // Handle different initialization scenarios
    if (widget.sessionId != null) {
      // Loading an existing session
      _currentSessionId = widget.sessionId;
      _loadExistingSession(widget.sessionId!);
    } else if (widget.initialMessages != null) {
      // Viewing messages from history (read-only)
      _messages.addAll(widget.initialMessages!);
    } else if (!widget.isReadOnly) {
      // Starting a new chat session
      _createNewSession();
    }
  }

  @override
  void dispose() {
    // For API-based sessions, the session is already saved on the server
    // No need to save locally when leaving

    _controller.dispose();
    _scrollController.dispose();
    _typingAnimationController.dispose();
    super.dispose();
  }

  Future<void> _createNewSession() async {
    try {
      final response = await ApiService().post(
        ApiConfig.createChatSession,
        data: {},
      );
      if (response['success'] == true) {
        _currentSessionId = response['session']['id'];
        // Add welcome message
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && _messages.isEmpty) {
            _addBotMessage(
              "Hello! I'm your AI assistant for Devoverflow. I can help you with Flutter development, coding questions, debugging, and best practices. What would you like to know?",
              isWelcome: true,
            );
          }
        });
      }
    } catch (e) {
      // Fallback to local mode if API fails — but only use mock responses in
      // debug builds. Production should show a friendly offline message.
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && _messages.isEmpty) {
          if (kDebugMode) {
            _addBotMessage(
              "Hello! I'm your AI assistant for Devoverflow. I can help you with Flutter development, coding questions, debugging, and best practices. What would you like to know?",
              isWelcome: true,
            );
          } else {
            _addBotMessage(
              'The AI assistant is currently unavailable. Please try again later.',
              isWelcome: true,
            );
          }
        }
      });
    }
  }

  Future<void> _loadExistingSession(String sessionId) async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get(
        '${ApiConfig.getChatMessages}/$sessionId',
      );
      if (response['success'] == true) {
        final messages = response['messages'] as List? ?? [];
        setState(() {
          _messages.clear();
          _messages.addAll(messages.map((m) => m as Map<String, dynamic>));
        });
      }
    } catch (e) {
      // If API fails, show error but keep the screen functional
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load chat session')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _getRandomResponse(String category) {
    final responses = _mockResponses[category] ?? _mockResponses['default']!;
    return responses[DateTime.now().millisecondsSinceEpoch % responses.length];
  }

  void _addBotMessage(String text, {bool isWelcome = false, String? html}) {
    // For new API: use content (raw markdown) and html (sanitized HTML)
    // For backward compatibility: if no html provided, use text as content
    final content = text;

    setState(() {
      _messages.add({
        "from": "bot",
        "content": content,
        "html": html,
        "timestamp": DateTime.now().toIso8601String(),
        "isWelcome": isWelcome,
      });
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add({
        "from": "user",
        "text": text,
        "timestamp": DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading || widget.isReadOnly) return;

    _addUserMessage(text);
    _controller.clear();

    setState(() {
      _isTyping = true;
      _isLoading = true;
    });

    try {
      if (_currentSessionId != null) {
        // Send message to API
        final response = await ApiService().post(
          '${ApiConfig.sendChatMessage}/$_currentSessionId/messages',
          data: {'message': text},
        );

        if (response['success'] == true) {
          final botResponse = response['response'];
          String botMessage;
          String? html;

          if (botResponse is Map<String, dynamic>) {
            // New API format: response contains content and html
            botMessage =
                botResponse['content'] ??
                botResponse['response'] ??
                'I apologize, but I couldn\'t generate a response right now.';
            html = botResponse['html'];
          } else {
            // Old API format: response is just the text
            botMessage =
                botResponse?.toString() ??
                'I apologize, but I couldn\'t generate a response right now.';
          }

          _addBotMessage(botMessage, html: html);
        } else {
          _addBotMessage(
            'I apologize, but I couldn\'t process your message right now. Please try again.',
          );
        }
      } else {
        // Fallback to mock response if no session (debug builds only). In
        // production, show a generic offline reply.
        await Future.delayed(const Duration(milliseconds: 1000));
        if (kDebugMode) {
          String category = 'default';
          final lowerText = text.toLowerCase();

          if (lowerText.contains('hello') ||
              lowerText.contains('hi') ||
              lowerText.contains('hey')) {
            category = 'greeting';
          } else if (lowerText.contains('flutter') ||
              lowerText.contains('dart') ||
              lowerText.contains('widget')) {
            category = 'flutter';
          } else if (lowerText.contains('error') ||
              lowerText.contains('bug') ||
              lowerText.contains('debug') ||
              lowerText.contains('fix')) {
            category = 'debug';
          }

          _addBotMessage(_getRandomResponse(category));
        } else {
          _addBotMessage(
            'The assistant is currently offline. Please try again later.',
          );
        }
      }
    } catch (e) {
      // Fallback to mock response on API failure
      await Future.delayed(const Duration(milliseconds: 1000));
      _addBotMessage(
        'I apologize, but I\'m having trouble connecting right now. Here\'s some general advice instead:',
      );
      _addBotMessage(_getRandomResponse('default'));
    } finally {
      setState(() {
        _isTyping = false;
        _isLoading = false;
      });
    }
  }

  void _startNewChat() {
    // For API-based sessions, sessions are automatically saved on the server
    // No need to save locally

    // Navigate to a new chat instance
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AIChatBotScreen()),
    );
  }

  void _clearConversation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Conversation'),
        content: const Text('Are you sure you want to clear all messages?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              setState(() {
                _messages.clear();
              });
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('chat_history');
              _addBotMessage(_getRandomResponse('greeting'), isWelcome: true);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                // Use ARGB to avoid deprecated withOpacity semantics
                color: const Color.fromARGB(51, 255, 255, 255),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Devoverflow',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
        actions: [
          if (!widget.isReadOnly) ...[
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _startNewChat,
              tooltip: 'New Chat',
            ),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatHistoryScreen(),
                  ),
                );
              },
              tooltip: 'Chat History',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearConversation,
              tooltip: 'Clear conversation',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatHistoryScreen(),
                  ),
                );
              },
              tooltip: 'Chat History',
            ),
          ],
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
        child: Column(
          children: [
            // Messages area
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length + (_isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isTyping) {
                        return _buildTypingIndicator();
                      }

                      final message = _messages[index];
                      final isBot = message['from'] == 'bot';
                      final isWelcome = message['isWelcome'] == true;

                      return _buildMessageBubble(message, isBot, isWelcome);
                    },
                  ),
                ),
              ),
            ),

            // Input area
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: InputDecoration(
                            hintText: widget.isReadOnly
                                ? 'This is a read-only conversation'
                                : 'Ask me anything about development...',
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            suffixIcon: _isLoading
                                ? Container(
                                    width: 20,
                                    height: 20,
                                    margin: const EdgeInsets.all(14),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF667eea),
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: widget.isReadOnly
                              ? null
                              : (_) => _sendMessage(),
                          enabled: !widget.isReadOnly && !_isLoading,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        onPressed: (widget.isReadOnly || _isLoading)
                            ? null
                            : _sendMessage,
                        icon: Icon(
                          Icons.send,
                          color: widget.isReadOnly ? Colors.grey : Colors.white,
                        ),
                        tooltip: widget.isReadOnly
                            ? 'Read-only mode'
                            : 'Send message',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF667eea),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            AnimatedBuilder(
              animation: _typingAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _typingAnimation.value,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF667eea),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(width: 4),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF667eea),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'AI is thinking...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    Map<String, dynamic> message,
    bool isBot,
    bool isWelcome,
  ) {
    return Align(
      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isBot
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            // Message bubble
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isBot
                    ? const LinearGradient(
                        colors: [Color(0xFFF8F9FA), Color(0xFFE9ECEF)],
                      )
                    : const LinearGradient(
                        colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isBot ? 4 : 20),
                  topRight: Radius.circular(isBot ? 20 : 4),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1 * 255),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isWelcome) ...[
                    Row(
                      children: [
                        Icon(
                          Icons.waving_hand,
                          color: Colors.amber.shade600,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Welcome to Devoverflow AI!',
                          style: TextStyle(
                            color: Colors.amber.shade700,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  _buildMessageContent(message),
                ],
              ),
            ),

            // Timestamp
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 12, right: 12),
              child: Text(
                _formatTimestamp(message['timestamp']),
                style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> message) {
    // Get content: prefer 'content' field (new API), fallback to 'text' (old API)
    final content =
        message['content'] as String? ?? message['text'] as String? ?? '';
    final html = message['html'] as String?;

    // Try to render as Markdown first
    try {
      return MarkdownBody(
        data: content,
        selectable: true,
        styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
      );
    } catch (_) {
      // Fallback: render sanitized HTML if available
      if (html != null && html.isNotEmpty) {
        // For now, render as plain text since we don't have flutter_html
        // TODO: Add flutter_html dependency for HTML rendering
        return Text(
          html,
          style: const TextStyle(color: Colors.black87, height: 1.4),
        );
      }

      // Last resort: plain text
      return Text(
        content,
        style: const TextStyle(color: Colors.black87, height: 1.4),
      );
    }
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '';

    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return '';
    }
  }
}

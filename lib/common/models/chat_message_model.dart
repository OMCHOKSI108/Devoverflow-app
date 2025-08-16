// lib/common/models/chat_message_model.dart
enum MessageAuthor { user, bot }

class ChatMessage {
  final String text;
  final MessageAuthor author;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.author,
    required this.timestamp,
  });
}

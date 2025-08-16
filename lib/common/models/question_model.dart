// lib/common/models/question_model.dart
class Question {
  final String id;
  final String title;
  final String author;
  final String authorImageUrl;
  final int votes;
  final int answers;
  final List<String> tags;
  final DateTime timestamp;

  Question({
    required this.id,
    required this.title,
    required this.author,
    required this.authorImageUrl,
    required this.votes,
    required this.answers,
    required this.tags,
    required this.timestamp,
  });
}
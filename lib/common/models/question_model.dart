// lib/common/models/question_model.dart

class QuestionModel {
  final String id;
  final String title;
  final String body;
  final String authorId;
  final String authorName;
  final String authorImageUrl;
  final int votes;
  final int answersCount;
  final List<String> tags;
  final DateTime timestamp;

  QuestionModel({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.authorImageUrl,
    required this.votes,
    required this.answersCount,
    required this.tags,
    required this.timestamp,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> map) {
    return QuestionModel(
      id: map['_id'] ?? map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      authorId: map['author']?['_id'] ?? '',
      authorName: map['author']?['username'] ?? 'Unknown User',
      authorImageUrl:
          map['author']?['profileImageUrl'] ?? 'https://i.pravatar.cc/150',
      votes: map['votes'] ?? 0,
      answersCount: map['answersCount'] ?? 0,
      tags: List<String>.from(map['tags'] ?? []),
      timestamp: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(), // Default to current time if not provided
    );
  }
}

// Legacy alias class kept for backward compatibility with older widgets and cubits
class Question {
  final String id;
  final String title;
  final String body;
  final String authorId;
  final String authorName;
  final String authorImageUrl;
  final int votes;
  final int answersCount;
  final List<String> tags;
  final DateTime timestamp;

  Question({
    required this.id,
    required this.title,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.authorImageUrl,
    required this.votes,
    required this.answersCount,
    required this.tags,
    required this.timestamp,
  });

  factory Question.fromJson(Map<String, dynamic> map) {
    // Reuse QuestionModel parsing and map into Question
    final qm = QuestionModel.fromJson(map);
    return Question(
      id: qm.id,
      title: qm.title,
      body: qm.body,
      authorId: qm.authorId,
      authorName: qm.authorName,
      authorImageUrl: qm.authorImageUrl,
      votes: qm.votes,
      answersCount: qm.answersCount,
      tags: qm.tags,
      timestamp: qm.timestamp,
    );
  }
}

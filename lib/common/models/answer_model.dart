// lib/common/models/answer_model.dart

class AnswerModel {
  final String id;
  final String body;
  final String authorId;
  final String authorName;
  final String authorImageUrl;
  final int votes;
  final bool isAcceptedAnswer;
  final DateTime timestamp;

  AnswerModel({
    required this.id,
    required this.body,
    required this.authorId,
    required this.authorName,
    required this.authorImageUrl,
    this.votes = 0,
    this.isAcceptedAnswer = false,
    required this.timestamp,
  });

  factory AnswerModel.fromJson(Map<String, dynamic> map) {
    return AnswerModel(
      id: map['_id'] ?? map['id'] ?? '',
      body: map['body'] ?? '',
      authorId: map['author']?['_id'] ?? '',
      authorName: map['author']?['username'] ?? 'Unknown User',
      authorImageUrl:
          map['author']?['profileImageUrl'] ?? 'https://i.pravatar.cc/150',
      votes: map['votes'] ?? 0,
      isAcceptedAnswer: map['isAccepted'] ?? false,
      timestamp: map['createdAt'] is String
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(), // Default to current time if not provided
    );
  }
}

// lib/common/models/answer_model.dart
import 'package:devoverflow/common/models/user_model.dart';
import 'package:devoverflow/common/models/comment_model.dart'; // <-- ADD THIS IMPORT

class AnswerModel {
  final String id;
  final String body;
  final UserModel author;
  final int votes;
  final bool isAcceptedAnswer;
  final DateTime timestamp;
  final List<CommentModel> comments; // <-- ADD THIS NEW FIELD

  AnswerModel({
    required this.id,
    required this.body,
    required this.author,
    this.votes = 0,
    this.isAcceptedAnswer = false,
    required this.timestamp,
    this.comments = const [], // Default to an empty list
  });
}

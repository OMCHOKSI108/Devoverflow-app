// lib/common/models/comment_model.dart
import 'package:devoverflow/common/models/user_model.dart';

class CommentModel {
  final String id;
  final String body;
  final UserModel author;
  final DateTime timestamp;

  CommentModel({
    required this.id,
    required this.body,
    required this.author,
    required this.timestamp,
  });
}

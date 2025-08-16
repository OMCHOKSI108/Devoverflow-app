// lib/common/models/notification_model.dart
enum NotificationType { newAnswer, newComment, newVote }

class NotificationModel {
  final String id;
  final NotificationType type;
  final String message;
  final String questionId; // To navigate to the relevant question
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.type,
    required this.message,
    required this.questionId,
    this.isRead = false,
    required this.timestamp,
  });
}

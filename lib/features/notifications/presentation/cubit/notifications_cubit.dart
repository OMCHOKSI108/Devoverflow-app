import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:devoverflow/common/models/notification_model.dart';
import 'notifications_state.dart';

class NotificationCubit extends Cubit<NotificationState> {
  NotificationCubit() : super(NotificationInitial());

  Future<void> fetchNotifications() async {
    try {
      emit(NotificationLoading());
      await Future.delayed(const Duration(milliseconds: 700));
      emit(NotificationLoaded(_getMockNotifications()));
    } catch (e) {
      emit(const NotificationError('Failed to load notifications.'));
    }
  }

  List<NotificationModel> _getMockNotifications() {
    return [
      NotificationModel(id: 'n1', type: NotificationType.newAnswer, message: 'John Smith answered your question about API calls.', questionId: '2', timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
      NotificationModel(id: 'n2', type: NotificationType.newVote, message: 'Your answer on "Clean Architecture" was upvoted.', questionId: '3', timestamp: DateTime.now().subtract(const Duration(hours: 1))),
      NotificationModel(id: 'n3', type: NotificationType.newComment, message: 'Sarah Lynn commented on your answer.', questionId: '1', isRead: true, timestamp: DateTime.now().subtract(const Duration(days: 1))),
    ];
  }
}
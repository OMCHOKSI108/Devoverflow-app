// lib/features/notifications/presentation/screens/notifications_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:devoverflow/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:devoverflow/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:devoverflow/common/models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationCubit()..fetchNotifications(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Notifications'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state is NotificationLoading || state is NotificationInitial) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is NotificationError) {
              return Center(child: Text(state.message));
            }
            if (state is NotificationLoaded) {
              if (state.notifications.isEmpty) {
                return const Center(child: Text('You have no new notifications.'));
              }
              return ListView.builder(
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return ListTile(
                    leading: Icon(
                      notification.isRead ? Icons.notifications : Icons.notifications_active,
                      color: notification.isRead ? Colors.grey : Theme.of(context).colorScheme.secondary,
                    ),
                    title: Text(notification.message),
                    subtitle: Text('${DateTime.now().difference(notification.timestamp).inMinutes}m ago'),
                    onTap: () {
                      context.push('/question/${notification.questionId}');
                    },
                  );
                },
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_service.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String type;
  final DateTime createdAt;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    DateTime? createdAt,
    this.isRead = false,
    this.data,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'message': message,
    'type': type,
    'createdAt': createdAt.toIso8601String(),
    'isRead': isRead,
    'data': data,
  };

  static NotificationItem fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'],
        title: json['title'],
        message: json['message'],
        type: json['type'],
        createdAt: DateTime.parse(json['createdAt']),
        isRead: json['isRead'] ?? false,
        data: json['data'],
      );

  // Factory for creating mock notifications
  static NotificationItem mock({
    required String id,
    required String title,
    required String message,
    required String type,
    bool isRead = false,
  }) => NotificationItem(
    id: id,
    title: title,
    message: message,
    type: type,
    createdAt: DateTime.now().subtract(Duration(minutes: int.parse(id) * 5)),
    isRead: isRead,
  );
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);

    try {
      // Try API first
      final response = await ApiService().getNotifications();

      List<dynamic> list = ApiService().extractList(response, [
        'notifications',
        'data',
      ]);

      // Handle nested data structure: response.data.notifications
      if (list.isEmpty) {
        final data = response['data'];
        if (data is Map<String, dynamic> && data['notifications'] is List) {
          list = data['notifications'] as List<dynamic>;
        }
      }

      final parsed = list
          .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
          .toList();
      setState(() {
        _notifications = parsed;
      });
      // Cache to prefs for offline fallback
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'notifications',
          json.encode(_notifications.map((n) => n.toJson()).toList()),
        );
      } catch (_) {}
    } catch (e) {
      // Fallback to local notifications on error
      await _loadNotificationsFromLocal();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadNotificationsFromLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsRaw = prefs.getString('notifications');
    if (notificationsRaw != null) {
      final notificationsList = json.decode(notificationsRaw) as List;
      _notifications = notificationsList
          .map((n) => NotificationItem.fromJson(n))
          .toList();
    } else {
      // Create some mock notifications for demo in debug builds only.
      // Production should not create or persist mock notifications.
      if (kDebugMode) {
        _notifications = [
          NotificationItem.mock(
            id: '1',
            title: 'Welcome to DevOverflow!',
            message:
                'Thanks for joining our community. Start by asking your first question!',
            type: 'welcome',
            isRead: false,
          ),
          NotificationItem.mock(
            id: '2',
            title: 'Question Answered',
            message:
                'Your question "How to implement state management in Flutter?" received a new answer.',
            type: 'answer',
            isRead: false,
          ),
          NotificationItem.mock(
            id: '3',
            title: 'New Follower',
            message: 'FlutterExpert started following you.',
            type: 'follow',
            isRead: true,
          ),
          NotificationItem.mock(
            id: '4',
            title: 'Badge Earned',
            message:
                'Congratulations! You earned the "Curious Mind" badge for asking great questions.',
            type: 'badge',
            isRead: true,
          ),
        ];

        // Save mock notifications for debug convenience
        await prefs.setString(
          'notifications',
          json.encode(_notifications.map((n) => n.toJson()).toList()),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final response = await ApiService().markNotificationAsRead(
        notificationId,
      );

      if (response['success'] == true) {
        setState(() {
          final index = _notifications.indexWhere(
            (n) => n.id == notificationId,
          );
          if (index != -1) {
            _notifications[index] = NotificationItem(
              id: _notifications[index].id,
              title: _notifications[index].title,
              message: _notifications[index].message,
              type: _notifications[index].type,
              createdAt: _notifications[index].createdAt,
              isRead: true,
              data: _notifications[index].data,
            );
          }
        });
        // persist change
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'notifications',
            json.encode(_notifications.map((n) => n.toJson()).toList()),
          );
        } catch (_) {}
      } else {
        // Fallback to local update
        await _markAsReadLocal(notificationId);
      }
    } catch (e) {
      // Fallback to local update on error
      await _markAsReadLocal(notificationId);
    }
  }

  Future<void> _markAsReadLocal(String notificationId) async {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = NotificationItem(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          type: _notifications[index].type,
          createdAt: _notifications[index].createdAt,
          isRead: true,
          data: _notifications[index].data,
        );
      }
    });

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notifications',
      json.encode(_notifications.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> _markAllAsRead() async {
    setState(() => _isMarkingAllRead = true);

    try {
      final response = await ApiService().markAllNotificationsAsRead();

      if (response['success'] == true) {
        setState(() {
          _notifications = _notifications
              .map(
                (n) => NotificationItem(
                  id: n.id,
                  title: n.title,
                  message: n.message,
                  type: n.type,
                  createdAt: n.createdAt,
                  isRead: true,
                  data: n.data,
                ),
              )
              .toList();
        });
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'notifications',
            json.encode(_notifications.map((n) => n.toJson()).toList()),
          );
        } catch (_) {}
      } else {
        // Fallback to local update
        await _markAllAsReadLocal();
      }
    } catch (e) {
      // Fallback to local update on error
      await _markAllAsReadLocal();
    } finally {
      setState(() => _isMarkingAllRead = false);
    }
  }

  Future<void> _markAllAsReadLocal() async {
    setState(() {
      _notifications = _notifications
          .map(
            (n) => NotificationItem(
              id: n.id,
              title: n.title,
              message: n.message,
              type: n.type,
              createdAt: n.createdAt,
              isRead: true,
              data: n.data,
            ),
          )
          .toList();
    });

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notifications',
      json.encode(_notifications.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> _deleteNotification(String notificationId) async {
    try {
      final response = await ApiService().deleteNotification(notificationId);

      if (response['success'] == true) {
        setState(() {
          _notifications.removeWhere((n) => n.id == notificationId);
        });
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
            'notifications',
            json.encode(_notifications.map((n) => n.toJson()).toList()),
          );
        } catch (_) {}
      } else {
        // Fallback to local delete
        await _deleteNotificationLocal(notificationId);
      }
    } catch (e) {
      // Fallback to local delete on error
      await _deleteNotificationLocal(notificationId);
    }
  }

  Future<void> _deleteNotificationLocal(String notificationId) async {
    setState(() {
      _notifications.removeWhere((n) => n.id == notificationId);
    });

    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'notifications',
      json.encode(_notifications.map((n) => n.toJson()).toList()),
    );
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'answer':
        return Icons.question_answer;
      case 'follow':
        return Icons.person_add;
      case 'badge':
        return Icons.emoji_events;
      case 'welcome':
        return Icons.waving_hand;
      case 'mention':
        return Icons.alternate_email;
      case 'vote':
        return Icons.thumb_up;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'answer':
        return Colors.blue;
      case 'follow':
        return Colors.green;
      case 'badge':
        return Colors.orange;
      case 'welcome':
        return Colors.purple;
      case 'mention':
        return Colors.red;
      case 'vote':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: const Color(0xFF667eea),
        actions: [
          if (unreadCount > 0)
            TextButton.icon(
              onPressed: _isMarkingAllRead ? null : _markAllAsRead,
              icon: _isMarkingAllRead
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.done_all, color: Colors.white),
              label: Text(
                'Mark all read',
                style: const TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF667eea)),
              ),
            )
          : _notifications.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.notifications_off,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No notifications yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You\'ll see updates here when people interact with your content',
                    style: TextStyle(color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadNotifications,
              child: ListView.builder(
                itemCount: _notifications.length,
                itemBuilder: (context, index) {
                  final notification = _notifications[index];

                  return Dismissible(
                    key: Key(notification.id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    onDismissed: (direction) {
                      _deleteNotification(notification.id);
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      elevation: notification.isRead ? 1 : 3,
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getNotificationColor(
                            notification.type,
                          ).withValues(alpha: 0.2 * 255),
                          child: Icon(
                            _getNotificationIcon(notification.type),
                            color: _getNotificationColor(notification.type),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: TextStyle(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF667eea),
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(notification.message),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimeAgo(notification.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        onTap: () {
                          if (!notification.isRead) {
                            _markAsRead(notification.id);
                          }
                          // TODO: Navigate to relevant screen based on notification type
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

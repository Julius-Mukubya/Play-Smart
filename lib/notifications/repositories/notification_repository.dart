import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

/// Notification repository — handles notification events and delivery.
class NotificationRepository {
  final List<AppNotification> _notifications = List.from(MockData.notifications);

  /// Get all notifications for a user.
  List<AppNotification> getNotifications(String userId) {
    return _notifications.where((n) => n.userId == userId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get unread notification count.
  int getUnreadCount(String userId) {
    return _notifications.where((n) => n.userId == userId && !n.read).length;
  }

  /// Create a notification.
  Future<AppNotification> createNotification(AppNotification notification) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _notifications.add(notification);
    return notification;
  }

  /// Mark a notification as read.
  Future<void> markAsRead(String notificationId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index >= 0) {
      final n = _notifications[index];
      _notifications[index] = AppNotification(
        id: n.id, userId: n.userId, type: n.type,
        title: n.title, body: n.body, relatedId: n.relatedId,
        read: true, createdAt: n.createdAt,
      );
    }
  }

  /// Mark all notifications as read for a user.
  Future<void> markAllAsRead(String userId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    for (int i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId && !_notifications[i].read) {
        final n = _notifications[i];
        _notifications[i] = AppNotification(
          id: n.id, userId: n.userId, type: n.type,
          title: n.title, body: n.body, relatedId: n.relatedId,
          read: true, createdAt: n.createdAt,
        );
      }
    }
  }

  /// Create a notification for a specific event type.
  Future<AppNotification> notify({
    required String userId,
    required NotificationType type,
    required String title,
    required String body,
    String? relatedId,
  }) async {
    return createNotification(AppNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      userId: userId, type: type,
      title: title, body: body, relatedId: relatedId,
    ));
  }
}
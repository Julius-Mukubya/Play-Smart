import 'package:play_smart/shared/types/domain_types.dart';

/// Mock/In-memory Notification repository — ready to be wired up with Firebase Firestore.
class NotificationRepository {
  final List<AppNotification> _notifications = [];

  Future<List<AppNotification>> getNotifications(String userId) async {
    return _notifications.where((n) => n.userId == userId).toList();
  }

  Future<int> getUnreadCount(String userId) async {
    return _notifications.where((n) => n.userId == userId && !n.read).length;
  }

  Future<void> markAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _notifications[idx] = _notifications[idx].copyWith(read: true);
    }
  }

  Future<void> markAllAsRead(String userId) async {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].userId == userId) {
        _notifications[i] = _notifications[i].copyWith(read: true);
      }
    }
  }
}

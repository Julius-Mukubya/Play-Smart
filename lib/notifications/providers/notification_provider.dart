import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/notifications/repositories/notification_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() => NotificationState();

  NotificationRepository get _repo => ref.read(notificationRepositoryProvider);
  String? get _uid {
    final a = ref.read(authProvider);
    return a is AuthAuthenticated ? a.user.id : null;
  }

  Future<void> loadNotifications() async {
    final uid = _uid;
    if (uid == null) return;
    state = state.copyWith(isLoading: true);
    try {
      final list = _repo.getNotifications(uid);
      final unread = _repo.getUnreadCount(uid);
      state = state.copyWith(notifications: list, unreadCount: unread, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    await loadNotifications();
  }

  Future<void> markAllAsRead() async {
    final uid = _uid;
    if (uid == null) return;
    await _repo.markAllAsRead(uid);
    await loadNotifications();
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  NotificationNotifier.new,
);
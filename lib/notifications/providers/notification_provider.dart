import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/notifications/repositories/notification_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgresChangeEvent, PostgresChangeFilter, PostgresChangeFilterType, RealtimeChannel;

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
  RealtimeChannel? _channel;
  String? _subscribedUserId;

  @override
  NotificationState build() {
    ref.onDispose(() => _channel?.unsubscribe());
    return NotificationState();
  }

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
      final list = await _repo.getNotifications(uid);
      final unread = await _repo.getUnreadCount(uid);
      state = state.copyWith(notifications: list, unreadCount: unread, isLoading: false);
      _ensureSubscription(uid);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Subscribe to new notifications for this user so the unread badge and
  /// list update live. Only listens for `insert` — `markAsRead`/
  /// `markAllAsRead` already refresh state directly, so reacting to `update`
  /// events too would just be a redundant extra fetch per read action.
  void _ensureSubscription(String userId) {
    if (_subscribedUserId == userId) return;
    _channel?.unsubscribe();
    _subscribedUserId = userId;
    _channel = supabase
        .channel('notifications:$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) => loadNotifications(),
        )
        .subscribe();
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
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/notifications/providers/notification_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Notifications screen — shows all notification events.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(notificationProvider.notifier).fetchNotifications());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(notificationProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
              child: const Text('Mark All Read'),
            ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.notifications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('No notifications', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('You\'re all caught up!', style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: state.notifications.length,
                  itemBuilder: (ctx, i) {
                    final n = state.notifications[i];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: n.read
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.primaryContainer,
                          child: Icon(
                            _iconForType(n.type),
                            color: n.read ? theme.colorScheme.outline : theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(n.title, style: TextStyle(fontWeight: n.read ? FontWeight.normal : FontWeight.w600)),
                        subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
                        trailing: n.read
                            ? null
                            : Container(
                                width: 8, height: 8,
                                decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                              ),
                        onTap: n.read ? null : () => ref.read(notificationProvider.notifier).markAsRead(n.id),
                      ),
                    );
                  },
                ),
    );
  }

  IconData _iconForType(NotificationType type) {
    return switch (type) {
      NotificationType.profileView => Icons.visibility,
      NotificationType.shortlisted => Icons.bookmark,
      NotificationType.trialMatch => Icons.sports,
      NotificationType.endorsementRequest => Icons.verified,
      NotificationType.messageRequest => Icons.mail,
    };
  }
}
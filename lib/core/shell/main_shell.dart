import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/notifications/providers/notification_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Main app shell — persistent bottom navigation bar wrapping all main tab screens.
/// Uses StatefulShellRoute so each tab preserves its own navigation stack.
class MainShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final unreadCount = ref.watch(notificationProvider).unreadCount;

    // Determine user role for the contextual middle tab
    AccountRole role = AccountRole.athlete;
    if (authState is AuthAuthenticated) {
      role = authState.user.role;
    }

    final tabs = _buildTabs(role, unreadCount);

    return Scaffold(
      body: SizedBox.expand(child: navigationShell),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
        items: tabs,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  List<BottomNavigationBarItem> _buildTabs(AccountRole role, int unreadCount) {
    // Middle tab adapts to user role
    final BottomNavigationBarItem middleTab = switch (role) {
      AccountRole.athlete => const BottomNavigationBarItem(
          icon: Icon(Icons.cloud_upload_outlined),
          activeIcon: Icon(Icons.cloud_upload),
          label: 'Upload',
        ),
      AccountRole.recruiter || AccountRole.club => const BottomNavigationBarItem(
          icon: Icon(Icons.event_outlined),
          activeIcon: Icon(Icons.event),
          label: 'Opportunities',
        ),
      AccountRole.guest || AccountRole.admin => const BottomNavigationBarItem(
          icon: Icon(Icons.explore_outlined),
          activeIcon: Icon(Icons.explore),
          label: 'Explore',
        ),
    };

    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.explore_outlined),
        activeIcon: Icon(Icons.explore),
        label: 'Discover',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        activeIcon: Icon(Icons.search),
        label: 'Search',
      ),
      middleTab,
      BottomNavigationBarItem(
        icon: unreadCount > 0
            ? Badge(
                label: Text('$unreadCount'),
                child: const Icon(Icons.message_outlined),
              )
            : const Icon(Icons.message_outlined),
        activeIcon: unreadCount > 0
            ? Badge(
                label: Text('$unreadCount'),
                child: const Icon(Icons.message),
              )
            : const Icon(Icons.message),
        label: 'Messages',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outlined),
        activeIcon: Icon(Icons.person),
        label: 'Profile',
      ),
    ];
  }

  void _onTap(BuildContext context, int index) {
    // goBranch keeps each tab's own navigation stack alive
    navigationShell.goBranch(
      index,
      // Re-tapping the active tab pops to the branch root
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

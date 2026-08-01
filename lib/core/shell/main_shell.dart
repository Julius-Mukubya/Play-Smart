import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/notifications/providers/notification_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Which bottom-nav tab is currently visible. StatefulShellRoute keeps every
/// branch mounted via IndexedStack, so a screen like Discover (autoplaying
/// video) has no built-in signal that it's been navigated away from —
/// widgets that need to pause/stop when off-screen should watch this.
class ActiveShellTabIndexNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void set(int index) => state = index;
}

final activeShellTabIndexProvider = NotifierProvider<ActiveShellTabIndexNotifier, int>(
  ActiveShellTabIndexNotifier.new,
);

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

    // Deferred to avoid "modify provider during build" — keeps
    // activeShellTabIndexProvider in sync with the shell's actual current
    // branch regardless of how navigation got there (tap, deep link, etc).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(activeShellTabIndexProvider) != navigationShell.currentIndex) {
        ref.read(activeShellTabIndexProvider.notifier).set(navigationShell.currentIndex);
      }
    });

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
        onTap: (index) => _onTap(context, ref, index),
        items: tabs,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }

  List<BottomNavigationBarItem> _buildTabs(AccountRole role, int unreadCount) {
    // Middle tab adapts to user role
    final BottomNavigationBarItem middleTab = switch (role) {
      AccountRole.athlete => const BottomNavigationBarItem(
          icon: Icon(Icons.add_box_outlined),
          activeIcon: Icon(Icons.add_box),
          label: 'Post',
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

  void _onTap(BuildContext context, WidgetRef ref, int index) {
    if (index == 1 || index == 2 || index == 3 || index == 4) {
      final authState = ref.read(authProvider);
      if (authState is! AuthAuthenticated) {
        context.push(AppRouter.auth);
        return;
      }
    }
    // goBranch keeps each tab's own navigation stack alive
    navigationShell.goBranch(
      index,
      // Re-tapping the active tab pops to the branch root
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

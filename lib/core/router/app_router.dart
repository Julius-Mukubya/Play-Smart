import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/auth/screens/landing_screen.dart';
import 'package:play_smart/auth/screens/sign_in_screen.dart';
import 'package:play_smart/auth/screens/sign_up_screen.dart';
import 'package:play_smart/auth/screens/splash_screen.dart';
import 'package:play_smart/profiles/screens/athlete_profile_screen.dart';
import 'package:play_smart/admin/screens/verification_screen.dart';
import 'package:play_smart/profiles/screens/athlete_setup_screen.dart';
import 'package:play_smart/profiles/screens/my_profile_screen.dart';
import 'package:play_smart/profiles/screens/edit_profile_screen.dart';
import 'package:play_smart/profiles/screens/saved_content_screen.dart';
import 'package:play_smart/profiles/screens/your_content_screen.dart';
import 'package:play_smart/profiles/screens/upload_screen.dart';
import 'package:play_smart/discovery/screens/discover_screen.dart';
import 'package:play_smart/discovery/screens/search_screen.dart';
import 'package:play_smart/shortlisting/screens/shortlist_screen.dart';
import 'package:play_smart/messaging/screens/messages_screen.dart';
import 'package:play_smart/opportunities/screens/opportunities_screen.dart';
import 'package:play_smart/notifications/screens/notifications_screen.dart';
import 'package:play_smart/payments/screens/billing_screen.dart';
import 'package:play_smart/core/shell/main_shell.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/settings/screens/privacy_safety_screen.dart';
import 'package:play_smart/settings/screens/help_support_screen.dart';

/// Centralised app router with bottom navigation shell.
///
/// Shell tab order (5 tabs):
///   0 — Discover
///   1 — Search
///   2 — Middle (Upload for athletes / Opportunities for recruiters & clubs)
///   3 — Messages
///   4 — Profile
///
/// Auth routes and onboarding sit outside the shell.
class AppRouter {
  AppRouter._();

  // Route path constants
  static const String splash = '/';
  static const String landing = '/landing';
  static const String signUp = '/signup';
  static const String signIn = '/signin';
  static const String athleteSetup = '/onboarding/athlete';
  static const String verification = '/onboarding/verification';
  static const String discover = '/discover';
  static const String search = '/search';
  static const String athleteProfile = '/athlete/:id';
  static const String myProfile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String upload = '/upload';
  static const String shortlists = '/shortlists';
  static const String myContent = '/profile/content';
  static const String saved = '/profile/saved';
  static const String opportunities = '/opportunities';
  static const String messages = '/messages';
  static const String notifications = '/notifications';
  static const String billing = '/account/billing';
  static const String admin = '/admin';
  static const String privacy = '/settings/privacy';
  static const String helpSupport = '/settings/help';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      // ── Auth routes (outside shell) ─────────────────────────────────────
      GoRoute(path: splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: landing, builder: (_, __) => const LandingScreen()),
      GoRoute(path: signUp, builder: (_, __) => const SignUpScreen()),
      GoRoute(
        path: signIn,
        builder: (_, state) => SignInScreen(prefillEmail: state.extra as String?),
      ),

      // ── Onboarding (outside shell) ──────────────────────────────────────
      GoRoute(path: athleteSetup, builder: (_, __) => const AthleteSetupScreen()),
      GoRoute(path: verification, builder: (_, __) => const VerificationScreen()),

      // ── Admin (outside shell, placeholder) ──────────────────────────────
      GoRoute(path: admin, builder: (_, __) => const _PlaceholderScreen(title: 'Admin')),

      // ── Settings screens (outside shell) ────────────────────────────────
      GoRoute(path: privacy, builder: (_, __) => const PrivacySafetyScreen()),
      GoRoute(path: helpSupport, builder: (_, __) => const HelpSupportScreen()),

      // ── Deep-link athlete profile (outside shell) ────────────────────────
      GoRoute(
        path: athleteProfile,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return AthleteProfileScreen(athleteId: id);
        },
      ),

      // ── Notifications (top-level so it can be pushed from anywhere) ──────
      GoRoute(
        path: notifications,
        builder: (_, __) => const NotificationsScreen(),
      ),

      // ── Billing (top-level so it can be pushed from anywhere) ────────────
      GoRoute(
        path: billing,
        builder: (_, __) => const BillingScreen(),
      ),



      // ── Shortlists (top-level so it can be pushed from anywhere) ─────────
      GoRoute(
        path: shortlists,
        builder: (_, __) => const ShortlistScreen(),
      ),

      // ── Main app shell with persistent bottom nav ────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          // Tab 0 — Discover
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: discover,
                builder: (_, __) => const DiscoverScreen(),
              ),
            ],
          ),

          // Tab 1 — Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: search,
                builder: (_, __) => const SearchScreen(),
              ),
            ],
          ),

          // Tab 2 — Middle: role-adaptive screen
          // A thin wrapper reads the user role and shows Upload or Opportunities.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: upload,
                builder: (_, __) => const _MiddleTabScreen(),
              ),
            ],
          ),

          // Tab 3 — Messages
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: messages,
                builder: (_, __) => const MessagesScreen(),
              ),
            ],
          ),

          // Tab 4 — Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: myProfile,
                builder: (_, __) => const MyProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'shortlists',
                    builder: (_, __) => const ShortlistScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (_, __) => const NotificationsScreen(),
                  ),
                  GoRoute(
                    path: 'billing',
                    builder: (_, __) => const BillingScreen(),
                  ),
                  GoRoute(
                    path: 'saved',
                    builder: (_, __) => const SavedContentScreen(),
                  ),
                  GoRoute(
                    path: 'content',
                    builder: (_, __) => const YourContentScreen(),
                  ),
                  GoRoute(
                    path: 'edit',
                    builder: (_, __) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

/// Middle tab (index 2) — shows UploadScreen for athletes,
/// OpportunitiesScreen for recruiters and clubs.
class _MiddleTabScreen extends ConsumerWidget {
  const _MiddleTabScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is AuthAuthenticated) {
      final role = authState.user.role;
      if (role == AccountRole.recruiter || role == AccountRole.club) {
        return const OpportunitiesScreen();
      }
    }

    return const UploadScreen();
  }
}

/// Temporary placeholder screen.
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.construction, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              const Text('Coming soon.', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go(AppRouter.discover),
                child: const Text('Go to Discover'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

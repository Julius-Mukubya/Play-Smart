import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Centralised app router with role-based access.
/// Currently using named routes for simplicity; can be upgraded to GoRouter's
/// redirect guards for role-based access control.
class AppRouter {
  AppRouter._();

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
  static const String upload = '/upload';
  static const String shortlists = '/shortlists';
  static const String opportunities = '/opportunities';
  static const String messages = '/messages';
  static const String notifications = '/notifications';
  static const String billing = '/account/billing';
  static const String admin = '/admin';

  static final GoRouter router = GoRouter(
    initialLocation: splash,
    routes: [
      GoRoute(path: splash, builder: (_, __) => const _PlaceholderScreen(title: 'Splash')),
      GoRoute(path: landing, builder: (_, __) => const _PlaceholderScreen(title: 'Landing / Home')),
      GoRoute(path: signUp, builder: (_, __) => const _PlaceholderScreen(title: 'Sign Up')),
      GoRoute(path: signIn, builder: (_, __) => const _PlaceholderScreen(title: 'Sign In')),
      GoRoute(path: athleteSetup, builder: (_, __) => const _PlaceholderScreen(title: 'Athlete Profile Setup')),
      GoRoute(path: verification, builder: (_, __) => const _PlaceholderScreen(title: 'Verification')),
      GoRoute(path: discover, builder: (_, __) => const _PlaceholderScreen(title: 'Discover Feed')),
      GoRoute(path: search, builder: (_, __) => const _PlaceholderScreen(title: 'Search')),
      GoRoute(path: athleteProfile, builder: (_, __) => const _PlaceholderScreen(title: 'Athlete Profile')),
      GoRoute(path: myProfile, builder: (_, __) => const _PlaceholderScreen(title: 'My Profile')),
      GoRoute(path: upload, builder: (_, __) => const _PlaceholderScreen(title: 'Upload')),
      GoRoute(path: shortlists, builder: (_, __) => const _PlaceholderScreen(title: 'Shortlists')),
      GoRoute(path: opportunities, builder: (_, __) => const _PlaceholderScreen(title: 'Opportunities')),
      GoRoute(path: messages, builder: (_, __) => const _PlaceholderScreen(title: 'Messages')),
      GoRoute(path: notifications, builder: (_, __) => const _PlaceholderScreen(title: 'Notifications')),
      GoRoute(path: billing, builder: (_, __) => const _PlaceholderScreen(title: 'Billing')),
      GoRoute(path: admin, builder: (_, __) => const _PlaceholderScreen(title: 'Admin')),
    ],
  );
}

/// Temporary placeholder screen until real screens are implemented.
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
              Text(
                title,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Coming soon — being implemented in the next feature unit.',
                textAlign: TextAlign.center,
              ),
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
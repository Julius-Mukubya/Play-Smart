import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/auth/screens/landing_screen.dart';
import 'package:play_smart/auth/screens/sign_in_screen.dart';
import 'package:play_smart/auth/screens/sign_up_screen.dart';
import 'package:play_smart/auth/screens/splash_screen.dart';
import 'package:play_smart/profiles/screens/athlete_profile_screen.dart';
import 'package:play_smart/admin/screens/verification_screen.dart';
import 'package:play_smart/profiles/screens/athlete_setup_screen.dart';
import 'package:play_smart/profiles/screens/my_profile_screen.dart';
import 'package:play_smart/profiles/screens/upload_screen.dart';
import 'package:play_smart/discovery/screens/discover_screen.dart';
import 'package:play_smart/discovery/screens/search_screen.dart';
import 'package:play_smart/shortlisting/screens/shortlist_screen.dart';
import 'package:play_smart/messaging/screens/messages_screen.dart';

/// Centralised app router with role-based access.
/// Auth routes use real screens. Other routes use placeholders until implemented.
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
      // Auth routes — implemented
      GoRoute(path: splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: landing, builder: (_, __) => const LandingScreen()),
      GoRoute(path: signUp, builder: (_, __) => const SignUpScreen()),
      GoRoute(path: signIn, builder: (_, __) => const SignInScreen()),

      // Other routes — placeholders
      GoRoute(path: athleteSetup, builder: (_, __) => const AthleteSetupScreen()),
      GoRoute(path: verification, builder: (_, __) => const VerificationScreen()),
      GoRoute(path: discover, builder: (_, __) => const DiscoverScreen()),
      GoRoute(path: search, builder: (_, __) => const SearchScreen()),
      GoRoute(
        path: athleteProfile,
        builder: (context, state) {
          final athleteId = state.pathParameters['id'] ?? '';
          return AthleteProfileScreen(athleteId: athleteId);
        },
      ),
      GoRoute(path: myProfile, builder: (_, __) => const MyProfileScreen()),
      GoRoute(path: upload, builder: (_, __) => const UploadScreen()),
      GoRoute(path: shortlists, builder: (_, __) => const ShortlistScreen()),
      GoRoute(path: opportunities, builder: (_, __) => const _PlaceholderScreen(title: 'Opportunities')),
      GoRoute(path: messages, builder: (_, __) => const MessagesScreen()),
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

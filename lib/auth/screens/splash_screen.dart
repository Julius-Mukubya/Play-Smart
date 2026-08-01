import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/router/app_router.dart';

/// Splash screen — initial app entry point.
/// Checks for existing session and redirects accordingly.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Schedule session check after the first frame is complete
    // This avoids "Tried to modify a provider while the widget tree was building" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);

    // Redirect based on auth state after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (authState is AuthAuthenticated) {
        context.go(AppRouter.discover);
      } else if (authState is AuthUnauthenticated) {
        context.go(AppRouter.discover);
      } else if (authState is AuthError) {
        context.go(AppRouter.discover);
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'lib/assets/images/logo_mark.png',
              height: 96,
            ),
            const SizedBox(height: 16),
            Text(
              'Play Smart',
              style: theme.textTheme.displayMedium,
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

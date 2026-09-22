import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/main.dart';

class FakeAuthNotifier extends AuthNotifier {
  @override
  AuthState build() => const AuthInitial();

  @override
  Future<void> checkSession() async {
    // No-op to prevent state transition and redirection during test
  }
}

void main() {
  testWidgets('Play Smart app renders with ProviderScope',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PlaySmartApp()),
    );

    // Pump with duration to let pending timers (SplashScreen session check) settle
    await tester.pump(const Duration(milliseconds: 200));

    // Verify MaterialApp.router is rendering
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('Splash screen shows VANTRA branding',
      (WidgetTester tester) async {
    AppRouter.router.go(AppRouter.splash);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(FakeAuthNotifier.new),
        ],
        child: const PlaySmartApp(),
      ),
    );

    // Verify the splash screen displays the app name
    expect(find.text('VANTRA'), findsOneWidget);
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/main.dart';

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

  testWidgets('Splash screen shows Play Smart branding',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PlaySmartApp()),
    );

    // Pump with duration to let pending timers settle
    await tester.pump(const Duration(milliseconds: 200));

    // The splash screen displays the app name
    expect(find.text('Play Smart'), findsWidgets);
  });
}
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/main.dart';

void main() {
  testWidgets('Play Smart app renders splash screen on start',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PlaySmartApp()),
    );

    // The app starts at the splash screen
    expect(find.text('Play Smart'), findsWidgets);

    // Loading indicator should be present
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Play Smart app navigates to landing when unauthenticated',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: PlaySmartApp()),
    );

    // Wait for the splash screen to check session and navigate
    await tester.pumpAndSettle();

    // Should be redirected to landing since no session exists
    expect(find.text('Discover. Connect. Play.'), findsOneWidget);
  });
}
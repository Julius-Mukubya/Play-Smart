import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/main.dart';

void main() {
  testWidgets('Play Smart app renders placeholder screen on splash route',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PlaySmartApp());

    // The app starts at the splash route — "Splash" text appears in both
    // the AppBar title and the body, so use findsWidgets
    expect(find.text('Splash'), findsWidgets);

    // The Go to Discover button should be present
    expect(find.text('Go to Discover'), findsOneWidget);
  });

  testWidgets('Play Smart app navigates to discover route',
      (WidgetTester tester) async {
    await tester.pumpWidget(const PlaySmartApp());

    // Tap the Go to Discover button
    await tester.tap(find.text('Go to Discover'));
    await tester.pumpAndSettle();

    // Should now be on the Discover Feed placeholder
    expect(find.text('Discover Feed'), findsWidgets);
  });
}
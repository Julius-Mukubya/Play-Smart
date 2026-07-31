import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/core/push/push_notification_service.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:play_smart/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  // No-ops safely until `flutterfire configure` has been run — see
  // PushNotificationService's doc comment.
  await PushNotificationService.instance.initialize();
  runApp(
    const ProviderScope(
      child: PlaySmartApp(),
    ),
  );
}

class PlaySmartApp extends ConsumerWidget {
  const PlaySmartApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Play Smart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
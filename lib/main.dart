import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/core/theme/app_theme.dart';

void main() {
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
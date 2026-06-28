import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/core/theme/app_theme.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://yfromhczuwahjzxpwuyf.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inlmcm9taGN6dXdhaGp6eHB3dXlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI1OTkzOTAsImV4cCI6MjA5ODE3NTM5MH0.dzsakJ9guNVnOkNtEa5Nf9-c1AqJ-Wly8l-jtjCsEhg',
  );

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
      title: 'PlaySmart',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: AppRouter.router,
    );
  }
}
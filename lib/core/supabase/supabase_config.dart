import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Initializes the Supabase client. Call once, before `runApp`.
///
/// Reads `SUPABASE_URL` / `SUPABASE_ANON_KEY` from `.env` (see `.env.example`).
/// Never put the `service_role` key here — it bypasses every RLS policy and is
/// server-only (Edge Functions, admin tooling).
class SupabaseConfig {
  static Future<void> initialize() async {
    await dotenv.load(fileName: '.env');
    await Supabase.initialize(
      url: dotenv.get('SUPABASE_URL'),
      publishableKey: dotenv.get('SUPABASE_ANON_KEY'),
    );
  }
}

/// Shorthand accessor used throughout the repositories.
SupabaseClient get supabase => Supabase.instance.client;

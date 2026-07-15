import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Analytics repository — profile view/shortlist tracking via RPCs rather
/// than direct table access. There is no client insert or select grant on
/// `public.analytics_events` at all (viewer identity must not be spoofable,
/// and free-tier athletes must not see full per-viewer data) — every read
/// and write goes through a Postgres function that enforces the free/premium
/// split server-side. See `lib/supabase-integration.md` section 4.
class AnalyticsRepository {
  /// Record a profile view. Never inserts into `analytics_events` directly.
  Future<void> recordView({
    required String athleteId,
    String? viewerId,
    String? viewerName,
  }) async {
    await supabase.rpc('record_profile_view', params: {'p_athlete_id': athleteId});
  }

  /// Get aggregate view count for an athlete (free tier — safe for anyone to call).
  Future<int> getViewCount(String athleteId) async {
    final result = await supabase.rpc('get_view_count', params: {'p_athlete_id': athleteId});
    return result as int;
  }

  /// Get shortlist count for an athlete.
  Future<int> getShortlistCount(String athleteId) async {
    final result =
        await supabase.rpc('get_shortlist_count', params: {'p_athlete_id': athleteId});
    return result as int;
  }

  /// Full per-viewer analytics (premium tier only). The RPC raises unless the
  /// athlete's own subscription is `premium_monthly`/`premium_annual` — that
  /// exception surfaces here rather than being checked client-side, since the
  /// client must not be trusted to enforce the tier gate.
  Future<List<AnalyticsEvent>> getFullAnalytics(String athleteId) async {
    final rows = await supabase.rpc('get_full_analytics', params: {'p_athlete_id': athleteId});
    return (rows as List).map((r) => AnalyticsEvent.fromJson(r as Map<String, dynamic>)).toList();
  }
}

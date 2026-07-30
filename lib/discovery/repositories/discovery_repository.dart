import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/discovery/models/feed_item.dart';
import 'package:play_smart/profiles/repositories/profile_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Discovery repository — search, filtering, and feed queries against
/// `public.athletes`. Structured filters run server-side via Postgrest;
/// engagement counts on `FeedItem` come from `athlete_content.like_count`/
/// `comment_count` (see `context/supabase-backend.md` section 4.2 for the
/// `content_likes`/`content_comments` tables backing those counters).
class DiscoveryRepository {
  static const _table = 'athletes';
  static const _selectWithRelations = '*, achievements(*), athlete_content(*)';

  final ProfileRepository _profileRepository;

  DiscoveryRepository({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? ProfileRepository();

  /// Get all athletes for the discover feed.
  Future<List<Athlete>> getDiscoverFeed() => _profileRepository.getAllAthletes();

  /// Get a content-first feed — each athlete's content pieces become
  /// individual feed cards, interleaved so the feed feels varied.
  Future<List<FeedItem>> getContentFeed() async {
    final athletes = await _profileRepository.getAllAthletes();

    final List<List<FeedItem>> byAthlete = athletes
        .where((a) => a.content.isNotEmpty)
        .map((a) => a.content
            .map((c) => FeedItem(
                  content: c,
                  athlete: a,
                  likeCount: c.likeCount,
                  commentCount: c.commentCount,
                ))
            .toList())
        .toList();

    // Round-robin interleave so different athletes alternate in the feed.
    final List<FeedItem> feed = [];
    int maxLen = byAthlete.fold(0, (m, l) => l.length > m ? l.length : m);
    int adCount = 1;
    for (int i = 0; i < maxLen; i++) {
      for (final list in byAthlete) {
        if (i < list.length) {
          feed.add(list[i]);
          if (feed.length % 3 == 2) {
            feed.add(FeedItem(
              isAd: true,
              adTitle: adCount == 1 ? 'MTN Sports Uganda' : 'Nike Football Academy',
              adDescription: adCount == 1
                  ? 'Connect with MTN Sports for exclusive grassroots tournaments, kits, and training camps!'
                  : 'Enroll in the Nike Elite Academy trials. Register now to showcase your skills to international scouts.',
              adImageUrl: adCount == 1
                  ? 'https://images.unsplash.com/photo-1508098682722-e99c43a406b2?w=800'
                  : 'https://images.unsplash.com/photo-1541252260730-0412e8e2108e?w=800',
            ));
            adCount = adCount == 1 ? 2 : 1;
          }
        }
      }
    }

    return feed;
  }

  /// Search athletes with a free-text query and/or structured filters.
  /// `query` matches against `display_name` only — fuzzy matching across
  /// `sports`/`positions` arrays isn't supported server-side; use the
  /// structured `sport`/`position` filters for those (exact value match).
  Future<List<Athlete>> searchAthletes({
    String? query,
    String? sport,
    String? position,
    int? minAge,
    int? maxAge,
    String? location,
    AvailabilityStatus? availability,
    TrustBadgeLevel? minBadge,
  }) async {
    var builder = supabase.from(_table).select(_selectWithRelations);
    if (query != null && query.isNotEmpty) {
      builder = builder.ilike('display_name', '%$query%');
    }
    if (sport != null && sport.isNotEmpty) {
      builder = builder.contains('sports', [sport]);
    }
    if (position != null && position.isNotEmpty) {
      builder = builder.contains('positions', [position]);
    }
    if (minAge != null) builder = builder.gte('age', minAge);
    if (maxAge != null) builder = builder.lte('age', maxAge);
    if (location != null && location.isNotEmpty) {
      builder = builder.or('city.ilike.%$location%,country.ilike.%$location%');
    }
    if (availability != null) {
      builder = builder.eq('availability_status', availability.toDb());
    }
    if (minBadge != null) {
      builder = builder.gte('profile_badge_level', minBadge.toDb());
    }
    final rows = await builder;
    return (rows as List).map((r) => Athlete.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Get recommended athletes for a recruiter based on saved preferences.
  Future<List<Athlete>> getRecommendedFeed({
    List<String>? preferredSports,
    List<String>? preferredPositions,
  }) async {
    var builder = supabase.from(_table).select(_selectWithRelations);
    if (preferredSports != null && preferredSports.isNotEmpty) {
      builder = builder.overlaps('sports', preferredSports);
    }
    if (preferredPositions != null && preferredPositions.isNotEmpty) {
      builder = builder.overlaps('positions', preferredPositions);
    }
    final rows = await builder;
    return (rows as List).map((r) => Athlete.fromJson(r as Map<String, dynamic>)).toList();
  }
}

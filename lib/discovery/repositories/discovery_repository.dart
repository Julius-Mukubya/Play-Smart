import 'package:play_smart/discovery/models/feed_item.dart';
import 'package:play_smart/profiles/repositories/profile_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Discovery repository — handles search, filtering, and feed operations.
/// Uses ProfileRepository for athlete data; can be extended with Algolia/Postgres.
class DiscoveryRepository {
  final ProfileRepository _profileRepository;

  DiscoveryRepository({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? ProfileRepository();

  /// Get all athletes for the discover feed.
  List<Athlete> getDiscoverFeed() {
    return _profileRepository.getAllAthletes();
  }

  /// Get a content-first feed — each athlete's content pieces become individual
  /// feed cards, interleaved so the feed feels varied.
  List<FeedItem> getContentFeed() {
    final athletes = _profileRepository.getAllAthletes();

    // Expand each athlete's content into individual FeedItems, then interleave
    // by athlete so the feed isn't just one athlete's content in a row.
    final List<List<FeedItem>> byAthlete = athletes
        .where((a) => a.content.isNotEmpty)
        .map((a) => a.content
            .map((c) => FeedItem(
                  content: c,
                  athlete: a,
                  // Mock engagement counts — replace with real data later
                  likeCount: (a.id.hashCode.abs() % 200) + 10,
                  commentCount: (c.id.hashCode.abs() % 40) + 1,
                ))
            .toList())
        .toList();

    // Round-robin interleave so different athletes alternate in the feed
    final List<FeedItem> feed = [];
    int maxLen = byAthlete.fold(0, (m, l) => l.length > m ? l.length : m);
    for (int i = 0; i < maxLen; i++) {
      for (final list in byAthlete) {
        if (i < list.length) feed.add(list[i]);
      }
    }

    // Athletes with no content still appear as a profile card at the end
    // (handled separately in the screen via getDiscoverFeed).
    return feed;
  }

  /// Search athletes with filters.
  List<Athlete> searchAthletes({
    String? query,
    String? sport,
    String? position,
    int? minAge,
    int? maxAge,
    String? location,
    AvailabilityStatus? availability,
    TrustBadgeLevel? minBadge,
  }) {
    var results = _profileRepository.getAllAthletes();

    // Text search across name, sport, position
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results.where((a) =>
          a.displayName.toLowerCase().contains(q) ||
          a.sports.any((s) => s.toLowerCase().contains(q)) ||
          a.positions.any((p) => p.toLowerCase().contains(q))).toList();
    }

    // Apply structured filters
    if (sport != null && sport.isNotEmpty) {
      results = results.where((a) =>
          a.sports.any((s) => s.toLowerCase().contains(sport.toLowerCase()))).toList();
    }
    if (position != null && position.isNotEmpty) {
      results = results.where((a) =>
          a.positions.any((p) => p.toLowerCase().contains(position.toLowerCase()))).toList();
    }
    if (minAge != null) {
      results = results.where((a) => (a.age ?? 0) >= minAge).toList();
    }
    if (maxAge != null) {
      results = results.where((a) => (a.age ?? 999) <= maxAge).toList();
    }
    if (location != null && location.isNotEmpty) {
      results = results.where((a) =>
          (a.city?.toLowerCase().contains(location.toLowerCase()) ?? false) ||
          (a.country?.toLowerCase().contains(location.toLowerCase()) ?? false)).toList();
    }
    if (availability != null) {
      results = results.where((a) => a.availabilityStatus == availability).toList();
    }
    if (minBadge != null) {
      results = results.where((a) =>
          a.profileBadgeLevel.index >= minBadge.index).toList();
    }

    return results;
  }

  /// Get recommended athletes for a recruiter based on profile preferences.
  List<Athlete> getRecommendedFeed({
    List<String>? preferredSports,
    List<String>? preferredPositions,
  }) {
    var results = _profileRepository.getAllAthletes();

    if (preferredSports != null && preferredSports.isNotEmpty) {
      results = results.where((a) =>
          a.sports.any((s) => preferredSports.any((ps) =>
              s.toLowerCase().contains(ps.toLowerCase())))).toList();
    }

    if (preferredPositions != null && preferredPositions.isNotEmpty) {
      results = results.where((a) =>
          a.positions.any((p) => preferredPositions.any((pp) =>
              p.toLowerCase().contains(pp.toLowerCase())))).toList();
    }

    return results;
  }
}
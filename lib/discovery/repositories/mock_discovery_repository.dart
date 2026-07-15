import 'package:play_smart/discovery/models/feed_item.dart';
import 'package:play_smart/profiles/repositories/mock_profile_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// In-memory discovery repository used by unit tests. Not wired into the app
/// — see `DiscoveryRepository` (Supabase-backed) for the production implementation.
class MockDiscoveryRepository {
  final MockProfileRepository _profileRepository;

  MockDiscoveryRepository({MockProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? MockProfileRepository();

  List<Athlete> getDiscoverFeed() {
    return _profileRepository.getAllAthletes();
  }

  List<FeedItem> getContentFeed() {
    final athletes = _profileRepository.getAllAthletes();

    final List<List<FeedItem>> byAthlete = athletes
        .where((a) => a.content.isNotEmpty)
        .map((a) => a.content
            .map((c) => FeedItem(
                  content: c,
                  athlete: a,
                  likeCount: (a.id.hashCode.abs() % 200) + 10,
                  commentCount: (c.id.hashCode.abs() % 40) + 1,
                ))
            .toList())
        .toList();

    final List<FeedItem> feed = [];
    int maxLen = byAthlete.fold(0, (m, l) => l.length > m ? l.length : m);
    for (int i = 0; i < maxLen; i++) {
      for (final list in byAthlete) {
        if (i < list.length) feed.add(list[i]);
      }
    }

    return feed;
  }

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

    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      results = results.where((a) =>
          a.displayName.toLowerCase().contains(q) ||
          a.sports.any((s) => s.toLowerCase().contains(q)) ||
          a.positions.any((p) => p.toLowerCase().contains(q))).toList();
    }

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

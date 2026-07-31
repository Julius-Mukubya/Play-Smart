import 'package:play_smart/discovery/models/feed_item.dart';
import 'package:play_smart/profiles/repositories/profile_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Mock/In-memory Discovery repository — ready to be wired up with Firebase Firestore.
class DiscoveryRepository {
  final ProfileRepository _profileRepository;

  DiscoveryRepository({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? ProfileRepository();

  Future<List<Athlete>> getDiscoverFeed() => _profileRepository.getAllAthletes();

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
    return _profileRepository.searchAthletes(
      sport: sport,
      position: position,
      minAge: minAge,
      maxAge: maxAge,
      location: location,
      availability: availability,
      minBadge: minBadge,
    );
  }

  Future<List<Athlete>> getRecommendedFeed({
    List<String>? preferredSports,
    List<String>? preferredPositions,
  }) async {
    return _profileRepository.getAllAthletes();
  }
}

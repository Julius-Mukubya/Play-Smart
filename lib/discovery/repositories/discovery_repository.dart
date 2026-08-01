import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:play_smart/discovery/models/comment_model.dart';
import 'package:play_smart/discovery/models/feed_item.dart';
import 'package:play_smart/profiles/repositories/profile_repository.dart';
import 'package:play_smart/profiles/repositories/content_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Discovery repository — manages feeds by merging profiles and Cloud Storage / Firestore content.
class DiscoveryRepository {
  final ProfileRepository _profileRepository;
  final ContentRepository _contentRepository;
  final FirebaseFirestore _firestore;

  // Local fallback storage for likes, comments, saves
  final Set<String> _likedContentIds = {};
  final Set<String> _savedContentIds = {};
  final Map<String, List<Comment>> _commentsStore = {};

  DiscoveryRepository({
    ProfileRepository? profileRepository,
    ContentRepository? contentRepository,
    FirebaseFirestore? firestore,
  })  : _profileRepository = profileRepository ?? ProfileRepository(),
        _contentRepository = contentRepository ?? ContentRepository(),
        _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Athlete>> getDiscoverFeed() async {
    final athletes = await _profileRepository.getAllAthletes();
    final List<Athlete> enriched = [];
    for (final athlete in athletes) {
      final contentList = await _contentRepository.getContentByAthleteId(athlete.id);
      enriched.add(athlete.copyWith(content: contentList));
    }
    return enriched;
  }

  Future<List<FeedItem>> getContentFeed({String? currentUserId}) async {
    final athletes = await getDiscoverFeed();

    final List<List<FeedItem>> byAthlete = athletes
        .where((a) => a.content.isNotEmpty)
        .map((a) => a.content
            .map((c) => FeedItem(
                  content: c,
                  athlete: a,
                  likeCount: c.likeCount,
                  commentCount: c.commentCount,
                  isLiked: _likedContentIds.contains(c.id),
                  isSaved: _savedContentIds.contains(c.id),
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

  // ── Firestore Likes ──────────────────────────────────────────
  Future<bool> toggleLike(String contentId, String userId) async {
    final isCurrentlyLiked = _likedContentIds.contains(contentId);
    if (isCurrentlyLiked) {
      _likedContentIds.remove(contentId);
    } else {
      _likedContentIds.add(contentId);
    }

    try {
      final docRef = _firestore.collection('athlete_content').doc(contentId);
      final likeRef = docRef.collection('likes').doc(userId);

      if (isCurrentlyLiked) {
        await likeRef.delete();
        await docRef.update({'likeCount': FieldValue.increment(-1)});
      } else {
        await likeRef.set({'timestamp': FieldValue.serverTimestamp()});
        await docRef.update({'likeCount': FieldValue.increment(1)});
      }
    } catch (_) {
      // Ephemeral fallback
    }
    return !isCurrentlyLiked;
  }

  // ── Firestore Save / Bookmark ────────────────────────────────
  Future<bool> toggleSave(String contentId, String userId) async {
    final isCurrentlySaved = _savedContentIds.contains(contentId);
    if (isCurrentlySaved) {
      _savedContentIds.remove(contentId);
    } else {
      _savedContentIds.add(contentId);
    }

    try {
      final userSavedRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('saved_items')
          .doc(contentId);

      if (isCurrentlySaved) {
        await userSavedRef.delete();
      } else {
        await userSavedRef.set({
          'contentId': contentId,
          'savedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (_) {
      // Ephemeral fallback
    }
    return !isCurrentlySaved;
  }

  // ── Firestore Comments ───────────────────────────────────────
  Future<List<Comment>> getComments(String contentId) async {
    try {
      final snap = await _firestore
          .collection('athlete_content')
          .doc(contentId)
          .collection('comments')
          .orderBy('createdAt', descending: true)
          .get();

      if (snap.docs.isNotEmpty) {
        final comments = snap.docs.map((d) => Comment.fromFirestore(d)).toList();
        _commentsStore[contentId] = comments;
        return comments;
      }
    } catch (_) {
      // Ephemeral fallback
    }
    return _commentsStore[contentId] ?? [];
  }

  Future<Comment> addComment({
    required String contentId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String text,
  }) async {
    final comment = Comment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      contentId: contentId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      text: text,
      createdAt: DateTime.now(),
    );

    _commentsStore.putIfAbsent(contentId, () => []).insert(0, comment);

    try {
      final contentDoc = _firestore.collection('athlete_content').doc(contentId);
      await contentDoc.collection('comments').add(comment.toFirestore());
      await contentDoc.update({'commentCount': FieldValue.increment(1)});
    } catch (_) {
      // Ephemeral fallback
    }

    return comment;
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
    final results = await _profileRepository.searchAthletes(
      sport: sport,
      position: position,
      minAge: minAge,
      maxAge: maxAge,
      location: location,
      availability: availability,
      minBadge: minBadge,
    );
    
    final List<Athlete> enriched = [];
    for (final athlete in results) {
      final contentList = await _contentRepository.getContentByAthleteId(athlete.id);
      enriched.add(athlete.copyWith(content: contentList));
    }
    return enriched;
  }

  Future<List<Athlete>> getRecommendedFeed({
    List<String>? preferredSports,
    List<String>? preferredPositions,
  }) async {
    return getDiscoverFeed();
  }
}

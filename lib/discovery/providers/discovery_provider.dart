import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/discovery/models/feed_item.dart';
import 'package:play_smart/discovery/repositories/discovery_repository.dart';
import 'package:play_smart/profiles/providers/profile_provider.dart';
import 'package:play_smart/profiles/providers/content_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Discovery repository provider.
final discoveryRepositoryProvider = Provider<DiscoveryRepository>((ref) {
  final profileRepo = ref.watch(profileRepositoryOnlyProvider);
  final contentRepo = ref.watch(contentRepositoryProvider);
  return DiscoveryRepository(
    profileRepository: profileRepo,
    contentRepository: contentRepo,
  );
});

/// Search filters state.
class SearchFilters {
  final String? query;
  final String? sport;
  final String? position;
  final int? minAge;
  final int? maxAge;
  final String? location;
  final AvailabilityStatus? availability;
  final TrustBadgeLevel? minBadge;

  const SearchFilters({
    this.query,
    this.sport,
    this.position,
    this.minAge,
    this.maxAge,
    this.location,
    this.availability,
    this.minBadge,
  });

  SearchFilters copyWith({
    String? query,
    String? sport,
    String? position,
    int? minAge,
    int? maxAge,
    String? location,
    AvailabilityStatus? availability,
    TrustBadgeLevel? minBadge,
    bool clearQuery = false,
    bool clearSport = false,
    bool clearPosition = false,
    bool clearLocation = false,
    bool clearAvailability = false,
    bool clearMinBadge = false,
  }) {
    return SearchFilters(
      query: clearQuery ? null : (query ?? this.query),
      sport: clearSport ? null : (sport ?? this.sport),
      position: clearPosition ? null : (position ?? this.position),
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      location: clearLocation ? null : (location ?? this.location),
      availability: clearAvailability ? null : (availability ?? this.availability),
      minBadge: clearMinBadge ? null : (minBadge ?? this.minBadge),
    );
  }

  int get activeFilterCount {
    int count = 0;
    if (sport != null) count++;
    if (position != null) count++;
    if (minAge != null || maxAge != null) count++;
    if (location != null) count++;
    if (availability != null) count++;
    if (minBadge != null) count++;
    return count;
  }
}

/// Discovery state.
class DiscoveryState {
  final List<Athlete> athletes;
  final List<FeedItem> feedItems;
  final Set<String> likedContentIds;  // content IDs the current user has liked
  final Set<String> bookmarkedContentIds; // content IDs the current user has bookmarked
  final bool isLoading;
  final String? error;
  final SearchFilters filters;

  const DiscoveryState({
    this.athletes = const [],
    this.feedItems = const [],
    this.likedContentIds = const {},
    this.bookmarkedContentIds = const {},
    this.isLoading = false,
    this.error,
    this.filters = const SearchFilters(),
  });

  DiscoveryState copyWith({
    List<Athlete>? athletes,
    List<FeedItem>? feedItems,
    Set<String>? likedContentIds,
    Set<String>? bookmarkedContentIds,
    bool? isLoading,
    String? error,
    SearchFilters? filters,
    bool clearError = false,
  }) {
    return DiscoveryState(
      athletes: athletes ?? this.athletes,
      feedItems: feedItems ?? this.feedItems,
      likedContentIds: likedContentIds ?? this.likedContentIds,
      bookmarkedContentIds: bookmarkedContentIds ?? this.bookmarkedContentIds,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filters: filters ?? this.filters,
    );
  }
}

/// Discovery notifier — manages search, filter, and feed state.
class DiscoveryNotifier extends Notifier<DiscoveryState> {
  @override
  DiscoveryState build() {
    return DiscoveryState();
  }

  DiscoveryRepository get _repository => ref.read(discoveryRepositoryProvider);

  /// Load the discover feed (both athlete list and content feed).
  Future<void> loadDiscoverFeed() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final athletes = await _repository.getDiscoverFeed();
      final feedItems = await _repository.getContentFeed();
      state = state.copyWith(
        athletes: athletes,
        feedItems: feedItems,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Toggle like on a content item.
  Future<void> toggleLike(String contentId, String userId) async {
    final liked = Set<String>.from(state.likedContentIds);
    final isLiked = liked.contains(contentId);
    if (isLiked) {
      liked.remove(contentId);
    } else {
      liked.add(contentId);
    }

    // Optimistically update state
    final updatedFeed = state.feedItems.map((item) {
      if (item.content?.id == contentId) {
        return item.copyWith(
          isLiked: !isLiked,
          likeCount: isLiked ? (item.likeCount - 1).clamp(0, 99999) : item.likeCount + 1,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(likedContentIds: liked, feedItems: updatedFeed);
    await _repository.toggleLike(contentId, userId);
  }

  /// Whether a content item is liked by the current user.
  bool isLiked(String contentId) => state.likedContentIds.contains(contentId);

  /// Toggle bookmark/save on a content item.
  Future<void> toggleBookmark(String contentId, String userId) async {
    final bookmarks = Set<String>.from(state.bookmarkedContentIds);
    final isSaved = bookmarks.contains(contentId);
    if (isSaved) {
      bookmarks.remove(contentId);
    } else {
      bookmarks.add(contentId);
    }

    final updatedFeed = state.feedItems.map((item) {
      if (item.content?.id == contentId) {
        return item.copyWith(isSaved: !isSaved);
      }
      return item;
    }).toList();

    state = state.copyWith(bookmarkedContentIds: bookmarks, feedItems: updatedFeed);
    await _repository.toggleSave(contentId, userId);
  }

  /// Add a comment to a content item.
  Future<void> addComment({
    required String contentId,
    required String userId,
    required String userName,
    String? userAvatar,
    required String text,
  }) async {
    await _repository.addComment(
      contentId: contentId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      text: text,
    );

    final updatedFeed = state.feedItems.map((item) {
      if (item.content?.id == contentId) {
        return item.copyWith(commentCount: item.commentCount + 1);
      }
      return item;
    }).toList();

    state = state.copyWith(feedItems: updatedFeed);
  }

  /// Whether a content item is bookmarked by the current user.
  bool isBookmarked(String contentId) => state.bookmarkedContentIds.contains(contentId);

  /// Search athletes with current filters.
  Future<void> search() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final results = await _repository.searchAthletes(
        query: state.filters.query,
        sport: state.filters.sport,
        position: state.filters.position,
        minAge: state.filters.minAge,
        maxAge: state.filters.maxAge,
        location: state.filters.location,
        availability: state.filters.availability,
        minBadge: state.filters.minBadge,
      );
      state = state.copyWith(athletes: results, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Update a filter and re-search.
  void updateFilters(SearchFilters newFilters) {
    state = state.copyWith(filters: newFilters);
    search();
  }

  /// Set search text query (doesn't auto-search — user must trigger search).
  void setQuery(String query) {
    state = state.copyWith(
      filters: state.filters.copyWith(query: query.isNotEmpty ? query : null, clearQuery: query.isEmpty),
    );
  }

  /// Clear all filters.
  void clearFilters() {
    state = state.copyWith(
      filters: const SearchFilters(),
    );
    loadDiscoverFeed();
  }
}

/// Discovery state provider.
final discoveryProvider = NotifierProvider<DiscoveryNotifier, DiscoveryState>(
  DiscoveryNotifier.new,
);
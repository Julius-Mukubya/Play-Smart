import 'package:play_smart/shared/types/domain_types.dart';

/// A single item in the discover feed.
/// Bundles a piece of athlete content with its owning athlete profile
/// so the feed card has everything it needs without extra lookups.
class FeedItem {
  final AthleteContent? content;
  final Athlete? athlete;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final bool isLiked;
  final bool isSaved;
  final bool isAd;
  final String? adTitle;
  final String? adDescription;
  final String? adImageUrl;

  const FeedItem({
    this.content,
    this.athlete,
    this.likeCount = 0,
    this.commentCount = 0,
    this.shareCount = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isAd = false,
    this.adTitle,
    this.adDescription,
    this.adImageUrl,
  });

  FeedItem copyWith({
    AthleteContent? content,
    Athlete? athlete,
    int? likeCount,
    int? commentCount,
    int? shareCount,
    bool? isLiked,
    bool? isSaved,
    bool? isAd,
    String? adTitle,
    String? adDescription,
    String? adImageUrl,
  }) {
    return FeedItem(
      content: content ?? this.content,
      athlete: athlete ?? this.athlete,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isAd: isAd ?? this.isAd,
      adTitle: adTitle ?? this.adTitle,
      adDescription: adDescription ?? this.adDescription,
      adImageUrl: adImageUrl ?? this.adImageUrl,
    );
  }
}

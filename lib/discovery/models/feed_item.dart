import 'package:play_smart/shared/types/domain_types.dart';

/// A single item in the discover feed.
/// Bundles a piece of athlete content with its owning athlete profile
/// so the feed card has everything it needs without extra lookups.
class FeedItem {
  final AthleteContent content;
  final Athlete athlete;
  final int likeCount;
  final int commentCount;

  const FeedItem({
    required this.content,
    required this.athlete,
    this.likeCount = 0,
    this.commentCount = 0,
  });
}

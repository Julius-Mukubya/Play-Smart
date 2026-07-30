import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Thumbnail card for a piece of athlete content, used in content galleries
/// (My Profile, public Athlete Profile). Shows the actual uploaded photo —
/// or the video's `thumbnailUrl` once a thumbnail-generation pipeline
/// exists — falling back to a generic type icon when there's nothing to
/// load (e.g. videos today, which don't have a thumbnail yet).
class ContentThumbnail extends StatelessWidget {
  final AthleteContent content;
  final double width;
  final Widget? momentChip;
  final VoidCallback? onDelete;

  const ContentThumbnail({
    super.key,
    required this.content,
    this.width = 140,
    this.momentChip,
    this.onDelete,
  });

  IconData get _typeIcon => switch (content.type) {
        ContentType.video => Icons.videocam,
        ContentType.photo => Icons.photo,
        ContentType.post => Icons.article,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imageUrl = content.type == ContentType.photo ? content.fileUrl : content.thumbnailUrl;

    return Container(
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl != null)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, __) => _iconFallback(theme),
              errorWidget: (_, __, ___) => _iconFallback(theme),
            )
          else
            _iconFallback(theme),

          if (content.type == ContentType.video && imageUrl != null)
            const Center(
              child: Icon(Icons.play_circle_fill, size: 36, color: Colors.white70),
            ),

          if (onDelete != null)
            Positioned(
              top: 6,
              right: 6,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.75)],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    content.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (momentChip != null) ...[
                    const SizedBox(height: 4),
                    momentChip!,
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconFallback(ThemeData theme) => Center(
        child: Icon(_typeIcon, size: 32, color: theme.colorScheme.primary),
      );
}

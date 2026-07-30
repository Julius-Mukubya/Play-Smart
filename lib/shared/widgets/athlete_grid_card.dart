import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/trust_badge.dart';

/// Grid-tile variant of AthleteCard — a photo-forward card for use in
/// GridView-based results (search). AthleteCard's horizontal list-tile
/// layout stays as-is for shortlists/discover.
class AthleteGridCard extends StatelessWidget {
  final Athlete athlete;
  final bool showShortlistAction;
  final bool isShortlisted;
  final VoidCallback? onShortlist;

  const AthleteGridCard({
    super.key,
    required this.athlete,
    this.showShortlistAction = false,
    this.isShortlisted = false,
    this.onShortlist,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => context.push('/athlete/${athlete.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (athlete.photoUrl != null)
                    CachedNetworkImage(
                      imageUrl: athlete.photoUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _avatarFallback(theme),
                      errorWidget: (_, __, ___) => _avatarFallback(theme),
                    )
                  else
                    _avatarFallback(theme),
                  if (showShortlistAction)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onShortlist,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black45,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isShortlisted ? Icons.bookmark : Icons.bookmark_outline,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athlete.displayName,
                    style: theme.textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      athlete.sports.isNotEmpty ? athlete.sports.first : null,
                      athlete.positions.isNotEmpty ? athlete.positions.first : null,
                    ].whereType<String>().join(' · '),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  TrustBadge(level: athlete.profileBadgeLevel, size: BadgeSize.sm),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarFallback(ThemeData theme) => Container(
        color: theme.colorScheme.primaryContainer,
        child: Center(
          child: Text(
            athlete.displayName.isNotEmpty ? athlete.displayName[0].toUpperCase() : '?',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      );
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/trust_badge.dart';

/// Shared AthleteCard component used across the app.
/// Summary card for an athlete — used in discover feed, search results, shortlists.
class AthleteCard extends StatelessWidget {
  final Athlete athlete;
  final bool showShortlistAction;
  final bool isShortlisted;
  final VoidCallback? onShortlist;

  const AthleteCard({
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: () => context.push('/athlete/${athlete.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Athlete photo / avatar
              CircleAvatar(
                radius: 32,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  athlete.displayName.isNotEmpty
                      ? athlete.displayName[0].toUpperCase()
                      : '?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Athlete info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      athlete.displayName,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${athlete.sports.join(', ')} — ${athlete.positions.join(', ')}',
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (athlete.country != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.location_on_outlined,
                                size: 12, color: theme.colorScheme.primary),
                          ),
                        if (athlete.country != null)
                          Text(athlete.country!, style: theme.textTheme.bodySmall),
                        const SizedBox(width: 8),
                        TrustBadge(
                          level: athlete.profileBadgeLevel,
                          size: BadgeSize.sm,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Shortlist action
              if (showShortlistAction)
                IconButton(
                  icon: Icon(
                    isShortlisted ? Icons.bookmark : Icons.bookmark_outline,
                    color: isShortlisted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  onPressed: onShortlist,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
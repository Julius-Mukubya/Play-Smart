import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/theme/app_theme.dart';
import 'package:play_smart/messaging/providers/messaging_provider.dart';
import 'package:play_smart/profiles/providers/content_provider.dart';
import 'package:play_smart/profiles/providers/profile_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/app_dialog.dart';
import 'package:play_smart/shared/widgets/content_thumbnail.dart';

/// Athlete Profile — unified public view seen by recruiters, clubs, and guests.
class AthleteProfileScreen extends ConsumerStatefulWidget {
  final String athleteId;
  const AthleteProfileScreen({super.key, required this.athleteId});

  @override
  ConsumerState<AthleteProfileScreen> createState() => _AthleteProfileScreenState();
}

class _AthleteProfileScreenState extends ConsumerState<AthleteProfileScreen> {
  ContentType? _contentFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadAthleteProfile(widget.athleteId));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }
          return _buildProfileContent(context, theme, profile);
        },
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, ThemeData theme, Athlete athlete) {
    final sportsLabel = athlete.sports.isNotEmpty ? athlete.sports.join(', ') : 'User';

    // Calculate metrics
    final videoCount = athlete.content.where((c) => c.type == ContentType.video).length;
    final postCount = athlete.content.where((c) => c.type == ContentType.post).length;
    
    // Calculate mock/active friends count
    final activeFriends = ref.watch(messagingProvider).conversations.where((c) =>
        c.fromUserId == athlete.userId || c.toUserId == athlete.userId).length;
    final totalFriends = activeFriends + 4; // Mock standard baseline friends count

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section with profile details
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.08),
                  theme.colorScheme.surface,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    athlete.displayName.isNotEmpty
                        ? athlete.displayName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  athlete.displayName.toUpperCase(),
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  sportsLabel,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (athlete.positions.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    athlete.positions.join(', '),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _buildTrustBadge(athlete.profileBadgeLevel),
                if (athlete.city != null || athlete.country != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        [athlete.city, athlete.country].whereType<String>().join(', '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Unified Metrics Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem(theme, 'Videos', '$videoCount'),
                  Container(width: 1, height: 32, color: theme.colorScheme.outlineVariant),
                  _buildMetricItem(theme, 'Posts', '$postCount'),
                  Container(width: 1, height: 32, color: theme.colorScheme.outlineVariant),
                  _buildMetricItem(theme, 'Friends', '$totalFriends'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Primary Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () async {
                final messagingState = ref.read(messagingProvider);
                final isFriend = messagingState.conversations.any((c) =>
                    c.fromUserId == athlete.userId || c.toUserId == athlete.userId);
                if (isFriend) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('You are already connected/friends.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                final err = await ref.read(messagingProvider.notifier).sendRequest(
                      athlete.userId,
                      "Friend Request",
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(err ?? 'Friend Request Sent Successfully!'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Send Friend Request'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const Divider(height: 32),

          // About/Bio
          if (athlete.bio != null && athlete.bio!.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    athlete.bio!,
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                  ),
                ],
              ),
            ),
            const Divider(height: 32),
          ],

          // Content library with choice chip filters
          Padding(
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Content Library', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                
                // Filters row
                SizedBox(
                  height: 44,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip('All', null),
                      const SizedBox(width: 8),
                      _buildFilterChip('Videos', ContentType.video),
                      const SizedBox(width: 8),
                      _buildFilterChip('Photos', ContentType.photo),
                      const SizedBox(width: 8),
                      _buildFilterChip('Posts', ContentType.post),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Grid view content rendering
                (() {
                  final filtered = athlete.content.where((c) {
                    if (_contentFilter == null) return true;
                    return c.type == _contentFilter;
                  }).toList();

                  if (filtered.isNotEmpty) {
                    return SizedBox(
                      height: 170,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (ctx, i) {
                          final content = filtered[i];
                          return ContentThumbnail(
                            content: content,
                            width: 130,
                            onDelete: _isOwnProfile(athlete)
                                ? () => _confirmDeleteContent(context, content)
                                : null,
                          );
                        },
                      ),
                    );
                  } else {
                    return Container(
                      height: 100,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        athlete.content.isEmpty
                            ? 'No content uploaded yet'
                            : 'No matching items found',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }
                }()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, ContentType? type) {
    final isSelected = _contentFilter == type;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _contentFilter = type;
          });
        }
      },
      selectedColor: Theme.of(context).colorScheme.primary,
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? Colors.transparent : Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
    );
  }

  Widget _buildMetricItem(ThemeData theme, String label, String count) {
    return Column(
      children: [
        Text(
          count,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ],
    );
  }

  bool _isOwnProfile(Athlete athlete) {
    final authState = ref.read(authProvider);
    return authState is AuthAuthenticated && authState.user.id == athlete.userId;
  }

  void _confirmDeleteContent(BuildContext context, AthleteContent content) {
    AppDialog.show(
      context,
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.stateError,
      title: 'Remove Post',
      body: 'Remove "${content.title}" from your profile? This cannot be undone.',
      confirmLabel: 'Remove',
      cancelLabel: 'Keep It',
      destructive: true,
      onConfirm: () async {
        try {
          await ref.read(contentRepositoryProvider).deleteContent(content.id);
          await ref.read(profileProvider.notifier).loadAthleteProfile(widget.athleteId);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Could not remove post: $e')),
            );
          }
        }
      },
    );
  }

  Widget _buildTrustBadge(TrustBadgeLevel level) {
    final (label, color) = switch (level) {
      TrustBadgeLevel.selfReported => ('Self-Reported', AppColors.badgeSelf),
      TrustBadgeLevel.coachEndorsed => ('Coach-Endorsed', AppColors.badgeCoach),
      TrustBadgeLevel.clubVerified => ('Club-Verified', AppColors.badgeClub),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
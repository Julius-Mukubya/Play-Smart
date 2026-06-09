import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/core/theme/app_theme.dart';
import 'package:play_smart/profiles/providers/profile_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Athlete Profile — public view seen by recruiters, clubs, and guests.
class AthleteProfileScreen extends ConsumerStatefulWidget {
  final String athleteId;
  const AthleteProfileScreen({super.key, required this.athleteId});

  @override
  ConsumerState<AthleteProfileScreen> createState() => _AthleteProfileScreenState();
}

class _AthleteProfileScreenState extends ConsumerState<AthleteProfileScreen> {
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
        title: const Text('Athlete Profile'),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.1),
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
                Text(athlete.displayName, style: theme.textTheme.headlineMedium),
                const SizedBox(height: 4),
                Text(
                  athlete.sports.join(', '),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  athlete.positions.join(', '),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                // Trust badge
                _buildTrustBadge(athlete.profileBadgeLevel),
                const SizedBox(height: 8),
                // Availability
                _buildAvailabilityBadge(athlete.availabilityStatus),
                const SizedBox(height: 8),
                if (athlete.country != null || athlete.city != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        [athlete.city, athlete.country].where((e) => e != null).join(', '),
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.message_outlined),
                  label: const Text('Send Expression of Interest'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.bookmark_border),
                  label: const Text('Shortlist'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Bio
          if (athlete.bio != null && athlete.bio!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('About', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(athlete.bio!, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),

          // Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Stats', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _buildStatChip('Age', '${athlete.age ?? '-'}'),
                    if (athlete.height != null)
                      _buildStatChip('Height', '${athlete.height} cm'),
                    if (athlete.weight != null)
                      _buildStatChip('Weight', '${athlete.weight} kg'),
                    if (athlete.dominantFootHand != null)
                      _buildStatChip('Dominant', athlete.dominantFootHand!),
                    if (athlete.currentTeam != null)
                      _buildStatChip('Team', athlete.currentTeam!),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Achievements
          if (athlete.achievements.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Achievements', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  ...athlete.achievements.map((ach) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: _buildBadgeIcon(ach.badgeLevel),
                          title: Text(ach.title),
                          subtitle: ach.description.isNotEmpty
                              ? Text(ach.description)
                              : null,
                          trailing: ach.endorsedByName != null
                              ? Text(
                                  ach.endorsedByName!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.primary,
                                  ),
                                )
                              : null,
                        ),
                      )),
                ],
              ),
            ),

          // Content
          if (athlete.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Content', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: athlete.content.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (ctx, i) {
                        final content = athlete.content[i];
                        return Container(
                          width: 160,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                content.type == ContentType.video
                                    ? Icons.videocam
                                    : content.type == ContentType.photo
                                        ? Icons.photo
                                        : Icons.article,
                                size: 40,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(height: 8),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: Text(
                                  content.title,
                                  style: theme.textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (content.momentTag != null)
                                Chip(
                                  label: Text(
                                    content.momentTag!.name.toUpperCase(),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                  visualDensity: VisualDensity.compact,
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
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
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAvailabilityBadge(AvailabilityStatus status) {
    final (label, color) = switch (status) {
      AvailabilityStatus.openToTrials => ('Open to Trials', AppColors.stateSuccess),
      AvailabilityStatus.currentlyContracted => ('Currently Contracted', AppColors.stateWarning),
      AvailabilityStatus.notAvailable => ('Not Available', AppColors.stateError),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(TrustBadgeLevel level) {
    final color = switch (level) {
      TrustBadgeLevel.selfReported => AppColors.badgeSelf,
      TrustBadgeLevel.coachEndorsed => AppColors.badgeCoach,
      TrustBadgeLevel.clubVerified => AppColors.badgeClub,
    };
    return Icon(Icons.verified, color: color);
  }
}
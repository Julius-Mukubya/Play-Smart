import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/profiles/providers/profile_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/trust_badge.dart';
import 'package:go_router/go_router.dart';

/// Athlete's own profile — view, edit controls, and content management.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadMyProfile());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return _buildEmptyProfile(context, theme);
          }
          return _buildProfileWithEdit(context, theme, profile);
        },
      ),
    );
  }

  Widget _buildEmptyProfile(BuildContext context, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('Complete Your Profile', style: theme.textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              'Set up your athlete profile to get discovered by recruiters and clubs.',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(AppRouter.athleteSetup),
              child: const Text('Get Started'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileWithEdit(BuildContext context, ThemeData theme, Athlete athlete) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Profile completeness banner
          if (athlete.profileCompleteness < 1.0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: theme.colorScheme.primaryContainer,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: theme.colorScheme.onPrimaryContainer),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile ${(athlete.profileCompleteness * 100).toInt()}% complete',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: athlete.profileCompleteness,
                            backgroundColor: theme.colorScheme.surface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go(AppRouter.athleteSetup),
                    child: const Text('Complete'),
                  ),
                ],
              ),
            ),

          // Header
          Container(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    athlete.displayName.isNotEmpty
                        ? athlete.displayName[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(athlete.displayName, style: theme.textTheme.titleLarge),
                      Text(
                        athlete.sports.join(', '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => context.go(AppRouter.athleteSetup),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Quick stats
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickStat(theme, Icons.visibility_outlined, 'Profile Views', '12'),
                _buildQuickStat(theme, Icons.bookmark_outlined, 'Shortlisted', '3'),
                _buildQuickStat(theme, Icons.message_outlined, 'Messages', '2'),
              ],
            ),
          ),

          const Divider(),

          // Content upload button
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Content', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                SizedBox(
                  height: 48,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRouter.upload),
                        icon: const Icon(Icons.videocam, size: 18),
                        label: const Text('Video'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRouter.upload),
                        icon: const Icon(Icons.photo, size: 18),
                        label: const Text('Photo'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => context.go(AppRouter.upload),
                        icon: const Icon(Icons.article, size: 18),
                        label: const Text('Post'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content gallery
          if (athlete.content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: athlete.content.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (ctx, i) {
                    final content = athlete.content[i];
                    return Container(
                      width: 140,
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
                            size: 32,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              content.title,
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Achievements section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Achievements', style: theme.textTheme.titleLarge),
                    TextButton.icon(
                      onPressed: () => _showAddAchievementDialog(context, theme),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (athlete.achievements.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        'No achievements yet. Add your first achievement to build your profile.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else
                  ...athlete.achievements.map((ach) => _buildAchievementCard(theme, ach)),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(ThemeData theme, Achievement achievement) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.title, style: theme.textTheme.titleMedium),
                if (achievement.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(achievement.description, style: theme.textTheme.bodySmall),
                  ),
                const SizedBox(height: 8),
                TrustBadge(level: achievement.badgeLevel, size: BadgeSize.sm),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove Achievement'),
                  content: Text('Remove "${achievement.title}"?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        ref.read(profileProvider.notifier).removeAchievement(achievement.id);
                      },
                      child: Text('Remove', style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAddAchievementDialog(BuildContext context, ThemeData theme) async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Achievement'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'e.g. Top Scorer 2025',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'e.g. Scored 15 goals in the season',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => titleController.text.trim().isEmpty ? null : Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      final now = DateTime.now();
      ref.read(profileProvider.notifier).addAchievement(
        Achievement(
          id: 'ach-${now.millisecondsSinceEpoch}',
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          badgeLevel: TrustBadgeLevel.selfReported,
        ),
      );
    }

    titleController.dispose();
    descriptionController.dispose();
  }

  Widget _buildQuickStat(
      ThemeData theme, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
        )),
        Text(label, style: theme.textTheme.bodySmall),
      ],
    );
  }
}
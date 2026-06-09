import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/core/theme/app_theme.dart';
import 'package:play_smart/profiles/providers/profile_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
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
        ],
      ),
    );
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
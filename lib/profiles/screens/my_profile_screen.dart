import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/profiles/providers/profile_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/app_dialog.dart';
import 'package:play_smart/core/theme/app_theme.dart';
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
            onPressed: () => _showSettingsSheet(context),
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

  void _showSettingsSheet(BuildContext context) {
    final authState = ref.read(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // User info header
              if (user != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium),
                            Text(user.email,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall),
                          ],
                        ),
                      ),
                      // Role chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.role.name[0].toUpperCase() +
                              user.role.name.substring(1),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const Divider(),

              // Settings items
              _SettingsTile(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                onTap: () {
                  Navigator.pop(ctx);
                  context.go(AppRouter.athleteSetup);
                },
              ),
              _SettingsTile(
                icon: Icons.credit_card_outlined,
                label: 'Billing & Subscription',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRouter.billing);
                },
              ),
              _SettingsTile(
                icon: Icons.bookmark_outline,
                label: 'My Shortlists',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRouter.shortlists);
                },
              ),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRouter.notifications);
                },
              ),
              _SettingsTile(
                icon: Icons.shield_outlined,
                label: 'Privacy & Safety',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRouter.privacy);
                },
              ),
              _SettingsTile(
                icon: Icons.help_outline,
                label: 'Help & Support',
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(AppRouter.helpSupport);
                },
              ),

              const Divider(),

              // Sign out
              _SettingsTile(
                icon: Icons.logout,
                label: 'Sign Out',
                color: Theme.of(context).colorScheme.error,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmSignOut(context);
                },
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    AppDialog.show(
      context,
      icon: Icons.logout_rounded,
      iconColor: AppColors.stateError,
      title: 'Sign Out',
      body: 'You\'ll need to sign back in to access your profile and messages.',
      confirmLabel: 'Sign Out',
      cancelLabel: 'Stay Signed In',
      destructive: true,
      onConfirm: () {
        ref.read(authProvider.notifier).signOut().then((_) {
          if (context.mounted) context.go(AppRouter.landing);
        });
      },
    );
  }

  Widget _buildEmptyProfile(BuildContext context, ThemeData theme) {
    final authState = ref.read(authProvider);
    final user = authState is AuthAuthenticated ? authState.user : null;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Account header ────────────────────────────────────────────
          Container(
            color: theme.colorScheme.surface,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 44,
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    user != null && user.name.isNotEmpty
                        ? user.name[0].toUpperCase()
                        : '?',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Name
                Text(
                  user?.name ?? 'My Profile',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                // Email
                Text(
                  user?.email ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                // Role chip
                if (user != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.accentPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: AppColors.accentPrimary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      user.role.name[0].toUpperCase() +
                          user.role.name.substring(1),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.accentPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Profile completion prompt ─────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.accentPrimary.withValues(alpha: 0.08),
                  AppColors.accentLight.withValues(alpha: 0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.accentPrimary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.accentPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.rocket_launch_outlined,
                          color: AppColors.accentPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Complete your profile',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Add your sport, position, and highlights so recruiters and clubs can find you.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go(AppRouter.athleteSetup),
                    child: const Text('Get Started'),
                  ),
                ),
              ],
            ),
          ),

          // ── Account details section ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text('Account',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 0.5,
                )),
          ),
          _InfoTile(
            icon: Icons.person_outline,
            label: 'Name',
            value: user?.name ?? '—',
            theme: theme,
          ),
          _InfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: user?.email ?? '—',
            theme: theme,
          ),
          _InfoTile(
            icon: Icons.verified_user_outlined,
            label: 'Account status',
            value: user?.verificationStatus.name.capitalize() ?? '—',
            theme: theme,
          ),
          _InfoTile(
            icon: Icons.workspace_premium_outlined,
            label: 'Plan',
            value: _formatTier(user?.subscriptionTier),
            theme: theme,
          ),

          const SizedBox(height: 32),
        ],
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
              AppDialog.show(
                context,
                icon: Icons.delete_outline_rounded,
                iconColor: AppColors.stateError,
                title: 'Remove Achievement',
                body: 'Remove "${achievement.title}" from your profile?',
                confirmLabel: 'Remove',
                cancelLabel: 'Keep It',
                destructive: true,
                onConfirm: () => ref
                    .read(profileProvider.notifier)
                    .removeAchievement(achievement.id),
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

    await AppDialog.show(
      context,
      icon: Icons.emoji_events_outlined,
      title: 'Add Achievement',
      confirmLabel: 'Add',
      cancelLabel: 'Cancel',
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
      onConfirm: () {
        if (titleController.text.trim().isNotEmpty) {
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
      },
    );

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

/// Reusable list tile for the settings bottom sheet.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SettingsTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: effectiveColor, size: 22),
      title: Text(
        label,
        style: TextStyle(
          color: effectiveColor,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
      ),
      trailing: color == null
          ? Icon(Icons.chevron_right,
              color: Theme.of(context).colorScheme.outline, size: 20)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
    );
  }
}

/// Read-only info row used in the empty profile state.
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ThemeData theme;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderDefault, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textMuted),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textMuted)),
          ),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ── Helpers ──────────────────────────────────────────────────────────────────

String _formatTier(SubscriptionTier? tier) {
  if (tier == null) return '—';
  return switch (tier) {
    SubscriptionTier.free              => 'Free',
    SubscriptionTier.premiumMonthly    => 'Premium Monthly',
    SubscriptionTier.premiumAnnual     => 'Premium Annual',
    SubscriptionTier.recruiterBasic    => 'Recruiter Basic',
    SubscriptionTier.recruiterPro      => 'Recruiter Pro',
    SubscriptionTier.clubGrassroots    => 'Club Grassroots',
    SubscriptionTier.clubProfessional  => 'Club Professional',
    SubscriptionTier.clubEnterprise    => 'Club Enterprise',
  };
}

extension _StringExt on String {
  String capitalize() =>
      isEmpty ? this : this[0].toUpperCase() + substring(1);
}

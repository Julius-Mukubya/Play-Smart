import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/messaging/repositories/connection_repository.dart';
import 'package:play_smart/profiles/providers/content_provider.dart';
import 'package:play_smart/profiles/providers/profile_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/app_dialog.dart';
import 'package:play_smart/core/theme/app_theme.dart';
import 'package:play_smart/shared/widgets/content_thumbnail.dart';
import 'package:play_smart/shared/widgets/trust_badge.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/discovery/providers/discovery_provider.dart';

/// Athlete's own profile — view, edit controls, and content management.
class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  bool _isUploadingAvatar = false;
  ContentType? _contentFilter;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(profileProvider.notifier).loadMyProfile());
  }

  Future<void> _changeAvatar(Athlete athlete) async {
    final authState = ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;

    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;

      var bytes = await file.readAsBytes();
      try {
        bytes = await FlutterImageCompress.compressWithList(
          bytes,
          minWidth: 512,
          minHeight: 512,
          quality: 80,
        );
      } catch (_) {
        // keep original bytes
      }

      if (!mounted) return;
      setState(() => _isUploadingAvatar = true);

      final url = await ref.read(profileRepositoryProvider).uploadAvatar(
            userId: authState.user.id,
            filename: 'avatar.jpg',
            bytes: bytes,
          );
      await ref.read(profileProvider.notifier).updateProfile(athlete.copyWith(photoUrl: url));

      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isUploadingAvatar = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update profile picture: $e')),
      );
    }
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
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share profile',
            onPressed: () {
              final athlete = profileAsync.value;
              final targetId = athlete?.id ?? '';
              Clipboard.setData(ClipboardData(text: 'https://playsmart.app/athlete/$targetId'));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile link copied to clipboard! Ready to share.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Edit profile',
            onPressed: () => context.push(AppRouter.editProfile),
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

  Widget _buildSignOutButton(BuildContext context, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () => _confirmSignOut(context),
          icon: Icon(Icons.logout, color: theme.colorScheme.error),
          label: Text('Sign Out', style: TextStyle(color: theme.colorScheme.error)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.colorScheme.error),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  Future<void> _showSwitchAccountSheet(BuildContext context) async {
    final authState = ref.read(authProvider);
    final currentEmail = authState is AuthAuthenticated ? authState.user.email : null;
    final accounts = await ref.read(knownAccountsStoreProvider).getAll();

    if (!context.mounted) return;

    Future<void> switchTo(BuildContext sheetContext, String? email) async {
      Navigator.pop(sheetContext);
      await ref.read(authProvider.notifier).signOut();
      if (context.mounted) context.go(AppRouter.auth);
    }

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
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Switch Account',
                      style: Theme.of(ctx).textTheme.titleLarge),
                ),
              ),
              const SizedBox(height: 8),
              if (accounts.isNotEmpty) const Divider(height: 1),
              ...accounts.map((account) {
                final isCurrent = account.email == currentEmail;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(ctx).colorScheme.primaryContainer,
                    child: Text(
                      account.name.isNotEmpty
                          ? account.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(ctx).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  title: Text(account.name),
                  subtitle:
                      Text('${account.email} · ${account.role.name.capitalize()}'),
                  trailing: isCurrent
                      ? Icon(Icons.check_circle,
                          color: Theme.of(ctx).colorScheme.primary)
                      : null,
                  onTap: isCurrent ? null : () => switchTo(ctx, account.email),
                );
              }),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.person_add_alt_outlined),
                title: const Text('Add Another Account'),
                onTap: () => switchTo(ctx, null),
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
          if (context.mounted) context.go(AppRouter.discover);
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
                    onPressed: () => context.push(AppRouter.athleteSetup),
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

          const SizedBox(height: 16),

          // ── More section ────────────────────────────────────────────
          const SizedBox(height: 8),
          if ((user?.role == AccountRole.recruiter || user?.role == AccountRole.club) &&
              user?.verificationStatus != VerificationStatus.approved)
            _ActionTile(
              icon: Icons.verified_outlined,
              label: 'Apply for Verification',
              onTap: () => context.push(AppRouter.verification),
            ),
          _ActionTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => context.push(AppRouter.notifications),
          ),
          _ActionTile(
            icon: Icons.shield_outlined,
            label: 'Privacy & Safety',
            onTap: () => context.push(AppRouter.privacy),
          ),
          _ActionTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () => context.push(AppRouter.helpSupport),
          ),
          _ActionTile(
            icon: Icons.switch_account_outlined,
            label: 'Switch Account',
            onTap: () => _showSwitchAccountSheet(context),
          ),

          const SizedBox(height: 24),
          _buildSignOutButton(context, theme),
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
                    onPressed: () => context.push(AppRouter.athleteSetup),
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
                GestureDetector(
                  onTap: _isUploadingAvatar ? null : () => _changeAvatar(athlete),
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.primaryContainer,
                        backgroundImage: athlete.photoUrl != null
                            ? CachedNetworkImageProvider(athlete.photoUrl!)
                            : null,
                        child: athlete.photoUrl == null
                            ? Text(
                                athlete.displayName.isNotEmpty
                                    ? athlete.displayName[0].toUpperCase()
                                    : '?',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              )
                            : null,
                      ),
                      if (_isUploadingAvatar)
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              ),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.surface, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                    ],
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
                  onPressed: () => context.push(AppRouter.editProfile),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('Edit'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Content & Connection Stats
          Builder(
            builder: (context) {
              final videoCount = athlete.content.where((c) => c.type == ContentType.video).length;
              final postCount = athlete.content.where((c) => c.type != ContentType.video).length;
              final totalLikes = athlete.content.fold<int>(0, (sum, c) => sum + c.likeCount);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickStat(theme, Icons.videocam_outlined, 'Videos', '$videoCount'),
                    _buildQuickStat(theme, Icons.photo_library_outlined, 'Posts', '$postCount'),
                    _buildQuickStat(theme, Icons.thumb_up_alt_outlined, 'Likes', '$totalLikes'),
                    FutureBuilder<int>(
                      future: ref.watch(connectionRepositoryProvider).getFriendsCount(athlete.userId),
                      builder: (context, snap) {
                        return _buildQuickStat(theme, Icons.people_outline, 'Friends', '${snap.data ?? 0}');
                      },
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(),

          // Content upload button
          // ── More section ────────────────────────────────────────────
          const SizedBox(height: 16),
          _ActionTile(
            icon: Icons.video_library_outlined,
            label: 'Your Content',
            onTap: () => context.push(AppRouter.myContent),
          ),
          _ActionTile(
            icon: Icons.bookmark_border_rounded,
            label: 'Saved Content',
            onTap: () => context.push(AppRouter.saved),
          ),
          _ActionTile(
            icon: Icons.notifications_outlined,
            label: 'Notifications',
            onTap: () => context.push(AppRouter.notifications),
          ),
          _ActionTile(
            icon: Icons.shield_outlined,
            label: 'Privacy & Safety',
            onTap: () => context.push(AppRouter.privacy),
          ),
          _ActionTile(
            icon: Icons.help_outline,
            label: 'Help & Support',
            onTap: () => context.push(AppRouter.helpSupport),
          ),
          _ActionTile(
            icon: Icons.switch_account_outlined,
            label: 'Switch Account',
            onTap: () => _showSwitchAccountSheet(context),
          ),

          const SizedBox(height: 24),
          _buildSignOutButton(context, theme),
          const SizedBox(height: 24),
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
          await ref
              .read(contentRepositoryProvider)
              .deleteContent(content.id);
          // Same reason as after upload: MyProfileScreen reads athlete.content
          // from profileProvider (the embedded relation), not contentProvider.
          await ref.read(profileProvider.notifier).loadMyProfile();
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

  Widget _buildAllFilterChip() {
    final isSelected = _contentFilter == null;
    return ChoiceChip(
      avatar: Icon(
        Icons.select_all_rounded,
        size: 16,
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        'All',
        style: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _contentFilter = null;
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

  Widget _buildFilterChip(ContentType type, IconData icon, String label) {
    final isSelected = _contentFilter == type;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      selected: isSelected,
      onSelected: (val) {
        setState(() {
          _contentFilter = val ? type : null;
        });
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
}

/// Tappable navigation row used for quick links on the profile page.
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
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
                      ?.copyWith(fontWeight: FontWeight.w500)),
            ),
            Icon(Icons.chevron_right, size: 20, color: theme.colorScheme.outline),
          ],
        ),
      ),
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

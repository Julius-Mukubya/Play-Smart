import 'package:flutter/material.dart';
import 'package:play_smart/core/theme/app_theme.dart';

/// Privacy & Safety screen.
class PrivacySafetyScreen extends StatefulWidget {
  const PrivacySafetyScreen({super.key});

  @override
  State<PrivacySafetyScreen> createState() => _PrivacySafetyScreenState();
}

class _PrivacySafetyScreenState extends State<PrivacySafetyScreen> {
  bool _publicProfile = true;
  bool _showLocation = true;
  bool _allowMessageRequests = true;
  bool _showInSearch = true;
  bool _analyticsOptIn = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Safety')),
      body: ListView(
        children: [
          _SectionHeader('Profile Visibility', theme),
          _ToggleTile(
            icon: Icons.public_outlined,
            title: 'Public Profile',
            subtitle: 'Anyone can view your profile and content',
            value: _publicProfile,
            onChanged: (v) => setState(() => _publicProfile = v),
            theme: theme,
          ),
          _ToggleTile(
            icon: Icons.location_on_outlined,
            title: 'Show Location',
            subtitle: 'Display your city on your public profile',
            value: _showLocation,
            onChanged: (v) => setState(() => _showLocation = v),
            theme: theme,
          ),
          _ToggleTile(
            icon: Icons.search_outlined,
            title: 'Appear in Search',
            subtitle: 'Allow recruiters to find you via search',
            value: _showInSearch,
            onChanged: (v) => setState(() => _showInSearch = v),
            theme: theme,
          ),

          _SectionHeader('Messaging', theme),
          _ToggleTile(
            icon: Icons.message_outlined,
            title: 'Allow Message Requests',
            subtitle:
                'Recruiters and clubs can send you connection requests',
            value: _allowMessageRequests,
            onChanged: (v) => setState(() => _allowMessageRequests = v),
            theme: theme,
          ),

          _SectionHeader('Data & Analytics', theme),
          _ToggleTile(
            icon: Icons.bar_chart_outlined,
            title: 'Analytics & Insights',
            subtitle:
                'Allow Play Smart to collect usage data to improve your experience',
            value: _analyticsOptIn,
            onChanged: (v) => setState(() => _analyticsOptIn = v),
            theme: theme,
          ),

          _SectionHeader('Account Safety', theme),
          _ActionTile(
            icon: Icons.lock_outline,
            title: 'Change Password',
            subtitle: 'Update your account password',
            iconColor: AppColors.accentPrimary,
            onTap: () => _showComingSoon(context),
            theme: theme,
          ),
          _ActionTile(
            icon: Icons.devices_outlined,
            title: 'Active Sessions',
            subtitle: 'View and manage devices signed into your account',
            iconColor: AppColors.accentPrimary,
            onTap: () => _showComingSoon(context),
            theme: theme,
          ),
          _ActionTile(
            icon: Icons.block_outlined,
            title: 'Blocked Accounts',
            subtitle: 'Manage accounts you have blocked',
            iconColor: AppColors.stateWarning,
            onTap: () => _showComingSoon(context),
            theme: theme,
          ),

          _SectionHeader('Legal', theme),
          _ActionTile(
            icon: Icons.description_outlined,
            title: 'Privacy Policy',
            subtitle: 'Read our full privacy policy',
            onTap: () => _showPolicy(
              context,
              title: 'Privacy Policy',
              content: _privacyPolicy,
            ),
            theme: theme,
          ),
          _ActionTile(
            icon: Icons.gavel_outlined,
            title: 'Terms of Service',
            subtitle: 'Read our terms and conditions',
            onTap: () => _showPolicy(
              context,
              title: 'Terms of Service',
              content: _termsOfService,
            ),
            theme: theme,
          ),

          _SectionHeader('Danger Zone', theme),
          _ActionTile(
            icon: Icons.delete_forever_outlined,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and all data',
            iconColor: AppColors.stateError,
            titleColor: AppColors.stateError,
            onTap: () => _confirmDeleteAccount(context),
            theme: theme,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showPolicy(BuildContext context,
      {required String title, required String content}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700)),
            ),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Text(content,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(height: 1.6)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding:
            const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 28),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.stateError.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_forever_outlined,
                    size: 30, color: AppColors.stateError),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Delete Account',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'This will permanently delete your account, profile, and all content. This cannot be undone.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textMuted, height: 1.5),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 28),
              const Divider(height: 1, color: AppColors.borderDefault),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Center(
                    child: Text('Delete My Account',
                        style: TextStyle(
                            color: AppColors.stateError,
                            fontSize: 16,
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const Divider(height: 1, color: AppColors.borderDefault),
              InkWell(
                onTap: () => Navigator.pop(context),
                child: const SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Center(
                    child: Text('Cancel',
                        style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 16,
                            fontWeight: FontWeight.w500)),
                  ),
                ),
              ),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared tile widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _SectionHeader(this.label, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ThemeData theme;

  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 2),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault, width: 0.5),
      ),
      child: SwitchListTile(
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.accentPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child:
              Icon(icon, color: AppColors.accentPrimary, size: 18),
        ),
        title: Text(title,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: theme.textTheme.bodySmall),
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.accentPrimary,
        activeTrackColor: AppColors.accentLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final ThemeData theme;
  final Color? iconColor;
  final Color? titleColor;

  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.theme,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AppColors.accentPrimary;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 2),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault, width: 0.5),
      ),
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        title: Text(title,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: titleColor,
            )),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: Icon(Icons.chevron_right,
            color: AppColors.textMuted, size: 20),
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Static policy content
// ─────────────────────────────────────────────────────────────────────────────

const _privacyPolicy = '''
Last updated: June 2026

1. Information We Collect
We collect information you provide directly, such as your name, email address, date of birth, and athlete profile data. We also collect usage data when you interact with the platform.

2. How We Use Your Information
Your information is used to operate and improve Play Smart, connect athletes with recruiters and clubs, and send relevant notifications. We do not sell your personal data to third parties.

3. Profile Visibility
Your public profile is visible to all users including guests unless you restrict it in your privacy settings. Private notes added by recruiters are never visible to athletes.

4. Under-18 Users
Accounts for users under 18 have additional protections. Only verified recruiters and clubs may contact them, and their conversations are flagged for monitoring.

5. Data Retention
You may request deletion of your account and associated data at any time. We will process requests within 30 days.

6. Contact
For privacy-related requests, contact privacy@playsmart.ug.
''';

const _termsOfService = '''
Last updated: June 2026

1. Acceptance
By using Play Smart, you agree to these terms. If you do not agree, do not use the platform.

2. Accounts
You are responsible for maintaining the security of your account. Athletes, recruiters, and clubs must provide accurate information during registration.

3. Content
Athletes retain ownership of content they upload. By posting, you grant Play Smart a licence to display it on the platform. You may not upload content you do not own.

4. Prohibited Conduct
You may not impersonate others, post false information, harass other users, or attempt to circumvent the trust badge system.

5. Subscriptions & Payments
Subscription fees are billed in advance. Refunds are not provided for partial billing periods. A 3-day grace period applies to failed payments before access is restricted.

6. Termination
We reserve the right to suspend or terminate accounts that violate these terms.

7. Governing Law
These terms are governed by the laws of Uganda.
''';

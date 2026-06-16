import 'package:flutter/material.dart';
import 'package:play_smart/core/theme/app_theme.dart';

/// Help & Support screen — FAQs, contact options, and app info.
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  int? _openFaq;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        children: [
          // ── Hero banner ───────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.accentDark, AppColors.accentPrimary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('How can we help?',
                          style: theme.textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(
                          'Browse FAQs or reach out to our support team.',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.support_agent_rounded,
                    color: Colors.white54, size: 48),
              ],
            ),
          ),

          // ── Contact options ───────────────────────────────────────────
          _SectionLabel('Contact Us', theme),
          _ContactTile(
            icon: Icons.email_outlined,
            iconColor: AppColors.accentPrimary,
            title: 'Email Support',
            subtitle: 'support@playsmart.ug',
            onTap: () => _showSnack(context, 'Opening email…'),
            theme: theme,
          ),
          _ContactTile(
            icon: Icons.chat_bubble_outline_rounded,
            iconColor: AppColors.stateSuccess,
            title: 'Live Chat',
            subtitle: 'Mon–Fri, 8am–6pm EAT',
            badge: 'Online',
            badgeColor: AppColors.stateSuccess,
            onTap: () => _showSnack(context, 'Starting chat…'),
            theme: theme,
          ),
          _ContactTile(
            icon: Icons.phone_outlined,
            iconColor: AppColors.stateWarning,
            title: 'Call Us',
            subtitle: '+256 700 000 000',
            onTap: () => _showSnack(context, 'Dialling…'),
            theme: theme,
          ),

          // ── FAQs ─────────────────────────────────────────────────────
          _SectionLabel('Frequently Asked Questions', theme),
          ..._faqs.asMap().entries.map((e) => _FaqTile(
                index: e.key,
                faq: e.value,
                isOpen: _openFaq == e.key,
                onToggle: () =>
                    setState(() => _openFaq = _openFaq == e.key ? null : e.key),
                theme: theme,
              )),

          // ── App info ──────────────────────────────────────────────────
          _SectionLabel('About', theme),
          _InfoRow('Version', '1.0.0 (Build 1)', theme),
          _InfoRow('Platform', 'Android / iOS', theme),
          _InfoRow('Support email', 'support@playsmart.ug', theme),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final ThemeData theme;
  const _SectionLabel(this.label, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
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

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String? badge;
  final Color? badgeColor;
  final VoidCallback onTap;
  final ThemeData theme;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.badge,
    this.badgeColor,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDefault, width: 0.5),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(title,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: badge != null
            ? Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (badgeColor ?? AppColors.accentPrimary)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  badge!,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? AppColors.accentPrimary),
                ),
              )
            : const Icon(Icons.chevron_right,
                color: AppColors.textMuted, size: 20),
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final int index;
  final ({String q, String a}) faq;
  final bool isOpen;
  final VoidCallback onToggle;
  final ThemeData theme;

  const _FaqTile({
    required this.index,
    required this.faq,
    required this.isOpen,
    required this.onToggle,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.accentPrimary.withValues(alpha: 0.04)
            : AppColors.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOpen
              ? AppColors.accentPrimary.withValues(alpha: 0.3)
              : AppColors.borderDefault,
          width: isOpen ? 1.0 : 0.5,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      faq.q,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isOpen
                            ? AppColors.accentPrimary
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: isOpen
                          ? AppColors.accentPrimary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                faq.a,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ),
            crossFadeState: isOpen
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;
  const _InfoRow(this.label, this.value, this.theme);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderDefault, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: AppColors.textMuted))),
          Text(value,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FAQ content
// ─────────────────────────────────────────────────────────────────────────────

const _faqs = [
  (
    q: 'How does the trust badge system work?',
    a: 'Achievements start as Self-Reported. A verified coach can upgrade them to Coach-Endorsed, and a verified club can grant Club-Verified status by confirming you\'re on their roster. Badges cannot be self-assigned.',
  ),
  (
    q: 'Can recruiters contact me without my permission?',
    a: 'No. Recruiters and clubs must send a message request first. You choose to accept or decline it. Only after you accept can a conversation open.',
  ),
  (
    q: 'How do I get verified as a recruiter or club?',
    a: 'Go to Account Verification during sign-up or via the settings menu. Submit your credentials or official documents. Our team reviews and approves within 2–5 business days.',
  ),
  (
    q: 'What is Post Boost?',
    a: 'Post Boost promotes a single piece of your content to the top of recruiter feeds for 7 days, increasing your visibility significantly.',
  ),
  (
    q: 'Is my profile visible to everyone?',
    a: 'By default yes — public profiles are discoverable by guests and all users. You can restrict visibility in Privacy & Safety settings.',
  ),
  (
    q: 'What payment methods are supported?',
    a: 'We accept MTN Mobile Money, Airtel Money, Visa/Mastercard via Pesapal or Flutterwave, and Stripe for international cards.',
  ),
  (
    q: 'How do I delete my account?',
    a: 'Go to Settings → Privacy & Safety → Delete Account. This permanently removes your profile and all content. The action cannot be undone.',
  ),
];

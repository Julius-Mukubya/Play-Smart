import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/core/router/app_router.dart';

/// Landing / Home screen — public-facing entry point.
/// Shown to unauthenticated users. Explains Play Smart and drives sign-up.
class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Hero section
              Image.asset(
                'lib/assets/images/logo_mark.png',
                height: 96,
              ),
              const SizedBox(height: 16),
              Text(
                'Play Smart',
                style: theme.textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Discover. Connect. Play.',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text(
                'The talent discovery platform for athletes across Uganda and the wider region. '
                'Create your profile, upload highlights, and get noticed by recruiters and clubs.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Sign Up buttons
              ElevatedButton(
                onPressed: () => context.push(AppRouter.signUp),
                child: const Text('Sign Up as Athlete'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => context.push(AppRouter.signUp),
                child: const Text('Sign Up as Recruiter or Club'),
              ),
              const SizedBox(height: 24),
              // Sign In prompt
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: theme.textTheme.bodyMedium,
                  ),
                  TextButton(
                    onPressed: () => context.push(AppRouter.signIn),
                    child: const Text('Sign In'),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              // Trust badge explanation section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trust Badges',
                      style: theme.textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _buildBadgeRow(
                      context,
                      icon: Icons.person,
                      label: 'Self-Reported',
                      description: 'Achievements you add yourself',
                    ),
                    const SizedBox(height: 8),
                    _buildBadgeRow(
                      context,
                      icon: Icons.school,
                      label: 'Coach-Endorsed',
                      description: 'Verified by your coach',
                    ),
                    const SizedBox(height: 8),
                    _buildBadgeRow(
                      context,
                      icon: Icons.verified,
                      label: 'Club-Verified',
                      description: 'Confirmed by a club',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadgeRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String description,
  }) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.titleMedium),
              Text(description, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
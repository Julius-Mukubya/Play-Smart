import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Recruiter/Club verification submission screen.
/// Allows recruiters and clubs to submit credentials for verification.
class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String? _selectedDocumentType;
  bool _isSubmitting = false;

  final List<String> _recruiterDocTypes = [
    'Scouting License / Certification',
    'Club Employment Letter',
    'FIFA Agent License',
    'National Association ID',
    'Other',
  ];

  final List<String> _clubDocTypes = [
    'Certificate of Registration',
    'League Membership Document',
    'Official Club Letterhead',
    'Tax Registration Certificate',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate submission
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Verification Submitted'),
        content: const Text(
          'Your verification documents have been submitted. '
          'You will be notified once your account is verified. '
          'This usually takes 1-3 business days.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go(AppRouter.discover);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final isRecruiter = authState is AuthAuthenticated && authState.user.role == AccountRole.recruiter;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account Verification'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Info section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: theme.colorScheme.onPrimaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Submit your credentials to verify your account. '
                          'Once approved, you\'ll unlock all features including '
                          'shortlisting, messaging, and posting opportunities.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Status indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_empty, color: Colors.orange),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: Pending Review',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.orange,
                              )),
                          Text('Submit your documents below',
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Features that will unlock
                Text('Features that will unlock', style: theme.textTheme.titleLarge),
                const SizedBox(height: 12),
                _buildFeatureItem(Icons.search, 'Full athlete search and filtering'),
                _buildFeatureItem(Icons.bookmark, 'Create and manage shortlists'),
                _buildFeatureItem(Icons.message, 'Contact athletes directly'),
                _buildFeatureItem(Icons.event, 'Post trial opportunities'),
                _buildFeatureItem(Icons.analytics, 'Access recruitment analytics'),

                const SizedBox(height: 32),

                // Document type
                Text('Document Type', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedDocumentType,
                  dropdownColor: Colors.white,
                  decoration: const InputDecoration(
                    hintText: 'Select document type',
                    prefixIcon: Icon(Icons.description),
                  ),
                  items: (isRecruiter ? _recruiterDocTypes : _clubDocTypes)
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedDocumentType = v),
                  validator: (v) => v == null ? 'Please select a document type' : null,
                ),

                const SizedBox(height: 16),

                // Upload area
                InkWell(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File upload coming soon.')),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                        style: BorderStyle.solid,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: theme.colorScheme.surface,
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.cloud_upload_outlined,
                            size: 48, color: theme.colorScheme.primary),
                        const SizedBox(height: 8),
                        Text('Tap to upload document',
                            style: theme.textTheme.titleMedium),
                        Text('PDF, JPG, or PNG (max 10MB)',
                            style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Additional notes (optional)',
                    hintText: 'Any additional information for the review team...',
                    prefixIcon: Icon(Icons.notes),
                  ),
                  maxLines: 3,
                ),

                const SizedBox(height: 32),

                // Submit button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Submit for Verification'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
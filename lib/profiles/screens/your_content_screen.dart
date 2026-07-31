import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/core/theme/app_theme.dart';
import 'package:play_smart/profiles/providers/content_provider.dart';
import 'package:play_smart/profiles/providers/profile_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/app_dialog.dart';
import 'package:play_smart/shared/widgets/content_thumbnail.dart';

class YourContentScreen extends ConsumerStatefulWidget {
  const YourContentScreen({super.key});

  @override
  ConsumerState<YourContentScreen> createState() => _YourContentScreenState();
}

class _YourContentScreenState extends ConsumerState<YourContentScreen> {
  ContentType? _contentFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Content'),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found.'));
          }

          final filtered = profile.content.where((c) {
            if (_contentFilter == null) return true;
            return c.type == _contentFilter;
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Filters row
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: SizedBox(
                  height: 40,
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
              ),
              
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.video_library_outlined, size: 64, color: theme.colorScheme.outline),
                              const SizedBox(height: 16),
                              Text('No content found', style: theme.textTheme.titleLarge),
                              const SizedBox(height: 8),
                              const Text(
                                'Upload photos or videos to start sharing your journey.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) {
                          final content = filtered[idx];
                          return ContentThumbnail(
                            content: content,
                            onDelete: () => _confirmDeleteContent(context, content, profile.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, ContentType? type) {
    final isSelected = _contentFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        if (val) {
          setState(() {
            _contentFilter = type;
          });
        }
      },
    );
  }

  void _confirmDeleteContent(BuildContext context, AthleteContent content, String athleteId) {
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
          await ref.read(profileProvider.notifier).loadAthleteProfile(athleteId);
          // Reload local my profile data to reflect deletion
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
}

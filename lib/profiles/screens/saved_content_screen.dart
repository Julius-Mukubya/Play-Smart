import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/discovery/providers/discovery_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/content_category_bar.dart';
import 'package:play_smart/shared/widgets/content_thumbnail.dart';

class SavedContentScreen extends ConsumerStatefulWidget {
  const SavedContentScreen({super.key});

  @override
  ConsumerState<SavedContentScreen> createState() => _SavedContentScreenState();
}

class _SavedContentScreenState extends ConsumerState<SavedContentScreen> {
  ContentType? _selectedType;
  MomentType? _selectedMoment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(discoveryProvider);
    final savedItems = state.feedItems.where((item) {
      if (item.isAd || item.content == null) return false;
      if (!state.bookmarkedContentIds.contains(item.content!.id)) return false;
      if (_selectedType != null && item.content!.type != _selectedType) return false;
      if (_selectedMoment != null && item.content!.momentTag != _selectedMoment) return false;
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Content'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: ContentCategoryBar(
              selectedType: _selectedType,
              selectedMoment: _selectedMoment,
              onFilterChanged: (type, moment) {
                setState(() {
                  _selectedType = type;
                  _selectedMoment = moment;
                });
              },
            ),
          ),
          Expanded(
            child: savedItems.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bookmark_border_rounded, size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 16),
                          Text('No saved content yet', style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          const Text(
                            'Bookmark videos and posts from the discover feed to view them here.',
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
                    itemCount: savedItems.length,
                    itemBuilder: (ctx, idx) {
                      final item = savedItems[idx];
                      return GestureDetector(
                        onTap: () => context.push('/athlete/${item.athlete!.id}'),
                        child: ContentThumbnail(
                          content: item.content!,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

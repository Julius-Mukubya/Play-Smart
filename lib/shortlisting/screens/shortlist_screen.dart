import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/profiles/repositories/profile_repository.dart';
import 'package:play_smart/shortlisting/providers/shortlist_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/athlete_card.dart';

/// Shortlist screen — manage shortlisted athletes.
class ShortlistScreen extends ConsumerStatefulWidget {
  const ShortlistScreen({super.key});

  @override
  ConsumerState<ShortlistScreen> createState() => _ShortlistScreenState();
}

class _ShortlistScreenState extends ConsumerState<ShortlistScreen> {
  final ProfileRepository _profileRepo = ProfileRepository();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(shortlistProvider.notifier).loadShortlists());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(shortlistProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(state.selectedShortlist != null
            ? state.selectedShortlist!.name
            : 'Shortlists'),
        actions: [
          if (state.selectedShortlist != null)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => ref.read(shortlistProvider.notifier).deselectShortlist(),
            ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateDialog(context, theme),
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text('Error: ${state.error}'))
              : state.selectedShortlist != null
                  ? _buildShortlistDetail(context, theme, state.selectedShortlist!)
                  : _buildShortlistList(context, theme, state.shortlists),
    );
  }

  Widget _buildShortlistList(BuildContext context, ThemeData theme, List<Shortlist> shortlists) {
    if (shortlists.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bookmark_border, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('No shortlists yet', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Create a shortlist to save and organize athletes you\'re interested in.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showCreateDialog(context, theme),
                icon: const Icon(Icons.add),
                label: const Text('Create Shortlist'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shortlists.length,
      itemBuilder: (ctx, i) {
        final list = shortlists[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () => ref.read(shortlistProvider.notifier).selectShortlist(list),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.bookmark, color: theme.colorScheme.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(list.name, style: theme.textTheme.titleMedium),
                        Text(
                          '${list.athleteIds.length} athletes',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      if (action == 'rename') {
                        _showRenameDialog(context, theme, list);
                      } else if (action == 'delete') {
                        _showDeleteConfirm(context, list);
                      }
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'rename', child: Text('Rename')),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShortlistDetail(BuildContext context, ThemeData theme, Shortlist shortlist) {
    if (shortlist.athleteIds.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_outline, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 16),
              Text('This shortlist is empty', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'Search for athletes and add them to this shortlist.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go(AppRouter.search),
                icon: const Icon(Icons.search),
                label: const Text('Find Athletes'),
              ),
            ],
          ),
        ),
      );
    }

    // Resolve athlete profiles for display
    final athletes = shortlist.athleteIds
        .map((id) => _profileRepo.getAthleteById(id))
        .where((a) => a != null)
        .cast<Athlete>()
        .toList();

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: athletes.length,
      itemBuilder: (ctx, i) {
        final athlete = athletes[i];
        final note = shortlist.privateNotes[athlete.id];

        return Column(
          children: [
            AthleteCard(
              athlete: athlete,
              showShortlistAction: true,
              isShortlisted: true,
              onShortlist: () {
                ref.read(shortlistProvider.notifier)
                    .removeAthlete(shortlist.id, athlete.id);
              },
            ),
            // Private note section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: InkWell(
                onTap: () => _showNoteDialog(context, theme, shortlist, athlete),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes, size: 16, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          note ?? 'Add private note...',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: note != null ? null : theme.colorScheme.outline,
                            fontStyle: note != null ? FontStyle.normal : FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCreateDialog(BuildContext context, ThemeData theme) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Shortlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'e.g. Strikers Watchlist',
            labelText: 'Name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(shortlistProvider.notifier).createShortlist(controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, ThemeData theme, Shortlist list) {
    final controller = TextEditingController(text: list.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename Shortlist'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(shortlistProvider.notifier).renameShortlist(list.id, controller.text.trim());
                Navigator.pop(ctx);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirm(BuildContext context, Shortlist list) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Shortlist'),
        content: Text('Delete "${list.name}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(shortlistProvider.notifier).deleteShortlist(list.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(BuildContext context, ThemeData theme, Shortlist shortlist, Athlete athlete) {
    final controller = TextEditingController(text: shortlist.privateNotes[athlete.id] ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Note about ${athlete.displayName}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter private notes...',
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              ref.read(shortlistProvider.notifier)
                  .setPrivateNote(shortlist.id, athlete.id, controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
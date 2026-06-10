import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/discovery/providers/discovery_provider.dart';
import 'package:play_smart/shared/widgets/athlete_card.dart';

/// Discover feed — main feed for all authenticated users.
/// Shows athlete content and highlights.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(discoveryProvider.notifier).loadDiscoverFeed());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                        const SizedBox(height: 16),
                        Text('Something went wrong', style: theme.textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(state.error!, style: theme.textTheme.bodySmall),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => ref.read(discoveryProvider.notifier).loadDiscoverFeed(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : state.athletes.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: theme.colorScheme.outline),
                            const SizedBox(height: 16),
                            Text('No athletes found', style: theme.textTheme.titleLarge),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your filters or check back later.',
                              style: theme.textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            if (state.filters.activeFilterCount > 0) ...[
                              const SizedBox(height: 16),
                              OutlinedButton(
                                onPressed: () => ref.read(discoveryProvider.notifier).clearFilters(),
                                child: const Text('Clear Filters'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                      : RefreshIndicator(
                        onRefresh: () => ref.read(discoveryProvider.notifier).loadDiscoverFeed(),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: state.athletes.length,
                          itemBuilder: (ctx, i) => AthleteCard(
                            athlete: state.athletes[i],
                          ),
                        ),
                      ),
    );
  }
}
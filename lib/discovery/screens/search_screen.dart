import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/core/theme/app_theme.dart' as theme_colors;
import 'package:play_smart/discovery/providers/discovery_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/athlete_grid_card.dart';
import 'package:play_smart/shared/widgets/content_thumbnail.dart';
import 'package:go_router/go_router.dart';

/// Advanced search screen — recruiters and clubs only.
/// Features filter panel, results list, and recommended feed.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(discoveryProvider.notifier).loadDiscoverFeed());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(discoveryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Athletes'),
        actions: [
          if (state.filters.activeFilterCount > 0)
            TextButton(
              onPressed: () => ref.read(discoveryProvider.notifier).clearFilters(),
              child: const Text('Clear'),
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: () => _showFilterSheet(context, theme),
              ),
              if (state.filters.activeFilterCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.stateError,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${state.filters.activeFilterCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by name, sport, position...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(discoveryProvider.notifier).setQuery('');
                        },
                      )
                    : null,
              ),
              onSubmitted: (value) {
                ref.read(discoveryProvider.notifier).setQuery(value);
                ref.read(discoveryProvider.notifier).search();
              },
            ),
          ),
          _CategoryBar(
            onFilterChanged: (sport) {
              final currentFilters = ref.read(discoveryProvider).filters;
              if (sport == 'All') {
                ref.read(discoveryProvider.notifier).updateFilters(
                  currentFilters.copyWith(clearSport: true),
                );
              } else {
                ref.read(discoveryProvider.notifier).updateFilters(
                  currentFilters.copyWith(sport: sport),
                );
              }
            },
          ),
          const SizedBox(height: 8),

          // Results
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
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
                                state.filters.activeFilterCount > 0
                                    ? 'Try adjusting your filters.'
                                    : 'Try searching by name, sport, or position.',
                                style: theme.textTheme.bodyMedium,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await ref.read(discoveryProvider.notifier).search();
                        },
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.68,
                          ),
                          itemCount: state.athletes.length,
                          itemBuilder: (ctx, i) => AthleteGridCard(
                            athlete: state.athletes[i],
                            showShortlistAction: true,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context, ThemeData theme) {
    final state = ref.read(discoveryProvider);
    final filters = state.filters;

    String? selectedSport = filters.sport;
    String? selectedPosition = filters.position;
    int? minAge = filters.minAge;
    int? maxAge = filters.maxAge;
    String? location = filters.location;
    AvailabilityStatus? availability = filters.availability;
    TrustBadgeLevel? minBadge = filters.minBadge;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Filters', style: theme.textTheme.titleLarge),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Sport
                Text('Sport', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'e.g. Football',
                    prefixIcon: Icon(Icons.sports_soccer),
                  ),
                  controller: TextEditingController(text: selectedSport ?? ''),
                  onChanged: (v) => selectedSport = v.isEmpty ? null : v,
                ),
                const SizedBox(height: 16),

                // Position
                Text('Position', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'e.g. Striker',
                    prefixIcon: Icon(Icons.person),
                  ),
                  controller: TextEditingController(text: selectedPosition ?? ''),
                  onChanged: (v) => selectedPosition = v.isEmpty ? null : v,
                ),
                const SizedBox(height: 16),

                // Age range
                Text('Age Range', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Min',
                          hintText: '18',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: minAge?.toString() ?? ''),
                        onChanged: (v) => minAge = int.tryParse(v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: 'Max',
                          hintText: '35',
                        ),
                        keyboardType: TextInputType.number,
                        controller: TextEditingController(text: maxAge?.toString() ?? ''),
                        onChanged: (v) => maxAge = int.tryParse(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Location
                Text('Location', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'e.g. Kampala',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  controller: TextEditingController(text: location ?? ''),
                  onChanged: (v) => location = v.isEmpty ? null : v,
                ),
                const SizedBox(height: 16),

                // Availability
                Text('Availability', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<AvailabilityStatus>(
                  initialValue: availability,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.access_time)),
                  hint: const Text('Any'),
                  items: AvailabilityStatus.values.map((status) {
                    String label;
                    switch (status) {
                      case AvailabilityStatus.openToTrials:
                        label = 'Open to Trials';
                      case AvailabilityStatus.currentlyContracted:
                        label = 'Currently Contracted';
                      case AvailabilityStatus.notAvailable:
                        label = 'Not Available';
                    }
                    return DropdownMenuItem(value: status, child: Text(label));
                  }).toList(),
                  onChanged: (v) => setSheetState(() => availability = v),
                ),
                const SizedBox(height: 16),

                // Badge level
                Text('Minimum Trust Badge', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                DropdownButtonFormField<TrustBadgeLevel>(
                  initialValue: minBadge,
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.verified)),
                  hint: const Text('Any'),
                  items: TrustBadgeLevel.values.map((level) {
                    String label;
                    switch (level) {
                      case TrustBadgeLevel.selfReported:
                        label = 'Self-Reported';
                      case TrustBadgeLevel.coachEndorsed:
                        label = 'Coach-Endorsed';
                      case TrustBadgeLevel.clubVerified:
                        label = 'Club-Verified';
                    }
                    return DropdownMenuItem(value: level, child: Text(label));
                  }).toList(),
                  onChanged: (v) => setSheetState(() => minBadge = v),
                ),
                const SizedBox(height: 24),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(discoveryProvider.notifier).updateFilters(
                        SearchFilters(
                          query: filters.query,
                          sport: selectedSport,
                          position: selectedPosition,
                          minAge: minAge,
                          maxAge: maxAge,
                          location: location,
                          availability: availability,
                          minBadge: minBadge,
                        ),
                      );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Apply Filters'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Private reference to AppColors for the filter badge.
class AppColors {
  static const Color stateError = Color(0xFFE74C3C);
}

class _CategoryBar extends StatefulWidget {
  final void Function(String sport) onFilterChanged;
  const _CategoryBar({required this.onFilterChanged});

  @override
  State<_CategoryBar> createState() => _CategoryBarState();
}

class _CategoryBarState extends State<_CategoryBar> {
  static const _categories = [
    (label: 'All',        icon: Icons.auto_awesome),
    (label: 'Football',   icon: Icons.sports_soccer),
    (label: 'Netball',    icon: Icons.sports_basketball),
    (label: 'Athletics',  icon: Icons.directions_run),
    (label: 'Basketball', icon: Icons.sports_basketball),
    (label: 'Rugby',      icon: Icons.sports_rugby),
    (label: 'Swimming',   icon: Icons.pool),
  ];

  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final active = _selected == i;
          return GestureDetector(
            onTap: () {
              setState(() => _selected = i);
              widget.onFilterChanged(cat.label);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: active
                    ? theme_colors.AppColors.accentPrimary
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: active
                      ? theme_colors.AppColors.accentPrimary
                      : Colors.grey.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon,
                      size: 16,
                      color: active
                          ? Colors.white
                          : Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : Colors.black87,
                      fontSize: 14,
                      fontWeight: active
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
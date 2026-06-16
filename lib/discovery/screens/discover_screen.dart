import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/core/theme/app_theme.dart';
import 'package:play_smart/discovery/models/feed_item.dart';
import 'package:play_smart/discovery/providers/discovery_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/trust_badge.dart';

/// Discover screen — horizontal PageView, one full-screen card per swipe.
/// Swipe LEFT for next content, swipe RIGHT for previous.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(discoveryProvider.notifier).loadDiscoverFeed());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(discoveryProvider);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        body: _buildBody(state),
      ),
    );
  }

  Widget _buildBody(DiscoveryState state) {
    if (state.isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (state.error != null) {
      return _ErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(discoveryProvider.notifier).loadDiscoverFeed(),
      );
    }
    if (state.feedItems.isEmpty) {
      return const _EmptyView();
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // ── Horizontal swipeable feed ───────────────────────────────────
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.horizontal,
          itemCount: state.feedItems.length,
          onPageChanged: (i) => setState(() => _currentPage = i),
          itemBuilder: (ctx, i) => _FullScreenCard(
            item: state.feedItems[i],
            isActive: i == _currentPage,
          ),
        ),

        // ── Top bar (wordmark + icons) ──────────────────────────────────
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _TopBar(),
        ),

        // ── Category tabs pinned below top bar ──────────────────────────
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 0,
          right: 0,
          child: _CategoryBar(
            onFilterChanged: (sport) {
              if (sport == 'All') {
                ref.read(discoveryProvider.notifier).loadDiscoverFeed();
              } else {
                ref
                    .read(discoveryProvider.notifier)
                    .updateFilters(SearchFilters(sport: sport));
              }
            },
          ),
        ),

        // ── Bottom progress dots ────────────────────────────────────────
        Positioned(
          bottom: MediaQuery.of(context).padding.bottom + 12,
          left: 0,
          right: 0,
          child: _ProgressDots(
            count: state.feedItems.length.clamp(0, 10),
            current: _currentPage.clamp(
                0, state.feedItems.length - 1),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen card
// ─────────────────────────────────────────────────────────────────────────────

class _FullScreenCard extends ConsumerStatefulWidget {
  final FeedItem item;
  final bool isActive;
  const _FullScreenCard({required this.item, required this.isActive});

  @override
  ConsumerState<_FullScreenCard> createState() => _FullScreenCardState();
}

class _FullScreenCardState extends ConsumerState<_FullScreenCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartCtrl;
  late Animation<double> _heartScale;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _heartCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _heartScale = Tween<double>(begin: 0.5, end: 1.4).animate(
        CurvedAnimation(parent: _heartCtrl, curve: Curves.elasticOut));
  }

  @override
  void dispose() {
    _heartCtrl.dispose();
    super.dispose();
  }

  void _doubleTapLike() {
    final id = widget.item.content.id;
    final liked =
        ref.read(discoveryProvider).likedContentIds.contains(id);
    if (!liked) ref.read(discoveryProvider.notifier).toggleLike(id);
    setState(() => _showHeart = true);
    _heartCtrl.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showHeart = false);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isLiked = ref
        .watch(discoveryProvider)
        .likedContentIds
        .contains(item.content.id);

    return GestureDetector(
      onDoubleTap: _doubleTapLike,
      onTap: () => context.push('/athlete/${item.athlete.id}'),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media background
          _MediaBackground(item: item),

          // Bottom gradient vignette
          Positioned(
            left: 0, right: 0, bottom: 0, height: 320,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.9),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Moment tag — mid-left
          if (item.content.momentTag != null)
            Positioned(
              left: 16,
              bottom: 160,
              child: _MomentChip(tag: item.content.momentTag!),
            ),

          // Right action rail
          Positioned(
            right: 14,
            bottom: 80,
            child: _ActionRail(item: item, isLiked: isLiked),
          ),

          // Bottom athlete strip
          Positioned(
            left: 0,
            right: 72,
            bottom: 40,
            child: _AthleteStrip(item: item),
          ),

          // Double-tap heart burst
          if (_showHeart)
            Center(
              child: IgnorePointer(
                child: ScaleTransition(
                  scale: _heartScale,
                  child: const Icon(Icons.favorite,
                      color: Colors.white, size: 100,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 20)
                      ]),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Media background
// ─────────────────────────────────────────────────────────────────────────────

class _MediaBackground extends StatelessWidget {
  final FeedItem item;
  const _MediaBackground({required this.item});

  @override
  Widget build(BuildContext context) {
    final content = item.content;
    final athlete = item.athlete;

    if (content.type == ContentType.video) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0D1117),
              Color.fromARGB(255,
                20 + (athlete.id.hashCode.abs() % 40),
                40 + (athlete.id.hashCode.abs() % 60),
                100 + (athlete.id.hashCode.abs() % 80),
              ),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.play_circle_fill,
              size: 90, color: Colors.white54),
        ),
      );
    }

    if (content.type == ContentType.photo) {
      final hue = (athlete.id.hashCode.abs() % 36) * 10.0;
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              HSLColor.fromAHSL(1, hue, 0.5, 0.25).toColor(),
              HSLColor.fromAHSL(1, hue + 20, 0.4, 0.15).toColor(),
            ],
          ),
        ),
        child: const Center(
          child: Icon(Icons.image_outlined, size: 72, color: Colors.white30),
        ),
      );
    }

    // Text post
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A2332), Color(0xFF2B6CB0)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(28, 180, 88, 180),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(content.title,
              style: const TextStyle(
                color: Colors.white, fontSize: 28,
                fontWeight: FontWeight.w800, height: 1.25)),
          if (content.description.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(content.description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 17, height: 1.5),
                maxLines: 5, overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Athlete strip
// ─────────────────────────────────────────────────────────────────────────────

class _AthleteStrip extends StatelessWidget {
  final FeedItem item;
  const _AthleteStrip({required this.item});

  @override
  Widget build(BuildContext context) {
    final athlete = item.athlete;
    final content = item.content;

    return GestureDetector(
      onTap: () => context.push('/athlete/${athlete.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.accentPrimary,
                  child: Text(
                    athlete.displayName.isNotEmpty
                        ? athlete.displayName[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 19),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                          child: Text(athlete.displayName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15),
                              overflow: TextOverflow.ellipsis),
                        ),
                        const SizedBox(width: 6),
                        TrustBadge(
                            level: athlete.profileBadgeLevel,
                            size: BadgeSize.sm),
                      ]),
                      const SizedBox(height: 2),
                      Text(
                        [
                          athlete.sports.isNotEmpty
                              ? athlete.sports.first
                              : null,
                          athlete.positions.isNotEmpty
                              ? athlete.positions.first
                              : null,
                          athlete.city,
                        ].whereType<String>().join(' · '),
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _AvailabilityPill(status: athlete.availabilityStatus),
              ],
            ),
            if (content.type != ContentType.post) ...[
              const SizedBox(height: 8),
              Text(content.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Action rail
// ─────────────────────────────────────────────────────────────────────────────

class _ActionRail extends ConsumerWidget {
  final FeedItem item;
  final bool isLiked;
  const _ActionRail({required this.item, required this.isLiked});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likeCount = item.likeCount + (isLiked ? 1 : 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RailBtn(
          icon: isLiked ? Icons.favorite : Icons.favorite_border,
          label: _fmt(likeCount),
          color: isLiked ? Colors.redAccent : Colors.white,
          onTap: () => ref
              .read(discoveryProvider.notifier)
              .toggleLike(item.content.id),
        ),
        const SizedBox(height: 22),
        _RailBtn(
          icon: Icons.chat_bubble_outline_rounded,
          label: _fmt(item.commentCount),
          color: Colors.white,
          onTap: () => context.push('/athlete/${item.athlete.id}'),
        ),
        const SizedBox(height: 22),
        _RailBtn(
          icon: Icons.bookmark_border_rounded,
          label: 'Save',
          color: Colors.white,
          onTap: () => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${item.athlete.displayName} saved to shortlist'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
            ),
          ),
        ),
        const SizedBox(height: 22),
        _RailBtn(
          icon: Icons.person_add_outlined,
          label: 'Profile',
          color: Colors.white,
          onTap: () => context.push('/athlete/${item.athlete.id}'),
        ),
      ],
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

class _RailBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _RailBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
                color: Colors.black38, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        left: 16,
        right: 8,
        bottom: 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: 0.55),
            Colors.transparent,
          ],
        ),
      ),
      child: Row(
        children: [
          const Text('Play',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          Text('Smart',
              style: TextStyle(
                  color: AppColors.accentLight,
                  fontSize: 22,
                  fontWeight: FontWeight.w800)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded,
                color: Colors.white, size: 26),
            onPressed: () => context.push(AppRouter.notifications),
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded,
                color: Colors.white, size: 26),
            onPressed: () => context.go(AppRouter.search),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category bar — bigger, pill-style tabs with icons
// ─────────────────────────────────────────────────────────────────────────────

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
                    ? AppColors.accentPrimary
                    : Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: active
                      ? AppColors.accentPrimary
                      : Colors.white.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: AppColors.accentPrimary
                              .withValues(alpha: 0.45),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(cat.icon,
                      size: 16,
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.75)),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: TextStyle(
                      color: active
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.85),
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

// ─────────────────────────────────────────────────────────────────────────────
// Progress dots (horizontal, bottom)
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressDots extends StatelessWidget {
  final int count;
  final int current;
  const _ProgressDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small chips
// ─────────────────────────────────────────────────────────────────────────────

class _MomentChip extends StatelessWidget {
  final MomentType tag;
  const _MomentChip({required this.tag});

  @override
  Widget build(BuildContext context) {
    final label = switch (tag) {
      MomentType.goal   => '⚽  Goal',
      MomentType.assist => '🎯  Assist',
      MomentType.sprint => '💨  Sprint',
      MomentType.tackle => '🛡️  Tackle',
      MomentType.save   => '🧤  Save',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  final AvailabilityStatus status;
  const _AvailabilityPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      AvailabilityStatus.openToTrials =>
        ('Open to Trials', AppColors.stateSuccess),
      AvailabilityStatus.currentlyContracted =>
        ('Contracted', AppColors.stateWarning),
      AvailabilityStatus.notAvailable =>
        ('Not Available', AppColors.textMuted),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / error states
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer_outlined,
              size: 64, color: Colors.white38),
          SizedBox(height: 16),
          Text('No content yet',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text('Try a different filter.',
              style: TextStyle(color: Colors.white38, fontSize: 13)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline,
                size: 64, color: Colors.white54),
            const SizedBox(height: 16),
            const Text('Something went wrong',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(message,
                style:
                    const TextStyle(color: Colors.white54, fontSize: 12),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
                onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

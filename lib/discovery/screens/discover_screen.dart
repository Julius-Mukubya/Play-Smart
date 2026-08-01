import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/shortlisting/providers/shortlist_provider.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/core/router/app_router.dart';
import 'package:play_smart/core/shell/main_shell.dart';
import 'package:play_smart/core/theme/app_theme.dart';
import 'package:play_smart/discovery/models/feed_item.dart';
import 'package:play_smart/discovery/providers/discovery_provider.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/widgets/trust_badge.dart';
import 'package:play_smart/shared/widgets/content_thumbnail.dart';
import 'package:video_player/video_player.dart';

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
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    Future.microtask(
        () => ref.read(discoveryProvider.notifier).loadDiscoverFeed());
  }

  @override
  void dispose() {
    _pageController.dispose();
    _searchController.dispose();
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
        // ── Vertical swipeable feed ───────────────────────────────────
        PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
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
          child: _TopBar(
            isSearching: _isSearching,
            searchController: _searchController,
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            onToggleSearch: () => setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchQuery = '';
                _searchController.clear();
              }
            }),
            onOpenSaved: () => _showSavedContentSheet(context, ref),
          ),
        ),

        // Search dropdown overlay
        if (_isSearching && _searchQuery.isNotEmpty)
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 16,
            right: 16,
            child: Card(
              color: const Color(0xFF1E293B),
              elevation: 8,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: Consumer(
                  builder: (context, ref, _) {
                    final query = _searchQuery.toLowerCase();
                    final results = state.feedItems.where((item) {
                      if (item.isAd) return false;
                      final title = item.content?.title.toLowerCase() ?? '';
                      final description = item.content?.description.toLowerCase() ?? '';
                      return title.contains(query) || description.contains(query);
                    }).toList();

                    if (results.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No matching videos found.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: results.length,
                      itemBuilder: (ctx, idx) {
                        final item = results[idx];
                        return ListTile(
                          leading: Icon(
                            item.content?.type == ContentType.video
                                ? Icons.videocam
                                : item.content?.type == ContentType.photo
                                    ? Icons.photo
                                    : Icons.article,
                            color: Colors.blueAccent,
                          ),
                          title: Text(
                            item.content?.title ?? '',
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            item.athlete?.displayName ?? '',
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          onTap: () {
                            final feedIndex = state.feedItems.indexOf(item);
                            if (feedIndex != -1) {
                              _pageController.jumpToPage(feedIndex);
                            }
                            setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                              _searchController.clear();
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
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
    final id = widget.item.content!.id;
    final liked =
        ref.read(discoveryProvider).likedContentIds.contains(id);
    final authState = ref.read(authProvider);
    final userId = authState is AuthAuthenticated ? authState.user.id : 'guest';
    if (!liked) ref.read(discoveryProvider.notifier).toggleLike(id, userId);
    setState(() => _showHeart = true);
    _heartCtrl.forward(from: 0).then((_) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _showHeart = false);
      });
    });
  }

  Widget _buildAdCard(BuildContext context, FeedItem item) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (item.adImageUrl != null)
          CachedNetworkImage(
            imageUrl: item.adImageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withOpacity(0.9),
                Colors.black.withOpacity(0.2),
              ],
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.campaign, color: Colors.white, size: 14),
                SizedBox(width: 4),
                Text(
                  'SPONSORED AD',
                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 60,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                item.adTitle ?? 'Sponsored',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.adDescription ?? '',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening sponsor link for ${item.adTitle}...'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A90D9),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Learn More'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    if (item.isAd) {
      return _buildAdCard(context, item);
    }
    final isLiked = ref
        .watch(discoveryProvider)
        .likedContentIds
        .contains(item.content!.id);
    // StatefulShellRoute keeps Discover mounted (via IndexedStack) even when
    // another bottom-nav tab is showing, so widget.isActive alone (which
    // page of the PageView is current) isn't enough to know a video should
    // actually be playing — it also needs the Discover tab itself visible.
    final tabVisible = ref.watch(activeShellTabIndexProvider) == 0;
    final isCurrentRoute = ModalRoute.of(context)?.isCurrent ?? true;
    final visible = widget.isActive && tabVisible && isCurrentRoute;

    return GestureDetector(
      // Tapping the video itself no longer navigates — only double-tap
      // (like) is handled here. Navigating to the profile is now only
      // triggered from the profile-specific tap targets: the athlete strip
      // (_AthleteStrip) and the rail's Profile/comment buttons.
      onDoubleTap: _doubleTapLike,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Media background
          _MediaBackground(item: item, isActive: visible),

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
          if (item.content?.momentTag != null)
            Positioned(
              left: 16,
              bottom: 160,
              child: _MomentChip(tag: item.content!.momentTag!),
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
            child: _AthleteStrip(item: item, isLiked: isLiked),
          ),

          // Double-tap heart burst
          if (_showHeart)
            Center(
              child: IgnorePointer(
                child: ScaleTransition(
                  scale: _heartScale,
                  child: const Icon(Icons.thumb_up,
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
  final bool isActive;
  const _MediaBackground({required this.item, required this.isActive});

  Widget _placeholderGradient(IconData icon) {
    final athlete = item.athlete!;
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
      child: Center(
        child: Icon(icon, size: 72, color: Colors.white30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = item.content!;

    if (content.type == ContentType.video) {
      if (content.fileUrl == null) {
        return _placeholderGradient(Icons.play_circle_fill);
      }
      return _VideoBackground(url: content.fileUrl!, isActive: isActive);
    }

    // ── Photo / Image Content ──────────────────
    if (content.fileUrl != null) {
      return Container(
        color: const Color(0xFF0D1117),
        child: Center(
          child: CachedNetworkImage(
            imageUrl: content.fileUrl!,
            fit: BoxFit.contain,
            placeholder: (context, url) => _placeholderGradient(Icons.image_outlined),
            errorWidget: (context, url, error) => _placeholderGradient(Icons.broken_image_outlined),
          ),
        ),
      );
    }

    // Photo without URL — show placeholder
    if (content.type == ContentType.photo) {
      return _placeholderGradient(Icons.image_outlined);
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

/// Plays the uploaded video, cropped to fill the card (like a short-form
/// feed). Playback follows the card's visibility — only the active page's
/// video plays, everything else stays paused. A small button lets the user
/// override that and pause/resume manually; the override resets whenever
/// the card becomes freshly visible again (a new "view" autoplays).
class _VideoBackground extends StatefulWidget {
  final String url;
  final bool isActive;
  const _VideoBackground({required this.url, required this.isActive});

  @override
  State<_VideoBackground> createState() => _VideoBackgroundState();
}

class _VideoBackgroundState extends State<_VideoBackground> {
  late final VideoPlayerController _controller;
  bool _initialized = false;
  bool _failed = false;
  bool _userPaused = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _controller
      ..setLooping(true)
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() => _initialized = true);
        if (widget.isActive) _controller.play();
      }).catchError((_) {
        if (mounted) setState(() => _failed = true);
      });
  }

  @override
  void didUpdateWidget(covariant _VideoBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        // Freshly visible again — treat as a new view and autoplay,
        // regardless of an earlier manual pause.
        _userPaused = false;
        if (_initialized) _controller.play();
      } else if (_initialized) {
        _controller.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePause() {
    setState(() => _userPaused = !_userPaused);
    if (_userPaused) {
      _controller.pause();
    } else if (widget.isActive) {
      _controller.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const ColoredBox(
        color: Color(0xFF0D1117),
        child: Center(
          child: Icon(Icons.error_outline, size: 64, color: Colors.white30),
        ),
      );
    }
    if (!_initialized) {
      return const ColoredBox(
        color: Color(0xFF0D1117),
        child: Center(child: CircularProgressIndicator(color: Colors.white54)),
      );
    }

    final paused = _userPaused || !widget.isActive;

    return GestureDetector(
      onTap: _togglePause,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              clipBehavior: Clip.hardEdge,
              child: SizedBox(
                width: _controller.value.size.width,
                height: _controller.value.size.height,
                child: VideoPlayer(_controller),
              ),
            ),
          ),
          if (paused)
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
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
  final bool isLiked;
  const _AthleteStrip({required this.item, required this.isLiked});

  @override
  Widget build(BuildContext context) {
    if (item.isAd) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              item.adTitle ?? 'Sponsored',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
            ),
            const SizedBox(height: 4),
            Text(
              item.adDescription ?? '',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }
    final content = item.content!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (content.type != ContentType.post)
            Text(
              content.title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
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
    if (item.isAd) return const SizedBox.shrink();
    final likeCount = item.likeCount + (isLiked ? 1 : 0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _RailBtn(
          icon: isLiked ? Icons.thumb_up : Icons.thumb_up_outlined,
          label: _fmt(likeCount),
          color: isLiked ? Colors.blueAccent : Colors.white,
          onTap: () {
            if (_ensureAuthenticated(context, ref)) {
              final authState = ref.read(authProvider);
              final userId = authState is AuthAuthenticated ? authState.user.id : 'guest';
              ref.read(discoveryProvider.notifier).toggleLike(item.content!.id, userId);
            }
          },
        ),
        const SizedBox(height: 14),
        _RailBtn(
          icon: Icons.chat_bubble_outline_rounded,
          label: _fmt(item.commentCount),
          color: Colors.white,
          onTap: () {
            if (_ensureAuthenticated(context, ref)) {
              _showCommentsSheet(context, ref, item);
            }
          },
        ),
        const SizedBox(height: 14),
        _RailBtn(
          icon: Icons.share_rounded,
          label: 'Share',
          color: Colors.white,
          onTap: () {
            Clipboard.setData(ClipboardData(text: item.content?.fileUrl ?? 'https://playsmart.app/content/${item.content?.id}'));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Link copied to clipboard! Ready to share.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        const SizedBox(height: 14),
        (() {
          final isBookmarked = ref.watch(discoveryProvider).bookmarkedContentIds.contains(item.content!.id);
          return _RailBtn(
            icon: isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            label: 'Save',
            color: isBookmarked ? Colors.amber : Colors.white,
            onTap: () {
              if (_ensureAuthenticated(context, ref)) {
                final authState = ref.read(authProvider);
                final userId = authState is AuthAuthenticated ? authState.user.id : 'guest';
                ref.read(discoveryProvider.notifier).toggleBookmark(item.content!.id, userId);
              }
            },
          );
        }()),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () {
            if (_ensureAuthenticated(context, ref)) {
              context.push('/athlete/${item.athlete!.id}');
            }
          },
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.accentPrimary,
              child: Text(
                item.athlete!.displayName.isNotEmpty
                    ? item.athlete!.displayName[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

void _showCommentsSheet(BuildContext context, WidgetRef ref, FeedItem item) {
  if (item.content == null) return;
  final contentId = item.content!.id;
  final commentController = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final discoveryRepo = ref.read(discoveryRepositoryProvider);
          final authState = ref.read(authProvider);

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              height: 440,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Comments',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: FutureBuilder(
                      future: discoveryRepo.getComments(contentId),
                      builder: (ctx, snap) {
                        final comments = snap.data ?? [];
                        if (snap.connectionState == ConnectionState.waiting && comments.isEmpty) {
                          return const Center(child: CircularProgressIndicator(color: Colors.white54));
                        }
                        if (comments.isEmpty) {
                          return const Center(
                            child: Text(
                              'No comments yet. Be the first to comment!',
                              style: TextStyle(color: Colors.white54),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: comments.length,
                          itemBuilder: (ctx, idx) {
                            final c = comments[idx];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: const Color(0xFF4A90D9),
                                    child: Text(
                                      c.userName.isNotEmpty ? c.userName[0].toUpperCase() : '?',
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(c.userName, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 2),
                                        Text(c.text, style: const TextStyle(color: Colors.white, fontSize: 14)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  const Divider(color: Colors.white24),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.white30),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.send, color: Color(0xFF4A90D9)),
                        onPressed: () async {
                          final text = commentController.text.trim();
                          if (text.isNotEmpty) {
                            final userId = authState is AuthAuthenticated ? authState.user.id : 'guest';
                            final userName = authState is AuthAuthenticated ? authState.user.name : 'Guest User';
                            await ref.read(discoveryProvider.notifier).addComment(
                              contentId: contentId,
                              userId: userId,
                              userName: userName,
                              text: text,
                            );
                            commentController.clear();
                            setSheetState(() {});
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

void _showShortlistSelectionSheet(BuildContext context, WidgetRef ref, String athleteId, String athleteName) {
  final authState = ref.read(authProvider);
  if (authState is! AuthAuthenticated) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please sign in to shortlist athletes.')),
    );
    return;
  }
  
  if (authState.user.role == AccountRole.athlete) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Only recruiters and clubs can shortlist athletes.')),
    );
    return;
  }

  ref.read(shortlistProvider.notifier).loadShortlists();

  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(shortlistProvider);
          
          if (state.isLoading) {
            return const SizedBox(
              height: 250,
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            );
          }
          
          return Container(
            padding: const EdgeInsets.all(20),
            height: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Save to Shortlist',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: state.shortlists.isEmpty
                      ? const Center(
                          child: Text(
                            'No shortlists created yet.',
                            style: TextStyle(color: Colors.white30),
                          ),
                        )
                      : ListView.builder(
                          itemCount: state.shortlists.length,
                          itemBuilder: (ctx, idx) {
                            final list = state.shortlists[idx];
                            final isAdded = list.athleteIds.contains(athleteId);
                            return ListTile(
                              title: Text(list.name, style: const TextStyle(color: Colors.white)),
                              trailing: Icon(
                                isAdded ? Icons.bookmark_added : Icons.bookmark_add_outlined,
                                color: isAdded ? const Color(0xFF4A90D9) : Colors.white54,
                              ),
                              onTap: () {
                                if (isAdded) {
                                  ref.read(shortlistProvider.notifier).removeAthlete(list.id, athleteId);
                                } else {
                                  ref.read(shortlistProvider.notifier).addAthlete(list.id, athleteId);
                                }
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isAdded
                                        ? 'Removed $athleteName from ${list.name}'
                                        : 'Added $athleteName to ${list.name}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                            );
                          },
                        ),
                ),
                const Divider(color: Colors.white24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Shortlist'),
                    onPressed: () {
                      Navigator.pop(context);
                      _showCreateShortlistDialog(context, ref, athleteId, athleteName);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

void _showCreateShortlistDialog(BuildContext context, WidgetRef ref, String athleteId, String athleteName) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Create Shortlist'),
      content: TextField(
        controller: controller,
        decoration: const InputDecoration(
          labelText: 'Shortlist Name',
          hintText: 'e.g. Uganda U-17 Strikers',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            final name = controller.text.trim();
            if (name.isNotEmpty) {
              await ref.read(shortlistProvider.notifier).createShortlist(name);
              final state = ref.read(shortlistProvider);
              if (state.shortlists.isNotEmpty) {
                final newList = state.shortlists.last;
                await ref.read(shortlistProvider.notifier).addAthlete(newList.id, athleteId);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added $athleteName to new shortlist $name'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            }
          },
          child: const Text('Create & Add'),
        ),
      ],
    ),
  );
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

class _TopBar extends ConsumerWidget {
  final bool isSearching;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleSearch;
  final VoidCallback onOpenSaved;

  const _TopBar({
    required this.isSearching,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleSearch,
    required this.onOpenSaved,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      child: isSearching
          ? Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: onToggleSearch,
                ),
                Expanded(
                  child: TextField(
                    controller: searchController,
                    autofocus: true,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: 'Search videos...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                if (searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Colors.white),
                    onPressed: () {
                      searchController.clear();
                      onSearchChanged('');
                    },
                  ),
              ],
            )
          : Row(
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
                  icon: const Icon(Icons.bookmark_border_rounded,
                      color: Colors.white, size: 26),
                  onPressed: () {
                    if (_ensureAuthenticated(context, ref)) {
                      onOpenSaved();
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 26),
                  onPressed: () {
                    if (_ensureAuthenticated(context, ref)) {
                      context.push(AppRouter.notifications);
                    }
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.search_rounded,
                      color: Colors.white, size: 26),
                  onPressed: onToggleSearch,
                ),
              ],
            ),
    );
  }
}

void _showSavedContentSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF1E293B),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(discoveryProvider);
          final savedItems = state.feedItems.where((item) {
            if (item.isAd) return false;
            return state.bookmarkedContentIds.contains(item.content!.id);
          }).toList();

          return Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              height: 400,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Saved Videos & Content',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: savedItems.isEmpty
                        ? const Center(
                            child: Text(
                              'No saved items yet.',
                              style: TextStyle(color: Colors.white70, fontSize: 14),
                            ),
                          )
                        : GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: savedItems.length,
                            itemBuilder: (ctx, idx) {
                              final item = savedItems[idx];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                  context.push('/athlete/${item.athlete!.id}');
                                },
                                child: ContentThumbnail(
                                  content: item.content!,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
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
// Progress dots (vertical, right side)
// ─────────────────────────────────────────────────────────────────────────────

class _VerticalProgressDots extends StatelessWidget {
  final int count;
  final int current;
  const _VerticalProgressDots({required this.count, required this.current});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 4),
          width: 6,
          height: active ? 20 : 6,
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

bool _ensureAuthenticated(BuildContext context, WidgetRef ref) {
  final authState = ref.read(authProvider);
  if (authState is! AuthAuthenticated) {
    context.push(AppRouter.auth);
    return false;
  }
  return true;
}

import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';
import 'package:play_smart/discovery/models/feed_item.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Manages a sliding window of [VideoPlayerController] instances for the discovery feed.
/// Preloads adjacent videos (index - 1 and index + 1) in the background so playback
/// is near-instantaneous upon swiping.
class VideoPreloadManager extends ChangeNotifier {
  final int maxPreloadDistance;

  List<FeedItem> _items = const [];
  int _currentIndex = 0;
  bool _isDisposed = false;

  final Map<int, VideoPlayerController> _controllers = {};
  final Set<int> _initializingIndices = {};
  final Set<int> _failedIndices = {};

  VideoPreloadManager({this.maxPreloadDistance = 1});

  int get currentIndex => _currentIndex;
  List<FeedItem> get items => _items;

  /// Returns the controller for [index] if one exists in the sliding window.
  VideoPlayerController? getController(int index) => _controllers[index];

  /// Checks if the controller at [index] is initialized and ready to render.
  bool isInitialized(int index) {
    final c = _controllers[index];
    return c != null && c.value.isInitialized;
  }

  /// Checks if initialization failed for [index].
  bool hasError(int index) {
    if (_failedIndices.contains(index)) return true;
    final c = _controllers[index];
    return c != null && c.value.hasError;
  }

  /// Updates the feed items list and refreshes the preloaded window.
  void setFeedItems(List<FeedItem> items) {
    if (_isDisposed) return;
    _items = items;
    _updateWindow();
  }

  /// Sets the active visible page index and shifts the preload window.
  void setCurrentIndex(int index) {
    if (_isDisposed || _currentIndex == index) return;

    // Pause the old active controller if playing
    final oldController = _controllers[_currentIndex];
    if (oldController != null && oldController.value.isPlaying) {
      oldController.pause();
    }

    _currentIndex = index;
    _updateWindow();
    _notifySafely();
  }

  /// Pauses all active controllers across the entire pool.
  void pauseAll() {
    for (final controller in _controllers.values) {
      if (controller.value.isPlaying) {
        controller.pause();
      }
    }
  }

  /// Plays the controller at the current index if initialized.
  void playCurrent() {
    final current = _controllers[_currentIndex];
    if (current != null && current.value.isInitialized && !current.value.isPlaying) {
      current.play();
    }
  }

  /// Pauses the controller at the current index.
  void pauseCurrent() {
    final current = _controllers[_currentIndex];
    if (current != null && current.value.isPlaying) {
      current.pause();
    }
  }

  bool _isInWindow(int index) {
    final start = (_currentIndex - maxPreloadDistance).clamp(0, _items.length - 1);
    final end = (_currentIndex + maxPreloadDistance).clamp(0, _items.length - 1);
    return index >= start && index <= end;
  }

  void _updateWindow() {
    if (_isDisposed || _items.isEmpty) return;

    final start = (_currentIndex - maxPreloadDistance).clamp(0, _items.length - 1);
    final end = (_currentIndex + maxPreloadDistance).clamp(0, _items.length - 1);

    final targetIndices = <int>{};
    for (int i = start; i <= end; i++) {
      targetIndices.add(i);
    }

    // 1. Evict and dispose controllers outside the window to free memory & decoders
    final toRemove = <int>[];
    _controllers.forEach((index, controller) {
      if (!targetIndices.contains(index)) {
        toRemove.add(index);
      }
    });

    for (final index in toRemove) {
      final controller = _controllers.remove(index);
      _failedIndices.remove(index);
      _initializingIndices.remove(index);
      try {
        controller?.pause();
        controller?.dispose();
      } catch (_) {}
    }

    // 2. Preload targets in priority order: current -> next (+1) -> previous (-1)
    final priorityOrder = <int>[];
    if (targetIndices.contains(_currentIndex)) {
      priorityOrder.add(_currentIndex);
    }
    if (targetIndices.contains(_currentIndex + 1)) {
      priorityOrder.add(_currentIndex + 1);
    }
    if (targetIndices.contains(_currentIndex - 1)) {
      priorityOrder.add(_currentIndex - 1);
    }
    for (final index in targetIndices) {
      if (!priorityOrder.contains(index)) {
        priorityOrder.add(index);
      }
    }

    for (final index in priorityOrder) {
      if (!_controllers.containsKey(index) && !_initializingIndices.contains(index)) {
        _preloadIndex(index);
      }
    }
  }

  void _preloadIndex(int index) {
    if (index < 0 || index >= _items.length) return;

    final item = _items[index];
    if (item.content?.type != ContentType.video) return;

    final fileUrl = item.content?.fileUrl;
    if (fileUrl == null || fileUrl.trim().isEmpty) return;

    _initializingIndices.add(index);
    _failedIndices.remove(index);

    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.networkUrl(
        Uri.parse(fileUrl.trim()),
      );
    } catch (_) {
      _initializingIndices.remove(index);
      _failedIndices.add(index);
      _notifySafely();
      return;
    }

    _controllers[index] = controller;
    controller.setLooping(true);

    controller.initialize().then((_) {
      _initializingIndices.remove(index);
      if (_isDisposed || !_isInWindow(index)) {
        // Disposed or moved out of window while loading
        _controllers.remove(index);
        try {
          controller?.dispose();
        } catch (_) {}
        return;
      }
      _notifySafely();
    }).catchError((_) {
      _initializingIndices.remove(index);
      _failedIndices.add(index);
      _notifySafely();
    });
  }

  void _notifySafely() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    for (final controller in _controllers.values) {
      try {
        controller.pause();
        controller.dispose();
      } catch (_) {}
    }
    _controllers.clear();
    _initializingIndices.clear();
    _failedIndices.clear();
    super.dispose();
  }
}

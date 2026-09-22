import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/discovery/models/feed_item.dart';
import 'package:play_smart/discovery/services/video_preload_manager.dart';
import 'package:play_smart/shared/types/domain_types.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VideoPreloadManager', () {
    late VideoPreloadManager manager;

    setUp(() {
      manager = VideoPreloadManager(maxPreloadDistance: 1);
    });

    tearDown(() {
      manager.dispose();
    });

    test('initial state has empty items and index 0', () {
      expect(manager.currentIndex, 0);
      expect(manager.items, isEmpty);
      expect(manager.getController(0), isNull);
      expect(manager.isInitialized(0), isFalse);
      expect(manager.hasError(0), isFalse);
    });

    test('setCurrentIndex updates index and notifies listeners', () {
      var notified = false;
      manager.addListener(() => notified = true);

      manager.setCurrentIndex(2);
      expect(manager.currentIndex, 2);
      expect(notified, isTrue);

      // Calling again with same index should not notify
      notified = false;
      manager.setCurrentIndex(2);
      expect(notified, isFalse);
    });

    test('pauseAll runs cleanly when no controllers are active', () {
      expect(() => manager.pauseAll(), returnsNormally);
      expect(() => manager.playCurrent(), returnsNormally);
      expect(() => manager.pauseCurrent(), returnsNormally);
    });

    test('ignores non-video feed items during preload evaluation', () {
      final items = [
        FeedItem(
          content: AthleteContent(
            id: 'c1',
            athleteId: 'a1',
            type: ContentType.photo,
            title: 'Photo Post',
            fileUrl: 'https://example.com/photo.jpg',
            createdAt: DateTime.now(),
          ),
        ),
        FeedItem(
          content: AthleteContent(
            id: 'c2',
            athleteId: 'a1',
            type: ContentType.post,
            title: 'Text Post',
            createdAt: DateTime.now(),
          ),
        ),
      ];

      manager.setFeedItems(items);
      expect(manager.items.length, 2);
      expect(manager.getController(0), isNull);
      expect(manager.getController(1), isNull);
    });

    test('disposal cleans up without exceptions', () {
      final m = VideoPreloadManager(maxPreloadDistance: 2);
      expect(() => m.dispose(), returnsNormally);
      // Double dispose is safe
      expect(() => m.dispose(), returnsNormally);
    });
  });
}

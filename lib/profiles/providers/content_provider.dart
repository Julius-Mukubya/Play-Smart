import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/profiles/repositories/content_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Content repository provider.
final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository();
});

/// Content notifier — manages athlete content state.
class ContentNotifier extends Notifier<AsyncValue<List<AthleteContent>>> {
  @override
  AsyncValue<List<AthleteContent>> build() {
    return const AsyncValue.data([]);
  }

  ContentRepository get _repository => ref.read(contentRepositoryProvider);

  /// Load content for a specific athlete.
  Future<void> loadContent(String athleteId) async {
    state = const AsyncValue.loading();
    try {
      final content = await _repository.getContentByAthleteId(athleteId);
      state = AsyncValue.data(content);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create new content.
  Future<AthleteContent> createContent(AthleteContent content) async {
    try {
      final result = await _repository.createContent(content);
      // Reload content list after creation
      await loadContent(content.athleteId);
      return result;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete content.
  Future<void> deleteContent(String contentId, String athleteId) async {
    try {
      await _repository.deleteContent(contentId);
      await loadContent(athleteId);
    } catch (e) {
      rethrow;
    }
  }
}

/// Content state provider.
final contentProvider = NotifierProvider<ContentNotifier, AsyncValue<List<AthleteContent>>>(
  ContentNotifier.new,
);
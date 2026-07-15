import 'package:play_smart/profiles/repositories/content_repository.dart' show ContentException;
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

/// In-memory content repository used by unit tests. Not wired into the app —
/// see `ContentRepository` (Supabase-backed) for the production implementation.
class MockContentRepository {
  final List<AthleteContent> _contents = List.from(MockData.allContent);

  List<AthleteContent> getContentByAthleteId(String athleteId) {
    return _contents.where((c) => c.athleteId == athleteId).toList();
  }

  Future<AthleteContent> createContent(AthleteContent content) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _contents.add(content);
    return content;
  }

  Future<void> deleteContent(String contentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _contents.removeWhere((c) => c.id == contentId);
  }

  Future<AthleteContent> updateContent(AthleteContent updated) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _contents.indexWhere((c) => c.id == updated.id);
    if (index >= 0) {
      _contents[index] = updated;
      return updated;
    }
    throw ContentException('Content not found.');
  }
}

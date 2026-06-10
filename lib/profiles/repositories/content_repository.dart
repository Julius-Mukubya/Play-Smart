import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

/// Content repository — handles athlete content CRUD operations.
/// Currently uses mock data; swap with real API calls when backend is connected.
class ContentRepository {
  final List<AthleteContent> _contents = List.from(MockData.allContent);

  /// Get all content for a specific athlete.
  List<AthleteContent> getContentByAthleteId(String athleteId) {
    return _contents.where((c) => c.athleteId == athleteId).toList();
  }

  /// Create a new content entry.
  Future<AthleteContent> createContent(AthleteContent content) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _contents.add(content);
    return content;
  }

  /// Delete a content entry.
  Future<void> deleteContent(String contentId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _contents.removeWhere((c) => c.id == contentId);
  }

  /// Update an existing content entry.
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

/// Exception thrown by content operations.
class ContentException implements Exception {
  final String message;
  ContentException(this.message);

  @override
  String toString() => message;
}
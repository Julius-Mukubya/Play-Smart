import 'dart:typed_data';
import 'package:play_smart/shared/types/domain_types.dart';

/// Mock/In-memory Content repository — ready to be wired up with Firebase Firestore & Cloudflare R2.
class ContentRepository {
  final List<AthleteContent> _content = [];

  Future<List<AthleteContent>> getContentByAthleteId(String athleteId) async {
    return _content.where((c) => c.athleteId == athleteId).toList();
  }

  Future<String> uploadContentFile({
    required String userId,
    required String contentId,
    required String filename,
    required Uint8List bytes,
  }) async {
    // Return dummy URL
    return 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4';
  }

  Future<AthleteContent> createContent(AthleteContent content) async {
    _content.add(content);
    return content;
  }

  Future<void> deleteContent(String contentId) async {
    _content.removeWhere((c) => c.id == contentId);
  }

  Future<AthleteContent> updateContent(AthleteContent updated) async {
    final idx = _content.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _content[idx] = updated;
      return updated;
    }
    throw ContentException('Content not found.');
  }
}

class ContentException implements Exception {
  final String message;
  ContentException(this.message);

  @override
  String toString() => message;
}

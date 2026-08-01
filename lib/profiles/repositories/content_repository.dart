import 'dart:typed_data';
import 'package:play_smart/core/storage/firebase_storage_service.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Content repository integrated with Firebase Storage.
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
    final ext = filename.split('.').last.toLowerCase();
    final contentType = ext == 'mp4' ? 'video/mp4' : (ext == 'png' ? 'image/png' : 'image/jpeg');

    return FirebaseStorageService.upload(
      path: 'content/$userId/$contentId/$filename',
      bytes: bytes,
      contentType: contentType,
    );
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

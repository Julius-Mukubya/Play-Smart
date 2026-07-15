import 'dart:typed_data';

import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Content repository — Supabase-backed CRUD for `public.athlete_content`,
/// plus file upload to the `athlete-content` storage bucket.
class ContentRepository {
  static const _table = 'athlete_content';
  static const _bucket = 'athlete-content';

  Future<List<AthleteContent>> getContentByAthleteId(String athleteId) async {
    final rows = await supabase
        .from(_table)
        .select()
        .eq('athlete_id', athleteId)
        .order('created_at', ascending: false);
    return (rows as List).map((r) => AthleteContent.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Uploads raw file bytes to `athlete-content/{userId}/{contentId}/{filename}`
  /// and returns the public URL to store in `file_url`/`thumbnail_url`. See
  /// `lib/supabase-integration.md` section 6 for bucket/path conventions.
  ///
  /// This does NOT compress video — that pipeline is still an open decision
  /// (`context/supabase-backend.md` section 12, decision 3).
  Future<String> uploadContentFile({
    required String userId,
    required String contentId,
    required String filename,
    required Uint8List bytes,
  }) async {
    final path = '$userId/$contentId/$filename';
    await supabase.storage.from(_bucket).uploadBinary(path, bytes);
    return supabase.storage.from(_bucket).getPublicUrl(path);
  }

  Future<AthleteContent> createContent(AthleteContent content) async {
    try {
      final row = await supabase.from(_table).insert({
        'athlete_id': content.athleteId,
        'type': content.type.name,
        'title': content.title,
        'description': content.description,
        'file_url': content.fileUrl,
        'thumbnail_url': content.thumbnailUrl,
        'moment_tag': content.momentTag?.name,
      }).select().single();
      return AthleteContent.fromJson(row);
    } catch (e) {
      throw ContentException('Could not save content: ${e.toString()}');
    }
  }

  Future<void> deleteContent(String contentId) async {
    await supabase.from(_table).delete().eq('id', contentId);
  }

  Future<AthleteContent> updateContent(AthleteContent updated) async {
    try {
      final row = await supabase.from(_table).update({
        'title': updated.title,
        'description': updated.description,
        'file_url': updated.fileUrl,
        'thumbnail_url': updated.thumbnailUrl,
        'moment_tag': updated.momentTag?.name,
      }).eq('id', updated.id).select().single();
      return AthleteContent.fromJson(row);
    } catch (e) {
      throw ContentException('Content not found.');
    }
  }
}

/// Exception thrown by content operations.
class ContentException implements Exception {
  final String message;
  ContentException(this.message);

  @override
  String toString() => message;
}

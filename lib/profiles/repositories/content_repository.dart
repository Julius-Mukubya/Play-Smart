import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:play_smart/core/storage/firebase_storage_service.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Content repository integrated with Cloud Firestore and Firebase Storage.
class ContentRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final List<AthleteContent> _content = [];
  List<AthleteContent>? _cachedAllContent;
  DateTime? _lastFetchTime;
  static const Duration _cacheDuration = Duration(seconds: 45);

  ContentRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  void invalidateCache() {
    _cachedAllContent = null;
    _lastFetchTime = null;
  }

  Future<List<AthleteContent>> getContentByAthleteId(String athleteId) async {
    try {
      final snap = await _firestore
          .collection('athlete_content')
          .where('athleteId', isEqualTo: athleteId)
          .get();

      if (snap.docs.isNotEmpty) {
        final firestoreList = snap.docs
            .map((doc) => AthleteContent.fromMap(doc.data(), doc.id))
            .toList();

        // Merge with any in-memory items not yet synced
        final existingIds = firestoreList.map((c) => c.id).toSet();
        for (final item in _content) {
          if (item.athleteId == athleteId && !existingIds.contains(item.id)) {
            firestoreList.add(item);
          }
        }
        return firestoreList;
      }
    } catch (e) {
      debugPrint('ContentRepository.getContentByAthleteId Firestore error: $e');
    }

    return _content.where((c) => c.athleteId == athleteId).toList();
  }

  Future<List<AthleteContent>> getAllContent({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _cachedAllContent != null &&
        _lastFetchTime != null &&
        now.difference(_lastFetchTime!) < _cacheDuration) {
      return List<AthleteContent>.from(_cachedAllContent!);
    }

    final List<AthleteContent> all = [];
    try {
      final snap = await _firestore
          .collection('athlete_content')
          .get();

      for (final doc in snap.docs) {
        all.add(AthleteContent.fromMap(doc.data(), doc.id));
      }
    } catch (e) {
      debugPrint('ContentRepository.getAllContent Firestore error: $e');
    }

    // Merge in-memory content
    final existingIds = all.map((c) => c.id).toSet();
    for (final item in _content) {
      if (!existingIds.contains(item.id)) {
        all.add(item);
      }
    }

    // If Firestore has no content, scan Firebase Storage content directory (with 4s timeout)
    if (all.isEmpty) {
      try {
        final storageItems = await _discoverStorageContent()
            .timeout(const Duration(seconds: 4), onTimeout: () => []);
        all.addAll(storageItems);
      } catch (e) {
        debugPrint('ContentRepository: storage discovery skipped: $e');
      }
    }

    _cachedAllContent = List<AthleteContent>.from(all);
    _lastFetchTime = now;
    return all;
  }

  /// Discovers media files directly from Firebase Storage bucket under content/
  Future<List<AthleteContent>> _discoverStorageContent() async {
    final List<AthleteContent> discovered = [];
    try {
      final rootRef = _storage.ref('content');
      final usersList = await rootRef.listAll();

      await Future.wait(usersList.prefixes.map((userPrefix) async {
        try {
          final contentList = await userPrefix.listAll();
          await Future.wait(contentList.prefixes.map((contentPrefix) async {
            try {
              final files = await contentPrefix.listAll();
              String? mediaUrl;
              String? thumbUrl;
              ContentType type = ContentType.video;

              for (final file in files.items) {
                final name = file.name.toLowerCase();
                final url = await file.getDownloadURL();
                if (name.contains('thumb')) {
                  thumbUrl = url;
                } else if (name.endsWith('.mp4')) {
                  mediaUrl = url;
                  type = ContentType.video;
                } else if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png')) {
                  mediaUrl = url;
                  type = ContentType.photo;
                }
              }

              if (mediaUrl != null) {
                discovered.add(
                  AthleteContent(
                    id: contentPrefix.name,
                    athleteId: userPrefix.name,
                    type: type,
                    title: 'Training Highlight',
                    description: 'Athlete training moment uploaded to VANTRA.',
                    fileUrl: mediaUrl,
                    thumbnailUrl: thumbUrl ?? mediaUrl,
                    momentTag: MomentType.goal,
                  ),
                );
              }
            } catch (_) {}
          }));
        } catch (_) {}
      }));
    } catch (e) {
      debugPrint('Error during Firebase Storage content discovery: $e');
    }
    return discovered;
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
    final id = content.id.isNotEmpty
        ? content.id
        : _firestore.collection('athlete_content').doc().id;

    final updated = AthleteContent(
      id: id,
      athleteId: content.athleteId,
      type: content.type,
      title: content.title,
      description: content.description,
      fileUrl: content.fileUrl,
      thumbnailUrl: content.thumbnailUrl,
      momentTag: content.momentTag,
      likeCount: content.likeCount,
      commentCount: content.commentCount,
      createdAt: content.createdAt,
    );

    _content.add(updated);
    invalidateCache();

    try {
      await _firestore
          .collection('athlete_content')
          .doc(id)
          .set(updated.toMap());
    } catch (e) {
      debugPrint('ContentRepository: Failed to write content to Firestore: $e');
    }

    return updated;
  }

  Future<void> deleteContent(String contentId) async {
    _content.removeWhere((c) => c.id == contentId);
    invalidateCache();
    try {
      await _firestore.collection('athlete_content').doc(contentId).delete();
    } catch (e) {
      debugPrint('ContentRepository: Failed to delete from Firestore: $e');
    }
  }

  Future<AthleteContent> updateContent(AthleteContent updated) async {
    final idx = _content.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _content[idx] = updated;
    }
    invalidateCache();
    try {
      await _firestore
          .collection('athlete_content')
          .doc(updated.id)
          .update(updated.toMap());
    } catch (_) {}
    return updated;
  }
}

class ContentException implements Exception {
  final String message;
  ContentException(this.message);

  @override
  String toString() => message;
}

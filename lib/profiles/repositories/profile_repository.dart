import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:play_smart/core/storage/firebase_storage_service.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Profile repository integrated with Cloud Firestore and Firebase Storage.
class ProfileRepository {
  final FirebaseFirestore? _firestoreInstance;
  FirebaseFirestore get _firestore => _firestoreInstance ?? FirebaseFirestore.instance;
  final Map<String, Athlete> _athletes = {};

  ProfileRepository({FirebaseFirestore? firestore}) : _firestoreInstance = firestore;

  Future<String> uploadAvatar({
    required String userId,
    required String filename,
    required Uint8List bytes,
  }) async {
    // Determine content type extension
    final ext = filename.split('.').last.toLowerCase();
    final contentType = ext == 'png' ? 'image/png' : 'image/jpeg';
    
    return FirebaseStorageService.upload(
      path: 'avatars/$userId/$filename',
      bytes: bytes,
      contentType: contentType,
    );
  }

  Future<List<Athlete>> getAllAthletes() async {
    final Map<String, Athlete> map = Map.from(_athletes);
    try {
      final snap = await _firestore.collection('athletes').get();
      for (final doc in snap.docs) {
        map[doc.id] = Athlete.fromMap(doc.data(), doc.id);
      }
    } catch (_) {}
    return map.values.toList();
  }

  Future<Athlete?> getAthleteById(String id) async {
    if (_athletes.containsKey(id)) return _athletes[id];
    try {
      final doc = await _firestore.collection('athletes').doc(id).get();
      if (doc.exists && doc.data() != null) {
        final athlete = Athlete.fromMap(doc.data()!, doc.id);
        _athletes[id] = athlete;
        return athlete;
      }
      final q = await _firestore.collection('athletes').where('userId', isEqualTo: id).get();
      if (q.docs.isNotEmpty) {
        final athlete = Athlete.fromMap(q.docs.first.data(), q.docs.first.id);
        _athletes[id] = athlete;
        return athlete;
      }
      final userDoc = await _firestore.collection('users').doc(id).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final athlete = Athlete(
          id: id,
          userId: id,
          displayName: (data['displayName'] ?? data['name'] ?? 'Athlete') as String,
          photoUrl: (data['photoUrl'] ?? data['avatarUrl'] ?? data['photo_url']) as String?,
          sports: List<String>.from(data['sports'] ?? ['Football']),
          positions: List<String>.from(data['positions'] ?? ['Forward']),
          bio: (data['bio'] ?? '') as String,
        );
        _athletes[id] = athlete;
        return athlete;
      }
    } catch (_) {}
    return _athletes[id];
  }

  Future<Athlete?> getAthleteByUserId(String userId) async {
    try {
      return _athletes.values.firstWhere((a) => a.userId == userId);
    } catch (_) {}

    try {
      final q = await _firestore.collection('athletes').where('userId', isEqualTo: userId).get();
      if (q.docs.isNotEmpty) {
        final athlete = Athlete.fromMap(q.docs.first.data(), q.docs.first.id);
        _athletes[athlete.id] = athlete;
        return athlete;
      }
      final doc = await _firestore.collection('athletes').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        final athlete = Athlete.fromMap(doc.data()!, doc.id);
        _athletes[athlete.id] = athlete;
        return athlete;
      }
      final userDoc = await _firestore.collection('users').doc(userId).get();
      if (userDoc.exists && userDoc.data() != null) {
        final data = userDoc.data()!;
        final athlete = Athlete(
          id: userId,
          userId: userId,
          displayName: (data['displayName'] ?? data['name'] ?? 'Athlete') as String,
          photoUrl: (data['photoUrl'] ?? data['avatarUrl'] ?? data['photo_url']) as String?,
          sports: List<String>.from(data['sports'] ?? ['Football']),
          positions: List<String>.from(data['positions'] ?? ['Forward']),
          bio: (data['bio'] ?? '') as String,
        );
        _athletes[athlete.id] = athlete;
        return athlete;
      }
    } catch (_) {}

    final defaultAthlete = Athlete(
      id: 'athlete_$userId',
      userId: userId,
      displayName: 'Athlete',
      sports: ['Football'],
      positions: ['Forward'],
      bio: 'Athlete profile on Play Smart.',
      profileBadgeLevel: TrustBadgeLevel.selfReported,
      availabilityStatus: AvailabilityStatus.openToTrials,
    );
    _athletes[defaultAthlete.id] = defaultAthlete;
    return defaultAthlete;
  }

  Future<Athlete> createProfile(Athlete profile) async {
    _athletes[profile.id] = profile;
    try {
      await _firestore
          .collection('athletes')
          .doc(profile.id)
          .set(profile.toMap(), SetOptions(merge: true));
    } catch (_) {}
    return profile;
  }

  Future<Athlete> updateProfile(Athlete updated) async {
    _athletes[updated.id] = updated;
    try {
      await _firestore
          .collection('athletes')
          .doc(updated.id)
          .set(updated.toMap(), SetOptions(merge: true));
    } catch (_) {}
    return updated;
  }

  double calculateCompleteness(Athlete profile) {
    return 1.0;
  }

  Future<Athlete> addAchievement(String athleteId, Achievement achievement) async {
    final athlete = _athletes[athleteId];
    if (athlete == null) throw ProfileException('Athlete not found');
    final updated = athlete.copyWith(
      achievements: [...athlete.achievements, achievement],
    );
    _athletes[athleteId] = updated;
    return updated;
  }

  Future<Athlete> removeAchievement(String athleteId, String achievementId) async {
    final athlete = _athletes[athleteId];
    if (athlete == null) throw ProfileException('Athlete not found');
    final updated = athlete.copyWith(
      achievements: athlete.achievements.where((a) => a.id != achievementId).toList(),
    );
    _athletes[athleteId] = updated;
    return updated;
  }

  Future<List<Athlete>> searchAthletes({
    String? sport,
    String? position,
    int? minAge,
    int? maxAge,
    String? location,
    AvailabilityStatus? availability,
    TrustBadgeLevel? minBadge,
  }) async {
    return _athletes.values.toList();
  }
}

class ProfileException implements Exception {
  final String message;
  ProfileException(this.message);

  @override
  String toString() => message;
}

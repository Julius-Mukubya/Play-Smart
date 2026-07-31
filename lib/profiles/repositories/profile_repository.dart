import 'dart:typed_data';
import 'package:play_smart/shared/types/domain_types.dart';

/// Mock/In-memory Profile repository — ready to be wired up with Firebase Firestore & Cloudflare R2.
class ProfileRepository {
  final Map<String, Athlete> _athletes = {};

  Future<String> uploadAvatar({
    required String userId,
    required String filename,
    required Uint8List bytes,
  }) async {
    // Return dummy URL
    return 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&w=150';
  }

  Future<List<Athlete>> getAllAthletes() async {
    return _athletes.values.toList();
  }

  Future<Athlete?> getAthleteById(String id) async {
    return _athletes[id];
  }

  Future<Athlete?> getAthleteByUserId(String userId) async {
    return _athletes.values.firstWhere(
      (a) => a.userId == userId,
      orElse: () => Athlete(
        id: 'mock_athlete_$userId',
        userId: userId,
        displayName: 'Julius Mukubya',
        sports: ['Football'],
        positions: ['Defender'],
        bio: 'Determined defender playing for local club.',
        profileBadgeLevel: TrustBadgeLevel.selfReported,
        availabilityStatus: AvailabilityStatus.openToTrials,
      ),
    );
  }

  Future<Athlete> createProfile(Athlete profile) async {
    _athletes[profile.id] = profile;
    return profile;
  }

  Future<Athlete> updateProfile(Athlete updated) async {
    _athletes[updated.id] = updated;
    return updated;
  }

  double calculateCompleteness(Athlete profile) {
    return 1.0;
  }

  Future<Athlete> addAchievement(String athleteId, Achievement achievement) async {
    return _athletes[athleteId]!;
  }

  Future<Athlete> removeAchievement(String athleteId, String achievementId) async {
    return _athletes[athleteId]!;
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

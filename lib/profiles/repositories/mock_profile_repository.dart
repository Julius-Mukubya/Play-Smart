import 'package:play_smart/profiles/repositories/profile_repository.dart' show ProfileException;
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

/// In-memory profile repository used by unit tests. Not wired into the app —
/// see `ProfileRepository` (Supabase-backed) for the production implementation.
class MockProfileRepository {
  final List<Athlete> _athletes = List.from(MockData.athletes);

  List<Athlete> getAllAthletes() => List.unmodifiable(_athletes);

  Athlete? getAthleteById(String id) {
    try {
      return _athletes.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  Athlete? getAthleteByUserId(String userId) {
    try {
      return _athletes.firstWhere((a) => a.userId == userId);
    } catch (_) {
      return null;
    }
  }

  Future<Athlete> createProfile(Athlete profile) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _athletes.add(profile);
    return profile;
  }

  Future<Athlete> updateProfile(Athlete updated) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final index = _athletes.indexWhere((a) => a.id == updated.id);
    if (index >= 0) {
      _athletes[index] = updated;
      return updated;
    }
    throw ProfileException('Profile not found.');
  }

  double calculateCompleteness(Athlete profile) {
    int filled = 0;
    int total = 0;

    if (profile.displayName.isNotEmpty) filled++;
    total++;

    if (profile.sports.isNotEmpty) filled++;
    total++;

    if (profile.positions.isNotEmpty) filled++;
    total++;

    if (profile.age != null) filled++;
    total++;

    if (profile.height != null) filled++;
    total++;

    if (profile.weight != null) filled++;
    total++;

    if (profile.dominantFootHand != null && profile.dominantFootHand!.isNotEmpty) filled++;
    total++;

    if (profile.currentTeam != null && profile.currentTeam!.isNotEmpty) filled++;
    total++;

    if (profile.country != null && profile.country!.isNotEmpty) filled++;
    total++;

    if (profile.bio != null && profile.bio!.isNotEmpty) filled++;
    total++;

    if (profile.photoUrl != null) filled++;
    total++;

    return total > 0 ? filled / total : 0.0;
  }

  Future<Athlete> addAchievement(String athleteId, Achievement achievement) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _athletes.indexWhere((a) => a.id == athleteId);
    if (index < 0) throw ProfileException('Profile not found.');
    final athlete = _athletes[index];
    final updatedAchievements = [...athlete.achievements, achievement];
    final updatedAthlete = Athlete(
      id: athlete.id,
      userId: athlete.userId,
      displayName: athlete.displayName,
      photoUrl: athlete.photoUrl,
      sports: athlete.sports,
      positions: athlete.positions,
      age: athlete.age,
      height: athlete.height,
      weight: athlete.weight,
      dominantFootHand: athlete.dominantFootHand,
      currentTeam: athlete.currentTeam,
      country: athlete.country,
      city: athlete.city,
      bio: athlete.bio,
      availabilityStatus: athlete.availabilityStatus,
      achievements: updatedAchievements,
      content: athlete.content,
      profileBadgeLevel: athlete.profileBadgeLevel,
      profileCompleteness: athlete.profileCompleteness,
      createdAt: athlete.createdAt,
    );
    _athletes[index] = updatedAthlete;
    return updatedAthlete;
  }

  Future<Athlete> removeAchievement(String athleteId, String achievementId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _athletes.indexWhere((a) => a.id == athleteId);
    if (index < 0) throw ProfileException('Profile not found.');
    final athlete = _athletes[index];
    final updatedAchievements = athlete.achievements.where((a) => a.id != achievementId).toList();
    final updatedAthlete = Athlete(
      id: athlete.id,
      userId: athlete.userId,
      displayName: athlete.displayName,
      photoUrl: athlete.photoUrl,
      sports: athlete.sports,
      positions: athlete.positions,
      age: athlete.age,
      height: athlete.height,
      weight: athlete.weight,
      dominantFootHand: athlete.dominantFootHand,
      currentTeam: athlete.currentTeam,
      country: athlete.country,
      city: athlete.city,
      bio: athlete.bio,
      availabilityStatus: athlete.availabilityStatus,
      achievements: updatedAchievements,
      content: athlete.content,
      profileBadgeLevel: athlete.profileBadgeLevel,
      profileCompleteness: athlete.profileCompleteness,
      createdAt: athlete.createdAt,
    );
    _athletes[index] = updatedAthlete;
    return updatedAthlete;
  }

  List<Athlete> searchAthletes({
    String? sport,
    String? position,
    int? minAge,
    int? maxAge,
    String? location,
    AvailabilityStatus? availability,
    TrustBadgeLevel? minBadge,
  }) {
    return MockData.searchAthletes(
      sport: sport,
      position: position,
      maxAge: maxAge,
      minAge: minAge,
      location: location,
      availability: availability,
      minBadge: minBadge,
    );
  }
}

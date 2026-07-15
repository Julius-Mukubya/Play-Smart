import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/profiles/repositories/mock_profile_repository.dart';
import 'package:play_smart/profiles/repositories/profile_repository.dart' show ProfileException;
import 'package:play_smart/shared/types/domain_types.dart';

// Exercises profile business rules (completeness calc, search filters, CRUD)
// against the in-memory mock — the real `ProfileRepository` talks to Supabase.
// See lib/supabase-integration.md for how to verify it against a live project.
void main() {
  group('ProfileRepository', () {
    late MockProfileRepository repository;

    setUp(() {
      repository = MockProfileRepository();
    });

    test('getAllAthletes returns all athletes', () {
      final athletes = repository.getAllAthletes();
      expect(athletes.isNotEmpty, true);
    });

    test('getAthleteById returns correct athlete', () {
      final athlete = repository.getAthleteById('athlete-1-profile');
      expect(athlete, isNotNull);
      expect(athlete!.displayName, 'John Muwonge');
    });

    test('getAthleteById returns null for unknown id', () {
      final athlete = repository.getAthleteById('unknown-id');
      expect(athlete, isNull);
    });

    test('getAthleteByUserId returns correct athlete', () {
      final athlete = repository.getAthleteByUserId('athlete-1');
      expect(athlete, isNotNull);
      expect(athlete!.displayName, 'John Muwonge');
    });

    test('calculateCompleteness returns 0.0 for empty profile', () {
      final empty = Athlete(
        id: 'test',
        userId: 'test-user',
        displayName: '',
      );
      expect(repository.calculateCompleteness(empty), 0.0);
    });

    test('calculateCompleteness returns 1.0 for fully populated profile', () {
      final full = Athlete(
        id: 'test',
        userId: 'test-user',
        displayName: 'Test Athlete',
        photoUrl: 'photo.jpg',
        sports: ['Football'],
        positions: ['Striker'],
        age: 20,
        height: 180,
        weight: 75,
        dominantFootHand: 'Right',
        currentTeam: 'Test Team',
        country: 'Uganda',
        bio: 'Test bio',
      );
      expect(repository.calculateCompleteness(full), 1.0);
    });

    test('createProfile adds a new athlete', () async {
      final newAthlete = Athlete(
        id: 'new-athlete',
        userId: 'new-user',
        displayName: 'New Athlete',
        sports: ['Basketball'],
        positions: ['Guard'],
      );

      final result = await repository.createProfile(newAthlete);
      expect(result.id, 'new-athlete');

      // Verify it was added
      final found = repository.getAthleteById('new-athlete');
      expect(found, isNotNull);
    });

    test('updateProfile updates existing athlete', () async {
      final existing = repository.getAthleteById('athlete-1-profile')!;
      final updated = Athlete(
        id: existing.id,
        userId: existing.userId,
        displayName: 'Updated Name',
        sports: existing.sports,
        positions: existing.positions,
        age: existing.age,
        height: existing.height,
        weight: existing.weight,
        dominantFootHand: existing.dominantFootHand,
        currentTeam: existing.currentTeam,
        country: existing.country,
        city: existing.city,
        bio: existing.bio,
        availabilityStatus: existing.availabilityStatus,
        achievements: existing.achievements,
        content: existing.content,
        profileBadgeLevel: existing.profileBadgeLevel,
      );

      final result = await repository.updateProfile(updated);
      expect(result.displayName, 'Updated Name');

      // Verify persistence
      final refetched = repository.getAthleteById('athlete-1-profile');
      expect(refetched!.displayName, 'Updated Name');
    });

    test('updateProfile throws for unknown athlete', () async {
      final unknown = Athlete(
        id: 'unknown',
        userId: 'unknown-user',
        displayName: 'Unknown',
      );

      expect(
        () async => await repository.updateProfile(unknown),
        throwsA(isA<ProfileException>()),
      );
    });

    test('searchAthletes filters by sport', () {
      final results = repository.searchAthletes(sport: 'Football');
      expect(results.length, 2); // John + David
      expect(results.every((a) => a.sports.any((s) => s.contains('Football'))), true);
    });

    test('searchAthletes filters by location', () {
      final results = repository.searchAthletes(location: 'Kampala');
      expect(results.length, 1);
      expect(results.first.displayName, 'John Muwonge');
    });

    test('searchAthletes returns all when no filters', () {
      final results = repository.searchAthletes();
      expect(results.length, 3);
    });

    test('searchAthletes filters by availability', () {
      final results = repository.searchAthletes(
        availability: AvailabilityStatus.openToTrials,
      );
      expect(results.length, 3); // All are open to trials in mock data
    });

    test('searchAthletes filters by badge level', () {
      final results = repository.searchAthletes(
        minBadge: TrustBadgeLevel.coachEndorsed,
      );
      // John (coachEndorsed) and Sarah (clubVerified)
      expect(results.length, 2);
    });

    test('addAchievement adds achievement to athlete', () async {
      final achievement = Achievement(
        id: 'test-ach',
        title: 'Test Achievement',
        description: 'Test description',
        badgeLevel: TrustBadgeLevel.selfReported,
      );

      final updated = await repository.addAchievement('athlete-1-profile', achievement);
      expect(updated.achievements.any((a) => a.id == 'test-ach'), true);
      expect(updated.achievements.length, 3); // 2 original + 1 new
    });

    test('addAchievement throws for unknown athlete', () async {
      final achievement = Achievement(
        id: 'test-ach',
        title: 'Test Achievement',
        badgeLevel: TrustBadgeLevel.selfReported,
      );

      expect(
        () async => await repository.addAchievement('unknown', achievement),
        throwsA(isA<ProfileException>()),
      );
    });

    test('removeAchievement removes achievement from athlete', () async {
      final updated = await repository.removeAchievement('athlete-1-profile', 'ach-1');
      expect(updated.achievements.any((a) => a.id == 'ach-1'), false);
      expect(updated.achievements.length, 1); // Only ach-2 remains
    });

    test('removeAchievement throws for unknown athlete', () async {
      expect(
        () async => await repository.removeAchievement('unknown', 'ach-1'),
        throwsA(isA<ProfileException>()),
      );
    });

    test('removeAchievement does nothing for non-existent achievement', () async {
      final updated = await repository.removeAchievement('athlete-1-profile', 'non-existent');
      expect(updated.achievements.length, 2); // Unchanged
    });
  });
}

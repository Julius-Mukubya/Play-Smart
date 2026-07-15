import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/discovery/repositories/mock_discovery_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

// Exercises search/filter/feed logic against the in-memory mock — the real
// `DiscoveryRepository` queries Supabase. See lib/supabase-integration.md.
void main() {
  group('DiscoveryRepository', () {
    late MockDiscoveryRepository repository;

    setUp(() {
      repository = MockDiscoveryRepository();
    });

    test('getDiscoverFeed returns all athletes', () {
      final feed = repository.getDiscoverFeed();
      expect(feed.length, 3);
    });

    test('searchAthletes filters by text query', () {
      final results = repository.searchAthletes(query: 'John');
      expect(results.length, 1);
      expect(results.first.displayName, 'John Muwonge');
    });

    test('searchAthletes filters by sport', () {
      final results = repository.searchAthletes(sport: 'Netball');
      expect(results.length, 1);
      expect(results.first.displayName, 'Sarah Nakato');
    });

    test('searchAthletes filters by position', () {
      final results = repository.searchAthletes(position: 'Goalkeeper');
      expect(results.length, 1);
      expect(results.first.displayName, 'David Okello');
    });

    test('searchAthletes filters by age range', () {
      final results = repository.searchAthletes(minAge: 20, maxAge: 25);
      expect(results.length, 2); // John (24) and Sarah (22)
    });

    test('searchAthletes filters by location', () {
      final results = repository.searchAthletes(location: 'Jinja');
      expect(results.length, 1);
      expect(results.first.displayName, 'Sarah Nakato');
    });

    test('searchAthletes filters by availability', () {
      final results = repository.searchAthletes(
        availability: AvailabilityStatus.openToTrials,
      );
      expect(results.length, 3);
    });

    test('searchAthletes filters by badge level', () {
      final results = repository.searchAthletes(
        minBadge: TrustBadgeLevel.coachEndorsed,
      );
      expect(results.length, 2); // John (coachEndorsed) + Sarah (clubVerified)
    });

    test('searchAthletes combines multiple filters', () {
      final results = repository.searchAthletes(
        sport: 'Football',
        position: 'Striker',
        minAge: 18,
        maxAge: 30,
      );
      expect(results.length, 1);
      expect(results.first.displayName, 'John Muwonge');
    });

    test('searchAthletes returns empty for no match', () {
      final results = repository.searchAthletes(sport: 'Rugby');
      expect(results, isEmpty);
    });

    test('searchAthletes returns all when no filters', () {
      final results = repository.searchAthletes();
      expect(results.length, 3);
    });

    test('getRecommendedFeed filters by preferred sports', () {
      final results = repository.getRecommendedFeed(
        preferredSports: ['Football'],
      );
      expect(results.length, 2); // John and David
      expect(results.every((a) => a.sports.any((s) => s.contains('Football'))), true);
    });

    test('getRecommendedFeed returns all when no preferences', () {
      final results = repository.getRecommendedFeed();
      expect(results.length, 3);
    });

    test('getRecommendedFeed filters by preferred positions', () {
      final results = repository.getRecommendedFeed(
        preferredPositions: ['Striker'],
      );
      expect(results.length, 1);
      expect(results.first.displayName, 'John Muwonge');
    });
  });
}
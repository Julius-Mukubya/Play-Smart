import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/shortlisting/repositories/shortlist_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

void main() {
  group('ShortlistRepository', () {
    late ShortlistRepository repository;

    setUp(() {
      repository = ShortlistRepository();
    });

    test('getShortlistsByOwner returns lists for owner', () {
      final lists = repository.getShortlistsByOwner('recruiter-1');
      expect(lists.length, 2);
      expect(lists.every((s) => s.ownerId == 'recruiter-1'), true);
    });

    test('getShortlistsByOwner returns empty for unknown owner', () {
      final lists = repository.getShortlistsByOwner('unknown');
      expect(lists, isEmpty);
    });

    test('getShortlistById returns correct shortlist', () {
      final list = repository.getShortlistById('shortlist-1');
      expect(list, isNotNull);
      expect(list!.name, 'Strikers Watchlist');
    });

    test('getShortlistById returns null for unknown id', () {
      final list = repository.getShortlistById('unknown');
      expect(list, isNull);
    });

    test('createShortlist adds a new shortlist', () async {
      final created = await repository.createShortlist('recruiter-1', 'New List');
      expect(created.name, 'New List');
      expect(created.ownerId, 'recruiter-1');
      expect(created.athleteIds, isEmpty);

      final lists = repository.getShortlistsByOwner('recruiter-1');
      expect(lists.any((s) => s.id == created.id), true);
    });

    test('renameShortlist updates name', () async {
      final updated = await repository.renameShortlist('shortlist-1', 'Updated Name');
      expect(updated.name, 'Updated Name');
      expect(updated.id, 'shortlist-1');
    });

    test('renameShortlist throws for unknown', () async {
      expect(
        () => repository.renameShortlist('unknown', 'New Name'),
        throwsA(isA<ShortlistException>()),
      );
    });

    test('deleteShortlist removes a shortlist', () async {
      expect(repository.getShortlistById('shortlist-2'), isNotNull);
      await repository.deleteShortlist('shortlist-2');
      expect(repository.getShortlistById('shortlist-2'), isNull);
    });

    test('addAthlete adds athlete to shortlist', () async {
      final updated = await repository.addAthlete('shortlist-1', 'athlete-3');
      expect(updated.athleteIds.contains('athlete-3'), true);
      expect(updated.athleteIds.length, 3); // 2 original + 1 new
    });

    test('addAthlete does not duplicate athlete', () async {
      final updated = await repository.addAthlete('shortlist-1', 'athlete-1');
      expect(updated.athleteIds.where((id) => id == 'athlete-1').length, 1);
    });

    test('addAthlete throws for unknown shortlist', () async {
      expect(
        () => repository.addAthlete('unknown', 'athlete-1'),
        throwsA(isA<ShortlistException>()),
      );
    });

    test('removeAthlete removes athlete from shortlist', () async {
      final updated = await repository.removeAthlete('shortlist-1', 'athlete-1');
      expect(updated.athleteIds.contains('athlete-1'), false);
      expect(updated.athleteIds.length, 1); // Only athlete-2 remains
    });

    test('removeAthlete throws for unknown shortlist', () async {
      expect(
        () => repository.removeAthlete('unknown', 'athlete-1'),
        throwsA(isA<ShortlistException>()),
      );
    });

    test('setPrivateNote adds a note to an athlete', () async {
      final updated = await repository.setPrivateNote('shortlist-1', 'athlete-3', 'Great potential');
      expect(updated.privateNotes['athlete-3'], 'Great potential');
    });

    test('setPrivateNote with empty string removes note', () async {
      // First add a note
      await repository.setPrivateNote('shortlist-1', 'athlete-1', 'Some note');
      expect(repository.getShortlistById('shortlist-1')!.privateNotes['athlete-1'], 'Some note');

      // Now clear it
      await repository.setPrivateNote('shortlist-1', 'athlete-1', '');
      expect(repository.getShortlistById('shortlist-1')!.privateNotes.containsKey('athlete-1'), false);
    });

    test('getShortlistCount returns correct count', () {
      expect(repository.getShortlistCount('recruiter-1'), 2);
      expect(repository.getShortlistCount('unknown'), 0);
    });

    test('getTotalShortlistedAthletes returns correct total', () {
      // shortlist-1 has 2 athletes, shortlist-2 has 1 athlete
      expect(repository.getTotalShortlistedAthletes('recruiter-1'), 3);
    });
  });
}
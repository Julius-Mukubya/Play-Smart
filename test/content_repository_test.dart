import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/profiles/repositories/content_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

void main() {
  group('ContentRepository', () {
    late ContentRepository repository;

    setUp(() {
      repository = ContentRepository();
    });

    test('getContentByAthleteId returns content for existing athlete', () {
      final content = repository.getContentByAthleteId('athlete-1');
      expect(content.length, greaterThan(0));
      expect(content.every((c) => c.athleteId == 'athlete-1'), true);
    });

    test('getContentByAthleteId returns empty list for athlete with no content', () {
      final content = repository.getContentByAthleteId('athlete-3');
      expect(content, isEmpty);
    });

    test('getContentByAthleteId returns empty list for unknown athlete', () {
      final content = repository.getContentByAthleteId('unknown');
      expect(content, isEmpty);
    });

    test('createContent adds a new content entry', () async {
      final content = AthleteContent(
        id: 'new-content',
        athleteId: 'athlete-1',
        type: ContentType.video,
        title: 'New Test Video',
      );

      final created = await repository.createContent(content);
      expect(created.id, 'new-content');
      expect(created.title, 'New Test Video');

      // Verify it was added
      final allContent = repository.getContentByAthleteId('athlete-1');
      expect(allContent.any((c) => c.id == 'new-content'), true);
    });

    test('deleteContent removes a content entry', () async {
      final content = AthleteContent(
        id: 'delete-me',
        athleteId: 'athlete-2',
        type: ContentType.photo,
        title: 'To Delete',
      );

      await repository.createContent(content);
      expect(repository.getContentByAthleteId('athlete-2').any((c) => c.id == 'delete-me'), true);

      await repository.deleteContent('delete-me');
      expect(repository.getContentByAthleteId('athlete-2').any((c) => c.id == 'delete-me'), false);
    });

    test('updateContent updates an existing content entry', () async {
      final content = AthleteContent(
        id: 'update-me',
        athleteId: 'athlete-1',
        type: ContentType.post,
        title: 'Original Title',
      );

      await repository.createContent(content);

      final updated = AthleteContent(
        id: 'update-me',
        athleteId: 'athlete-1',
        type: ContentType.post,
        title: 'Updated Title',
        description: 'Updated description',
      );

      final result = await repository.updateContent(updated);
      expect(result.title, 'Updated Title');
      expect(result.description, 'Updated description');
    });

    test('updateContent throws for unknown content', () async {
      final content = AthleteContent(
        id: 'unknown',
        athleteId: 'athlete-1',
        type: ContentType.post,
        title: 'Unknown',
      );

      expect(
        () => repository.updateContent(content),
        throwsA(isA<ContentException>()),
      );
    });
  });
}
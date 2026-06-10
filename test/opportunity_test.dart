import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/opportunities/repositories/opportunity_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

void main() {
  group('OpportunityRepository', () {
    late OpportunityRepository repository;

    setUp(() {
      repository = OpportunityRepository();
    });

    test('getOpenOpportunities returns only open', () {
      final open = repository.getOpenOpportunities();
      expect(open.every((o) => !o.isClosed), true);
    });

    test('getAllOpportunities returns all', () {
      expect(repository.getAllOpportunities().length, 2);
    });

    test('getOpportunitiesByCreator returns correct', () {
      final list = repository.getOpportunitiesByCreator('club-1');
      expect(list.length, 1);
      expect(list.first.title, 'Open Trials - Express FC');
    });

    test('createOpportunity adds new', () async {
      final opp = Opportunity(
        id: 'opp-new', creatorId: 'recruiter-1', creatorRole: AccountRole.recruiter,
        title: 'New Trial', sport: 'Football', capacity: 10,
      );
      final created = await repository.createOpportunity(opp);
      expect(created.id, 'opp-new');
      expect(repository.getOpportunityById('opp-new'), isNotNull);
    });

    test('closeOpportunity closes an opportunity', () async {
      final closed = await repository.closeOpportunity('opp-1');
      expect(closed.isClosed, true);
    });

    test('apply adds application and increments count', () async {
      final app = await repository.apply('opp-1', 'athlete-3', 'David Okello');
      expect(app.opportunityId, 'opp-1');
      expect(app.athleteId, 'athlete-3');
      final opp = repository.getOpportunityById('opp-1')!;
      expect(opp.applicationCount, 13);
    });

    test('apply throws for closed opportunity', () async {
      await repository.closeOpportunity('opp-2');
      expect(
        () => repository.apply('opp-2', 'athlete-1', 'John'),
        throwsA(isA<OpportunityException>()),
      );
    });

    test('apply throws for duplicate application', () async {
      expect(
        () => repository.apply('opp-1', 'athlete-1', 'John'),
        throwsA(isA<OpportunityException>()),
      );
    });

    test('apply throws for capacity reached', () async {
      // opp-2 has capacity 20 and 20 applications, so it's closed
      expect(
        () => repository.apply('opp-2', 'athlete-3', 'David'),
        throwsA(isA<OpportunityException>()),
      );
    });

    test('getApplicationsForOpportunity returns correct', () {
      final apps = repository.getApplicationsForOpportunity('opp-1');
      expect(apps.length, 2);
    });

    test('acceptApplication marks as accepted', () async {
      final accepted = await repository.acceptApplication('app-1');
      expect(accepted.accepted, true);
    });

    test('filterOpportunities filters by sport', () {
      final results = repository.filterOpportunities(sport: 'Football');
      expect(results.every((o) => o.sport.contains('Football')), true);
    });

    test('filterOpportunities filters by location', () {
      final results = repository.filterOpportunities(location: 'Kampala');
      expect(results.length, 1);
    });
  });
}
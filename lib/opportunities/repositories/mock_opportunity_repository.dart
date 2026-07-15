import 'package:play_smart/opportunities/repositories/opportunity_repository.dart' show OpportunityException;
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

/// In-memory opportunity repository used by unit tests. Not wired into the
/// app — see `OpportunityRepository` (Supabase-backed) for the production
/// implementation, which enforces capacity/auto-close atomically via the
/// `apply_to_opportunity` RPC instead of client-side read-modify-write.
class MockOpportunityRepository {
  final List<Opportunity> _opportunities = List.from(MockData.opportunities);
  final List<Application> _applications = List.from(MockData.applications);

  List<Opportunity> getOpenOpportunities() {
    return _opportunities.where((o) => !o.isClosed).toList();
  }

  List<Opportunity> getAllOpportunities() {
    return List.unmodifiable(_opportunities);
  }

  List<Opportunity> getOpportunitiesByCreator(String creatorId) {
    return _opportunities.where((o) => o.creatorId == creatorId).toList();
  }

  Opportunity? getOpportunityById(String id) {
    try {
      return _opportunities.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Opportunity> createOpportunity(Opportunity opportunity) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _opportunities.add(opportunity);
    return opportunity;
  }

  Future<Opportunity> closeOpportunity(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _opportunities.indexWhere((o) => o.id == id);
    if (index < 0) throw OpportunityException('Opportunity not found.');
    final opp = _opportunities[index];
    final updated = Opportunity(
      id: opp.id,
      creatorId: opp.creatorId,
      creatorRole: opp.creatorRole,
      title: opp.title,
      sport: opp.sport,
      position: opp.position,
      location: opp.location,
      date: opp.date,
      minAge: opp.minAge,
      maxAge: opp.maxAge,
      description: opp.description,
      capacity: opp.capacity,
      applicationCount: opp.applicationCount,
      isClosed: true,
      createdAt: opp.createdAt,
    );
    _opportunities[index] = updated;
    return updated;
  }

  List<Application> getApplicationsForOpportunity(String opportunityId) {
    return _applications.where((a) => a.opportunityId == opportunityId).toList();
  }

  List<Application> getApplicationsByAthlete(String athleteId) {
    return _applications.where((a) => a.athleteId == athleteId).toList();
  }

  Future<Application> apply(
      String opportunityId, String athleteId, String athleteName,
      {String message = ''}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final oppIndex = _opportunities.indexWhere((o) => o.id == opportunityId);
    if (oppIndex < 0) throw OpportunityException('Opportunity not found.');
    final opp = _opportunities[oppIndex];

    if (opp.isClosed) throw OpportunityException('This opportunity is closed.');
    if (opp.applicationCount >= opp.capacity) {
      throw OpportunityException('This opportunity has reached its capacity.');
    }

    if (_applications.any((a) =>
        a.opportunityId == opportunityId && a.athleteId == athleteId)) {
      throw OpportunityException('You have already applied to this opportunity.');
    }

    final now = DateTime.now();
    final application = Application(
      id: 'app-${now.millisecondsSinceEpoch}',
      opportunityId: opportunityId,
      athleteId: athleteId,
      athleteName: athleteName,
      message: message,
    );

    _applications.add(application);

    final newCount = opp.applicationCount + 1;
    final autoClose = newCount >= opp.capacity;
    final updatedOpp = Opportunity(
      id: opp.id,
      creatorId: opp.creatorId,
      creatorRole: opp.creatorRole,
      title: opp.title,
      sport: opp.sport,
      position: opp.position,
      location: opp.location,
      date: opp.date,
      minAge: opp.minAge,
      maxAge: opp.maxAge,
      description: opp.description,
      capacity: opp.capacity,
      applicationCount: newCount,
      isClosed: autoClose,
      createdAt: opp.createdAt,
    );
    _opportunities[oppIndex] = updatedOpp;

    return application;
  }

  Future<Application> acceptApplication(String applicationId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _applications.indexWhere((a) => a.id == applicationId);
    if (index < 0) throw OpportunityException('Application not found.');
    final app = _applications[index];
    final updated = Application(
      id: app.id,
      opportunityId: app.opportunityId,
      athleteId: app.athleteId,
      athleteName: app.athleteName,
      message: app.message,
      status: 'accepted',
      createdAt: app.createdAt,
    );
    _applications[index] = updated;
    return updated;
  }

  List<Opportunity> filterOpportunities({
    String? sport,
    String? location,
    String? position,
  }) {
    var results = getOpenOpportunities();
    if (sport != null && sport.isNotEmpty) {
      results = results.where((o) =>
          o.sport.toLowerCase().contains(sport.toLowerCase())).toList();
    }
    if (location != null && location.isNotEmpty) {
      results = results.where((o) =>
          (o.location?.toLowerCase().contains(location.toLowerCase()) ?? false))
          .toList();
    }
    if (position != null && position.isNotEmpty) {
      results = results.where((o) =>
          (o.position?.toLowerCase().contains(position.toLowerCase()) ?? false))
          .toList();
    }
    return results;
  }
}

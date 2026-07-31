import 'package:play_smart/shared/types/domain_types.dart';

/// Mock/In-memory Opportunity repository — ready to be wired up with Firebase Firestore.
class OpportunityRepository {
  final List<Opportunity> _opportunities = [];
  final List<Application> _applications = [];

  Future<List<Opportunity>> getOpenOpportunities() async {
    return _opportunities.where((o) => !o.isClosed).toList();
  }

  Future<List<Opportunity>> getAllOpportunities() async {
    return _opportunities;
  }

  Future<List<Opportunity>> getOpportunitiesByCreator(String creatorId) async {
    return _opportunities.where((o) => o.creatorId == creatorId).toList();
  }

  Future<Opportunity?> getOpportunityById(String id) async {
    final list = _opportunities.where((o) => o.id == id).toList();
    return list.isNotEmpty ? list.first : null;
  }

  Future<Opportunity> createOpportunity(Opportunity opportunity) async {
    _opportunities.add(opportunity);
    return opportunity;
  }

  Future<Opportunity> closeOpportunity(String id) async {
    final idx = _opportunities.indexWhere((o) => o.id == id);
    if (idx != -1) {
      final updated = _opportunities[idx].copyWith(isClosed: true);
      _opportunities[idx] = updated;
      return updated;
    }
    throw OpportunityException('Opportunity not found.');
  }

  Future<List<Application>> getApplicationsForOpportunity(String opportunityId) async {
    return _applications.where((a) => a.opportunityId == opportunityId).toList();
  }

  Future<List<Application>> getApplicationsByAthlete(String athleteId) async {
    return _applications.where((a) => a.athleteId == athleteId).toList();
  }

  Future<Application> apply(
      String opportunityId, String athleteId, String athleteName,
      {String message = ''}) async {
    final app = Application(
      id: 'app_${DateTime.now().millisecondsSinceEpoch}',
      opportunityId: opportunityId,
      athleteId: athleteId,
      athleteName: athleteName,
      status: 'pending',
      message: message,
      createdAt: DateTime.now(),
    );
    _applications.add(app);
    return app;
  }

  Future<Application> acceptApplication(String applicationId) async {
    final idx = _applications.indexWhere((a) => a.id == applicationId);
    if (idx != -1) {
      final updated = _applications[idx].copyWith(status: 'accepted');
      _applications[idx] = updated;
      return updated;
    }
    throw OpportunityException('Application not found.');
  }

  Future<List<Opportunity>> filterOpportunities({
    String? sport,
    String? location,
    String? position,
  }) async {
    return _opportunities.where((o) => !o.isClosed).toList();
  }
}

class OpportunityException implements Exception {
  final String message;
  OpportunityException(this.message);

  @override
  String toString() => message;
}

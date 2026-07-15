import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Opportunity repository — Supabase-backed CRUD for `public.opportunities`
/// and `public.applications`.
///
/// [apply] calls the `apply_to_opportunity` RPC rather than inserting
/// directly: capacity check + insert + `application_count` increment +
/// auto-close all happen atomically in one Postgres function, which a plain
/// client-side read-modify-write cannot guarantee under concurrent applicants
/// (see `context/supabase-backend.md` section 8 and
/// `lib/supabase-integration.md` section 4).
class OpportunityRepository {
  static const _table = 'opportunities';
  static const _applicationsTable = 'applications';

  Future<List<Opportunity>> getOpenOpportunities() async {
    final rows = await supabase.from(_table).select().eq('is_closed', false);
    return (rows as List).map((r) => Opportunity.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<Opportunity>> getAllOpportunities() async {
    final rows = await supabase.from(_table).select();
    return (rows as List).map((r) => Opportunity.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<Opportunity>> getOpportunitiesByCreator(String creatorId) async {
    final rows = await supabase.from(_table).select().eq('creator_id', creatorId);
    return (rows as List).map((r) => Opportunity.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Opportunity?> getOpportunityById(String id) async {
    final row = await supabase.from(_table).select().eq('id', id).maybeSingle();
    return row != null ? Opportunity.fromJson(row) : null;
  }

  /// Create a new opportunity. Requires the creator's `verification_status`
  /// to be `approved` — enforced by RLS, not just client-side.
  Future<Opportunity> createOpportunity(Opportunity opportunity) async {
    try {
      final row = await supabase.from(_table).insert({
        'creator_id': opportunity.creatorId,
        'creator_role': opportunity.creatorRole.name,
        'title': opportunity.title,
        'sport': opportunity.sport,
        'position': opportunity.position,
        'location': opportunity.location,
        'event_date': opportunity.date?.toIso8601String(),
        'min_age': opportunity.minAge,
        'max_age': opportunity.maxAge,
        'description': opportunity.description,
        'capacity': opportunity.capacity,
      }).select().single();
      return Opportunity.fromJson(row);
    } catch (e) {
      throw OpportunityException(
          'Could not create opportunity. Your account may not be verified yet.');
    }
  }

  Future<Opportunity> closeOpportunity(String id) async {
    try {
      final row = await supabase
          .from(_table)
          .update({'is_closed': true})
          .eq('id', id)
          .select()
          .single();
      return Opportunity.fromJson(row);
    } catch (e) {
      throw OpportunityException('Opportunity not found.');
    }
  }

  Future<List<Application>> getApplicationsForOpportunity(String opportunityId) async {
    final rows =
        await supabase.from(_applicationsTable).select().eq('opportunity_id', opportunityId);
    return (rows as List).map((r) => Application.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<List<Application>> getApplicationsByAthlete(String athleteId) async {
    final rows = await supabase.from(_applicationsTable).select().eq('athlete_id', athleteId);
    return (rows as List).map((r) => Application.fromJson(r as Map<String, dynamic>)).toList();
  }

  /// Apply to an opportunity via the `apply_to_opportunity` RPC — see class
  /// doc comment for why this isn't a plain insert.
  Future<Application> apply(
      String opportunityId, String athleteId, String athleteName,
      {String message = ''}) async {
    try {
      final row = await supabase.rpc('apply_to_opportunity', params: {
        'p_opportunity_id': opportunityId,
        'p_message': message,
      });
      return Application.fromJson(row as Map<String, dynamic>);
    } catch (e) {
      throw OpportunityException(_friendlyMessage(e));
    }
  }

  Future<Application> acceptApplication(String applicationId) async {
    try {
      final row = await supabase
          .from(_applicationsTable)
          .update({'status': 'accepted'})
          .eq('id', applicationId)
          .select()
          .single();
      return Application.fromJson(row);
    } catch (e) {
      throw OpportunityException('Application not found.');
    }
  }

  Future<List<Opportunity>> filterOpportunities({
    String? sport,
    String? location,
    String? position,
  }) async {
    var query = supabase.from(_table).select().eq('is_closed', false);
    if (sport != null && sport.isNotEmpty) query = query.ilike('sport', '%$sport%');
    if (location != null && location.isNotEmpty) query = query.ilike('location', '%$location%');
    if (position != null && position.isNotEmpty) query = query.ilike('position', '%$position%');
    final rows = await query;
    return (rows as List).map((r) => Opportunity.fromJson(r as Map<String, dynamic>)).toList();
  }

  String _friendlyMessage(Object e) {
    final message = e.toString();
    if (message.contains('capacity')) return 'This opportunity has reached its capacity.';
    if (message.contains('closed')) return 'This opportunity is closed.';
    if (message.contains('duplicate') || message.contains('unique')) {
      return 'You have already applied to this opportunity.';
    }
    return 'Could not submit application. Please try again.';
  }
}

/// Exception thrown by opportunity operations.
class OpportunityException implements Exception {
  final String message;
  OpportunityException(this.message);

  @override
  String toString() => message;
}

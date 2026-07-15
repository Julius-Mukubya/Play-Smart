import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/opportunities/repositories/opportunity_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return OpportunityRepository();
});

class OpportunityState {
  final List<Opportunity> opportunities;
  final List<Opportunity> myPostings;
  final List<Application> applications;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const OpportunityState({
    this.opportunities = const [],
    this.myPostings = const [],
    this.applications = const [],
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  OpportunityState copyWith({
    List<Opportunity>? opportunities,
    List<Opportunity>? myPostings,
    List<Application>? applications,
    bool? isLoading,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return OpportunityState(
      opportunities: opportunities ?? this.opportunities,
      myPostings: myPostings ?? this.myPostings,
      applications: applications ?? this.applications,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class OpportunityNotifier extends Notifier<OpportunityState> {
  @override
  OpportunityState build() => OpportunityState();

  OpportunityRepository get _repo => ref.read(opportunityRepositoryProvider);
  String? get _uid {
    final a = ref.read(authProvider);
    return a is AuthAuthenticated ? a.user.id : null;
  }

  Future<void> loadOpenOpportunities() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getOpenOpportunities();
      state = state.copyWith(opportunities: list, isLoading: false);
    } catch (e, st) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMyPostings() async {
    final uid = _uid;
    if (uid == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getOpportunitiesByCreator(uid);
      state = state.copyWith(myPostings: list, isLoading: false);
    } catch (e, st) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> createOpportunity(Opportunity opp) async {
    try {
      await _repo.createOpportunity(opp);
      await loadMyPostings();
      state = state.copyWith(successMessage: 'Opportunity posted successfully!');
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return e.toString();
    }
  }

  Future<void> closeOpportunity(String id) async {
    try {
      await _repo.closeOpportunity(id);
      await loadMyPostings();
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadApplications(String opportunityId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _repo.getApplicationsForOpportunity(opportunityId);
      state = state.copyWith(applications: list, isLoading: false);
    } catch (e, st) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> apply(String opportunityId, String athleteName, {String message = ''}) async {
    final uid = _uid;
    if (uid == null) return 'Not authenticated.';
    try {
      await _repo.apply(opportunityId, uid, athleteName, message: message);
      await loadOpenOpportunities();
      state = state.copyWith(successMessage: 'Application submitted!');
      return null;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return e.toString();
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final opportunityProvider = NotifierProvider<OpportunityNotifier, OpportunityState>(
  OpportunityNotifier.new,
);
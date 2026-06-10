import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/shortlisting/repositories/shortlist_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/auth/models/auth_state.dart';

/// Shortlist repository provider.
final shortlistRepositoryProvider = Provider<ShortlistRepository>((ref) {
  return ShortlistRepository();
});

/// Shortlist state.
class ShortlistState {
  final List<Shortlist> shortlists;
  final Shortlist? selectedShortlist;
  final bool isLoading;
  final String? error;

  const ShortlistState({
    this.shortlists = const [],
    this.selectedShortlist,
    this.isLoading = false,
    this.error,
  });

  ShortlistState copyWith({
    List<Shortlist>? shortlists,
    Shortlist? selectedShortlist,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return ShortlistState(
      shortlists: shortlists ?? this.shortlists,
      selectedShortlist: selectedShortlist ?? this.selectedShortlist,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Shortlist notifier — manages shortlist CRUD and state.
class ShortlistNotifier extends Notifier<ShortlistState> {
  @override
  ShortlistState build() {
    return ShortlistState();
  }

  ShortlistRepository get _repository => ref.read(shortlistRepositoryProvider);

  String? get _currentUserId {
    final auth = ref.read(authProvider);
    if (auth is AuthAuthenticated) return auth.user.id;
    return null;
  }

  /// Load shortlists for the current user.
  Future<void> loadShortlists() async {
    final userId = _currentUserId;
    if (userId == null) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final lists = _repository.getShortlistsByOwner(userId);
      state = state.copyWith(shortlists: lists, isLoading: false);
    } catch (e, st) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Select a shortlist to view its athletes.
  void selectShortlist(Shortlist shortlist) {
    state = state.copyWith(selectedShortlist: shortlist);
  }

  /// Deselect the current shortlist.
  void deselectShortlist() {
    state = state.copyWith(selectedShortlist: null);
  }

  /// Create a new shortlist.
  Future<void> createShortlist(String name) async {
    final userId = _currentUserId;
    if (userId == null) return;
    try {
      final newList = await _repository.createShortlist(userId, name);
      final updated = [...state.shortlists, newList];
      state = state.copyWith(shortlists: updated, selectedShortlist: newList);
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Rename a shortlist.
  Future<void> renameShortlist(String id, String newName) async {
    try {
      final updated = await _repository.renameShortlist(id, newName);
      state = state.copyWith(
        shortlists: state.shortlists.map((s) => s.id == id ? updated : s).toList(),
        selectedShortlist: state.selectedShortlist?.id == id ? updated : state.selectedShortlist,
      );
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Delete a shortlist.
  Future<void> deleteShortlist(String id) async {
    try {
      await _repository.deleteShortlist(id);
      state = state.copyWith(
        shortlists: state.shortlists.where((s) => s.id != id).toList(),
        selectedShortlist: state.selectedShortlist?.id == id ? null : state.selectedShortlist,
      );
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add athlete to a shortlist.
  Future<void> addAthlete(String shortlistId, String athleteId) async {
    try {
      final updated = await _repository.addAthlete(shortlistId, athleteId);
      _updateShortlistInState(updated);
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove athlete from a shortlist.
  Future<void> removeAthlete(String shortlistId, String athleteId) async {
    try {
      final updated = await _repository.removeAthlete(shortlistId, athleteId);
      _updateShortlistInState(updated);
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set a private note on an athlete in a shortlist.
  Future<void> setPrivateNote(String shortlistId, String athleteId, String note) async {
    try {
      final updated = await _repository.setPrivateNote(shortlistId, athleteId, note);
      _updateShortlistInState(updated);
    } catch (e, st) {
      state = state.copyWith(error: e.toString());
    }
  }

  void _updateShortlistInState(Shortlist updated) {
    state = state.copyWith(
      shortlists: state.shortlists.map((s) => s.id == updated.id ? updated : s).toList(),
      selectedShortlist: state.selectedShortlist?.id == updated.id ? updated : state.selectedShortlist,
    );
  }
}

/// Shortlist state provider.
final shortlistProvider = NotifierProvider<ShortlistNotifier, ShortlistState>(
  ShortlistNotifier.new,
);
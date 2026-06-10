import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

/// Shortlist repository — handles recruiter/club shortlist CRUD operations.
/// Uses mock data; swap with real API calls when backend is connected.
class ShortlistRepository {
  final List<Shortlist> _shortlists = List.from(MockData.shortlists);

  /// Get all shortlists for a given owner.
  List<Shortlist> getShortlistsByOwner(String ownerId) {
    return _shortlists.where((s) => s.ownerId == ownerId).toList();
  }

  /// Get a specific shortlist by ID.
  Shortlist? getShortlistById(String id) {
    try {
      return _shortlists.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create a new shortlist.
  Future<Shortlist> createShortlist(String ownerId, String name) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final newList = Shortlist(
      id: 'shortlist-${DateTime.now().millisecondsSinceEpoch}',
      ownerId: ownerId,
      name: name,
    );
    _shortlists.add(newList);
    return newList;
  }

  /// Rename a shortlist.
  Future<Shortlist> renameShortlist(String id, String newName) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _shortlists.indexWhere((s) => s.id == id);
    if (index < 0) throw ShortlistException('Shortlist not found.');
    final existing = _shortlists[index];
    final updated = Shortlist(
      id: existing.id,
      ownerId: existing.ownerId,
      name: newName,
      athleteIds: existing.athleteIds,
      privateNotes: existing.privateNotes,
      createdAt: existing.createdAt,
    );
    _shortlists[index] = updated;
    return updated;
  }

  /// Delete a shortlist.
  Future<void> deleteShortlist(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));
    _shortlists.removeWhere((s) => s.id == id);
  }

  /// Add an athlete to a shortlist.
  Future<Shortlist> addAthlete(String shortlistId, String athleteId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _shortlists.indexWhere((s) => s.id == shortlistId);
    if (index < 0) throw ShortlistException('Shortlist not found.');
    final list = _shortlists[index];
    if (list.athleteIds.contains(athleteId)) return list;
    final updated = Shortlist(
      id: list.id,
      ownerId: list.ownerId,
      name: list.name,
      athleteIds: [...list.athleteIds, athleteId],
      privateNotes: list.privateNotes,
      createdAt: list.createdAt,
    );
    _shortlists[index] = updated;
    return updated;
  }

  /// Remove an athlete from a shortlist.
  Future<Shortlist> removeAthlete(String shortlistId, String athleteId) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _shortlists.indexWhere((s) => s.id == shortlistId);
    if (index < 0) throw ShortlistException('Shortlist not found.');
    final list = _shortlists[index];
    final updated = Shortlist(
      id: list.id,
      ownerId: list.ownerId,
      name: list.name,
      athleteIds: list.athleteIds.where((id) => id != athleteId).toList(),
      privateNotes: {...list.privateNotes}..remove(athleteId),
      createdAt: list.createdAt,
    );
    _shortlists[index] = updated;
    return updated;
  }

  /// Set private note on an athlete in a shortlist.
  Future<Shortlist> setPrivateNote(
      String shortlistId, String athleteId, String note) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _shortlists.indexWhere((s) => s.id == shortlistId);
    if (index < 0) throw ShortlistException('Shortlist not found.');
    final list = _shortlists[index];
    final updatedNotes = Map<String, String>.from(list.privateNotes);
    if (note.isNotEmpty) {
      updatedNotes[athleteId] = note;
    } else {
      updatedNotes.remove(athleteId);
    }
    final updated = Shortlist(
      id: list.id,
      ownerId: list.ownerId,
      name: list.name,
      athleteIds: list.athleteIds,
      privateNotes: updatedNotes,
      createdAt: list.createdAt,
    );
    _shortlists[index] = updated;
    return updated;
  }

  /// Get the count of shortlists for an owner (for tier limit checks).
  int getShortlistCount(String ownerId) {
    return _shortlists.where((s) => s.ownerId == ownerId).length;
  }

  /// Get total athletes across all shortlists for an owner.
  int getTotalShortlistedAthletes(String ownerId) {
    return _shortlists
        .where((s) => s.ownerId == ownerId)
        .fold(0, (sum, s) => sum + s.athleteIds.length);
  }
}

/// Exception thrown by shortlist operations.
class ShortlistException implements Exception {
  final String message;
  ShortlistException(this.message);

  @override
  String toString() => message;
}
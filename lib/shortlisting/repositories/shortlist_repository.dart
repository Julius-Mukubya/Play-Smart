import 'package:play_smart/shared/types/domain_types.dart';

/// Mock/In-memory Shortlist repository — ready to be wired up with Firebase Firestore.
class ShortlistRepository {
  final List<Shortlist> _shortlists = [];

  Future<List<Shortlist>> getShortlistsByOwner(String ownerId) async {
    return _shortlists.where((s) => s.ownerId == ownerId).toList();
  }

  Future<Shortlist?> getShortlistById(String id) async {
    final list = _shortlists.where((s) => s.id == id).toList();
    return list.isNotEmpty ? list.first : null;
  }

  Future<Shortlist> createShortlist(String ownerId, String name) async {
    final s = Shortlist(
      id: 'shortlist_${DateTime.now().millisecondsSinceEpoch}',
      ownerId: ownerId,
      name: name,
      athleteIds: [],
      privateNotes: {},
      createdAt: DateTime.now(),
    );
    _shortlists.add(s);
    return s;
  }

  Future<Shortlist> renameShortlist(String id, String newName) async {
    final idx = _shortlists.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final updated = Shortlist(
        id: id,
        ownerId: _shortlists[idx].ownerId,
        name: newName,
        athleteIds: _shortlists[idx].athleteIds,
        privateNotes: _shortlists[idx].privateNotes,
        createdAt: _shortlists[idx].createdAt,
      );
      _shortlists[idx] = updated;
      return updated;
    }
    throw ShortlistException('Shortlist not found.');
  }

  Future<void> deleteShortlist(String id) async {
    _shortlists.removeWhere((s) => s.id == id);
  }

  Future<Shortlist> addAthlete(String shortlistId, String athleteId) async {
    final idx = _shortlists.indexWhere((s) => s.id == shortlistId);
    if (idx != -1) {
      final s = _shortlists[idx];
      if (!s.athleteIds.contains(athleteId)) {
        final updated = Shortlist(
          id: s.id,
          ownerId: s.ownerId,
          name: s.name,
          athleteIds: [...s.athleteIds, athleteId],
          privateNotes: s.privateNotes,
          createdAt: s.createdAt,
        );
        _shortlists[idx] = updated;
        return updated;
      }
      return s;
    }
    throw ShortlistException('Shortlist not found.');
  }

  Future<Shortlist> removeAthlete(String shortlistId, String athleteId) async {
    final idx = _shortlists.indexWhere((s) => s.id == shortlistId);
    if (idx != -1) {
      final s = _shortlists[idx];
      final updated = Shortlist(
        id: s.id,
        ownerId: s.ownerId,
        name: s.name,
        athleteIds: s.athleteIds.where((id) => id != athleteId).toList(),
        privateNotes: s.privateNotes,
        createdAt: s.createdAt,
      );
      _shortlists[idx] = updated;
      return updated;
    }
    throw ShortlistException('Shortlist not found.');
  }

  Future<Shortlist> setPrivateNote(String shortlistId, String athleteId, String note) async {
    final idx = _shortlists.indexWhere((s) => s.id == shortlistId);
    if (idx != -1) {
      final s = _shortlists[idx];
      final newNotes = Map<String, String>.from(s.privateNotes);
      newNotes[athleteId] = note;
      final updated = Shortlist(
        id: s.id,
        ownerId: s.ownerId,
        name: s.name,
        athleteIds: s.athleteIds,
        privateNotes: newNotes,
        createdAt: s.createdAt,
      );
      _shortlists[idx] = updated;
      return updated;
    }
    throw ShortlistException('Shortlist not found.');
  }

  Future<int> getShortlistCount(String ownerId) async {
    return _shortlists.where((s) => s.ownerId == ownerId).length;
  }

  Future<int> getTotalShortlistedAthletes(String ownerId) async {
    final lists = await getShortlistsByOwner(ownerId);
    return lists.fold<int>(0, (sum, s) => sum + s.athleteIds.length);
  }
}

class ShortlistException implements Exception {
  final String message;
  ShortlistException(this.message);

  @override
  String toString() => message;
}

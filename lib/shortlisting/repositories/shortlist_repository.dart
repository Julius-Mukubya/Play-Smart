import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Shortlist repository — Supabase-backed CRUD for `public.shortlists` +
/// `public.shortlist_athletes` (the normalized form of the Dart model's
/// `athleteIds`/`privateNotes` map). Private notes are owner-only by RLS —
/// an athlete can never read a recruiter's note about them.
class ShortlistRepository {
  static const _table = 'shortlists';
  static const _athletesTable = 'shortlist_athletes';
  static const _selectWithAthletes = '*, shortlist_athletes(athlete_id, private_note)';

  Future<List<Shortlist>> getShortlistsByOwner(String ownerId) async {
    final rows =
        await supabase.from(_table).select(_selectWithAthletes).eq('owner_id', ownerId);
    return (rows as List).map((r) => Shortlist.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Shortlist?> getShortlistById(String id) async {
    final row =
        await supabase.from(_table).select(_selectWithAthletes).eq('id', id).maybeSingle();
    return row != null ? Shortlist.fromJson(row) : null;
  }

  Future<Shortlist> createShortlist(String ownerId, String name) async {
    final row = await supabase
        .from(_table)
        .insert({'owner_id': ownerId, 'name': name})
        .select(_selectWithAthletes)
        .single();
    return Shortlist.fromJson(row);
  }

  Future<Shortlist> renameShortlist(String id, String newName) async {
    try {
      await supabase.from(_table).update({'name': newName}).eq('id', id);
      final updated = await getShortlistById(id);
      if (updated == null) throw ShortlistException('Shortlist not found.');
      return updated;
    } catch (e) {
      throw ShortlistException('Shortlist not found.');
    }
  }

  Future<void> deleteShortlist(String id) async {
    await supabase.from(_table).delete().eq('id', id);
  }

  Future<Shortlist> addAthlete(String shortlistId, String athleteId) async {
    // upsert so re-adding an already-shortlisted athlete is a no-op, matching
    // the mock's idempotent behavior.
    await supabase.from(_athletesTable).upsert(
      {'shortlist_id': shortlistId, 'athlete_id': athleteId},
      onConflict: 'shortlist_id,athlete_id',
      ignoreDuplicates: true,
    );
    final updated = await getShortlistById(shortlistId);
    if (updated == null) throw ShortlistException('Shortlist not found.');
    return updated;
  }

  Future<Shortlist> removeAthlete(String shortlistId, String athleteId) async {
    await supabase
        .from(_athletesTable)
        .delete()
        .eq('shortlist_id', shortlistId)
        .eq('athlete_id', athleteId);
    final updated = await getShortlistById(shortlistId);
    if (updated == null) throw ShortlistException('Shortlist not found.');
    return updated;
  }

  Future<Shortlist> setPrivateNote(String shortlistId, String athleteId, String note) async {
    await supabase.from(_athletesTable).upsert(
      {
        'shortlist_id': shortlistId,
        'athlete_id': athleteId,
        'private_note': note.isNotEmpty ? note : null,
      },
      onConflict: 'shortlist_id,athlete_id',
    );
    final updated = await getShortlistById(shortlistId);
    if (updated == null) throw ShortlistException('Shortlist not found.');
    return updated;
  }

  Future<int> getShortlistCount(String ownerId) async {
    final rows = await supabase.from(_table).select('id').eq('owner_id', ownerId);
    return (rows as List).length;
  }

  /// Total athletes across all of this owner's shortlists (duplicates across
  /// lists counted once per list, matching the mock's behavior).
  Future<int> getTotalShortlistedAthletes(String ownerId) async {
    final lists = await getShortlistsByOwner(ownerId);
    return lists.fold<int>(0, (sum, s) => sum + s.athleteIds.length);
  }
}

/// Exception thrown by shortlist operations.
class ShortlistException implements Exception {
  final String message;
  ShortlistException(this.message);

  @override
  String toString() => message;
}

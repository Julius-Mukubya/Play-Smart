import 'dart:typed_data';

import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show FileOptions;

/// Profile repository — Supabase-backed CRUD for `public.athletes`.
///
/// `profile_badge_level` and `profile_completeness` are never sent in
/// insert/update payloads — they're recomputed server-side by triggers on
/// every write (see `context/supabase-backend.md` section 8). `lat`/`lng` are
/// geocoded server-side and likewise read-only from the client.
class ProfileRepository {
  static const _table = 'athletes';
  static const _avatarBucket = 'avatars';
  // Embeds achievements + content in the same query so screens that show a
  // full profile don't need a second round trip.
  static const _selectWithRelations = '*, achievements(*), athlete_content(*)';

  /// Uploads a profile photo to `avatars/{userId}/{filename}` and returns
  /// the public URL to store in `athletes.photo_url`. See
  /// `supabase/migrations/0005_avatars_storage.sql` for the bucket/RLS setup
  /// this depends on (owner-write, path-scoped by auth.uid()).
  Future<String> uploadAvatar({
    required String userId,
    required String filename,
    required Uint8List bytes,
  }) async {
    final path = '$userId/$filename';
    await supabase.storage.from(_avatarBucket).uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );
    return supabase.storage.from(_avatarBucket).getPublicUrl(path);
  }

  Future<List<Athlete>> getAllAthletes() async {
    final rows = await supabase.from(_table).select(_selectWithRelations);
    return (rows as List).map((r) => Athlete.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<Athlete?> getAthleteById(String id) async {
    final row =
        await supabase.from(_table).select(_selectWithRelations).eq('id', id).maybeSingle();
    return row != null ? Athlete.fromJson(row) : null;
  }

  Future<Athlete?> getAthleteByUserId(String userId) async {
    final row = await supabase
        .from(_table)
        .select(_selectWithRelations)
        .eq('user_id', userId)
        .maybeSingle();
    return row != null ? Athlete.fromJson(row) : null;
  }

  /// Create a new athlete profile for the current user.
  Future<Athlete> createProfile(Athlete profile) async {
    try {
      final row = await supabase
          .from(_table)
          .insert(_writableFields(profile))
          .select(_selectWithRelations)
          .single();
      return Athlete.fromJson(row);
    } catch (e) {
      throw ProfileException('Could not create profile: ${e.toString()}');
    }
  }

  /// Update an existing athlete profile.
  Future<Athlete> updateProfile(Athlete updated) async {
    try {
      final row = await supabase
          .from(_table)
          .update(_writableFields(updated))
          .eq('id', updated.id)
          .select(_selectWithRelations)
          .single();
      return Athlete.fromJson(row);
    } catch (e) {
      throw ProfileException('Profile not found.');
    }
  }

  /// Client-side estimate of profile completeness, useful for live form
  /// feedback before saving. The authoritative value is recalculated
  /// server-side on every write — always prefer `Athlete.profileCompleteness`
  /// from a freshly-loaded profile over this for display after save.
  double calculateCompleteness(Athlete profile) {
    int filled = 0;
    int total = 0;

    if (profile.displayName.isNotEmpty) filled++;
    total++;
    if (profile.sports.isNotEmpty) filled++;
    total++;
    if (profile.positions.isNotEmpty) filled++;
    total++;
    if (profile.age != null) filled++;
    total++;
    if (profile.height != null) filled++;
    total++;
    if (profile.weight != null) filled++;
    total++;
    if (profile.dominantFootHand != null && profile.dominantFootHand!.isNotEmpty) filled++;
    total++;
    if (profile.currentTeam != null && profile.currentTeam!.isNotEmpty) filled++;
    total++;
    if (profile.country != null && profile.country!.isNotEmpty) filled++;
    total++;
    if (profile.bio != null && profile.bio!.isNotEmpty) filled++;
    total++;
    if (profile.photoUrl != null) filled++;
    total++;

    return total > 0 ? filled / total : 0.0;
  }

  /// Add an achievement. `badge_level` is never sent — it always starts at
  /// `self_reported` server-side (invariant: badges are never self-assigned).
  Future<Athlete> addAchievement(String athleteId, Achievement achievement) async {
    await supabase.from('achievements').insert({
      'athlete_id': athleteId,
      'title': achievement.title,
      'description': achievement.description,
    });
    final athlete = await getAthleteById(athleteId);
    if (athlete == null) throw ProfileException('Profile not found.');
    return athlete;
  }

  Future<Athlete> removeAchievement(String athleteId, String achievementId) async {
    await supabase.from('achievements').delete().eq('id', achievementId);
    final athlete = await getAthleteById(athleteId);
    if (athlete == null) throw ProfileException('Profile not found.');
    return athlete;
  }

  /// Filter athletes by search criteria. `sport`/`position` match against the
  /// exact values used in the athlete setup form (array containment) —
  /// free-text fuzzy search across sport/position isn't supported server-side,
  /// only on `displayName` in `DiscoveryRepository.searchAthletes`.
  Future<List<Athlete>> searchAthletes({
    String? sport,
    String? position,
    int? minAge,
    int? maxAge,
    String? location,
    AvailabilityStatus? availability,
    TrustBadgeLevel? minBadge,
  }) async {
    var query = supabase.from(_table).select(_selectWithRelations);
    if (sport != null && sport.isNotEmpty) query = query.contains('sports', [sport]);
    if (position != null && position.isNotEmpty) query = query.contains('positions', [position]);
    if (minAge != null) query = query.gte('age', minAge);
    if (maxAge != null) query = query.lte('age', maxAge);
    if (location != null && location.isNotEmpty) {
      query = query.or('city.ilike.%$location%,country.ilike.%$location%');
    }
    if (availability != null) query = query.eq('availability_status', availability.toDb());
    if (minBadge != null) {
      // trust_badge_level's declared enum order matches TrustBadgeLevel's,
      // so a plain text >= comparison ranks it correctly in Postgres.
      query = query.gte('profile_badge_level', minBadge.toDb());
    }
    final rows = await query;
    return (rows as List).map((r) => Athlete.fromJson(r as Map<String, dynamic>)).toList();
  }

  Map<String, dynamic> _writableFields(Athlete a) => {
        'user_id': a.userId,
        'display_name': a.displayName,
        'photo_url': a.photoUrl,
        'sports': a.sports,
        'positions': a.positions,
        'age': a.age,
        'height': a.height,
        'weight': a.weight,
        'dominant_foot_hand': a.dominantFootHand,
        'current_team': a.currentTeam,
        'country': a.country,
        'city': a.city,
        'bio': a.bio,
        'availability_status': a.availabilityStatus.toDb(),
      };
}

/// Exception thrown by profile operations.
class ProfileException implements Exception {
  final String message;
  ProfileException(this.message);

  @override
  String toString() => message;
}

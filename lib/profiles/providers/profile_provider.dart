import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/providers/auth_provider.dart';
import 'package:play_smart/profiles/repositories/profile_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Profile repository provider.
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository();
});

/// Profile notifier — manages athlete profile state.
class ProfileNotifier extends Notifier<AsyncValue<Athlete?>> {
  @override
  AsyncValue<Athlete?> build() {
    return const AsyncValue.data(null);
  }

  ProfileRepository get _repository => ref.read(profileRepositoryProvider);

  /// Load the current user's profile.
  Future<void> loadMyProfile() async {
    state = const AsyncValue.loading();
    try {
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        final profile = await _repository.getAthleteByUserId(authState.user.id);
        state = AsyncValue.data(profile);
      } else {
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Load a specific athlete's profile by ID.
  Future<void> loadAthleteProfile(String athleteId) async {
    state = const AsyncValue.loading();
    try {
      final profile = await _repository.getAthleteById(athleteId);
      state = AsyncValue.data(profile);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create the current user's athlete profile (initial onboarding).
  Future<String?> createProfile(Athlete profile) async {
    try {
      final result = await _repository.createProfile(profile);
      state = AsyncValue.data(result);
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  /// Update the profile.
  Future<void> updateProfile(Athlete updated) async {
    try {
      final result = await _repository.updateProfile(updated);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Add an achievement to the current athlete profile.
  Future<void> addAchievement(Achievement achievement) async {
    try {
      final current = state.value;
      if (current == null) return;
      final result = await _repository.addAchievement(current.id, achievement);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Remove an achievement from the current athlete profile.
  Future<void> removeAchievement(String achievementId) async {
    try {
      final current = state.value;
      if (current == null) return;
      final result = await _repository.removeAchievement(current.id, achievementId);
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

/// Profile state provider.
final profileProvider = NotifierProvider<ProfileNotifier, AsyncValue<Athlete?>>(
  ProfileNotifier.new,
);

/// Provider for the profile repository (for direct non-notifier access).
final profileRepositoryOnlyProvider = Provider<ProfileRepository>((ref) {
  return ref.read(profileRepositoryProvider);
});
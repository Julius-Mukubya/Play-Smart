import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/repositories/auth_repository.dart';
import 'package:play_smart/auth/repositories/known_accounts_store.dart';
import 'package:play_smart/auth/services/auth_service.dart';
import 'package:play_smart/core/push/push_notification_service.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Auth repository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Auth service provider.
final authServiceProvider = Provider<AuthService>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthService(repository);
});

/// Store of accounts previously used on this device — powers "Switch Account".
final knownAccountsStoreProvider = Provider<KnownAccountsStore>((ref) {
  return KnownAccountsStore();
});

/// Auth notifier — manages authentication state.
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    return const AuthInitial();
  }

  AuthService get _authService => ref.read(authServiceProvider);

  static const _cachedUserKey = 'cached_auth_user';

  Future<void> _saveUserLocally(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedUserKey, jsonEncode(user.toJson()));
  }

  Future<void> _clearUserLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cachedUserKey);
  }

  Future<User?> _getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_cachedUserKey);
      if (jsonStr != null) {
        return User.fromJson(jsonDecode(jsonStr) as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }

  /// Check existing session on app start.
  Future<void> checkSession() async {
    state = const AuthLoading();
    final cached = await _getCachedUser();
    if (cached != null) {
      state = AuthAuthenticated(user: cached);
    } else {
      state = const AuthUnauthenticated();
    }

    try {
      final user = await _authService.getSession();
      if (user != null) {
        state = AuthAuthenticated(user: user);
        await _saveUserLocally(user);
        await PushNotificationService.instance.registerToken(user.id);
        await ref.read(knownAccountsStoreProvider).remember(user);
      } else {
        await _clearUserLocally();
        state = const AuthUnauthenticated();
      }
    } catch (_) {
      if (state is! AuthAuthenticated) {
        state = const AuthUnauthenticated();
      }
    }
  }

  /// Sign up a new user.
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
    required AccountRole role,
    DateTime? dateOfBirth,
  }) async {
    state = const AuthLoading();
    try {
      final data = SignUpData(
        name: name,
        email: email,
        password: password,
        role: role,
        dateOfBirth: dateOfBirth,
      );
      final user = await _authService.signUp(data);
      await _saveUserLocally(user);
      state = AuthAuthenticated(user: user);
      await PushNotificationService.instance.registerToken(user.id);
      await ref.read(knownAccountsStoreProvider).remember(user);
    } on AuthException catch (e) {
      state = AuthError(message: e.message);
    } catch (_) {
      state = const AuthError(message: 'An unexpected error occurred. Please try again.');
    }
  }

  /// Sign in with email and password.
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = const AuthLoading();
    try {
      final data = SignInData(email: email, password: password);
      final user = await _authService.signIn(data);
      await _saveUserLocally(user);
      state = AuthAuthenticated(user: user);
      await PushNotificationService.instance.registerToken(user.id);
      await ref.read(knownAccountsStoreProvider).remember(user);
    } on AuthException catch (e) {
      state = AuthError(message: e.message);
    } catch (_) {
      state = const AuthError(message: 'An unexpected error occurred. Please try again.');
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    state = const AuthLoading();
    await _clearUserLocally();
    await PushNotificationService.instance.unregisterToken();
    await _authService.signOut();
    state = const AuthUnauthenticated();
  }

  /// Clear error state.
  void clearError() {
    if (state is AuthError) {
      state = const AuthUnauthenticated();
    }
  }
}

/// Auth state provider.
final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

/// Provider for auth service methods (for use in non-notifier contexts).
final authServiceMethodsProvider = Provider<AuthService>((ref) {
  return ref.watch(authServiceProvider);
});
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/core/supabase/supabase_config.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Auth repository — Supabase Auth + the `public.users` profile row.
///
/// Sign-up does NOT insert into `public.users` directly; a database trigger
/// (`handle_new_user`) creates that row from the `auth.users` metadata payload
/// (role, name, date_of_birth -> is_under_18, verification_status). See
/// `lib/supabase-integration.md` section 3 for the exact trigger behavior.
class AuthRepository {
  User? _cachedUser;

  /// Best-effort synchronous read of the last-fetched profile. Call
  /// [getSession] to refresh from `public.users`.
  User? get currentUser => _cachedUser;

  /// Whether there's an active Supabase session.
  bool get hasSession => supabase.auth.currentSession != null;

  /// Sign up a new user.
  Future<User> signUp(SignUpData data) async {
    if (data.password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }

    try {
      final response = await supabase.auth.signUp(
        email: data.email,
        password: data.password,
        data: {
          'name': data.name,
          'role': data.role.name,
          if (data.dateOfBirth != null)
            'date_of_birth': data.dateOfBirth!.toIso8601String().split('T').first,
        },
      );

      if (response.user == null) {
        throw AuthException('Sign up failed. Please try again.');
      }
      if (response.session == null) {
        // Email confirmation is enabled on this project — the auth user and
        // the public.users row already exist, but there's no session yet.
        throw AuthException('Check your email to confirm your account, then sign in.');
      }

      final user = await _fetchProfile(response.user!.id);
      _cachedUser = user;
      return user;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  /// Sign in with email and password.
  Future<User> signIn(SignInData data) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: data.email,
        password: data.password,
      );
      if (response.user == null) {
        throw AuthException('Invalid email or password.');
      }
      final user = await _fetchProfile(response.user!.id);
      _cachedUser = user;
      return user;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(_friendlyMessage(e));
    }
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await supabase.auth.signOut();
    _cachedUser = null;
  }

  /// Get the current authenticated user's profile, refreshed from `public.users`.
  Future<User?> getSession() async {
    final session = supabase.auth.currentSession;
    if (session == null) {
      _cachedUser = null;
      return null;
    }
    final user = await _fetchProfile(session.user.id);
    _cachedUser = user;
    return user;
  }

  Future<User> _fetchProfile(String userId) async {
    final row = await supabase.from('users').select().eq('id', userId).single();
    return User.fromJson(row);
  }

  /// Look up any user's public profile row by id (e.g. to check role/
  /// verification/under-18 status before sending a message request).
  Future<User?> getUserById(String id) async {
    final row = await supabase.from('users').select().eq('id', id).maybeSingle();
    return row != null ? User.fromJson(row) : null;
  }

  String _friendlyMessage(Object e) {
    final message = e.toString();
    if (message.contains('already registered') || message.contains('already exists')) {
      return 'An account with this email already exists.';
    }
    if (message.contains('Invalid login credentials')) {
      return 'Invalid email or password.';
    }
    return 'Something went wrong. Please try again.';
  }
}

/// Exception thrown by auth operations.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

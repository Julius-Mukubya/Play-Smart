import 'package:play_smart/shared/types/domain_types.dart';

/// Represents the current authentication state.
sealed class AuthState {
  const AuthState();
}

/// Initial state — no session checked yet.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// User is not authenticated.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User is authenticated and session is active.
class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});
}

/// Loading state during auth operations.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Error state with message.
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});
}

/// Sign-up form data.
class SignUpData {
  final String name;
  final String email;
  final String password;
  final AccountRole role;
  final DateTime? dateOfBirth;

  SignUpData({
    required this.name,
    required this.email,
    required this.password,
    required this.role,
    this.dateOfBirth,
  });
}

/// Sign-in form data.
class SignInData {
  final String email;
  final String password;

  SignInData({required this.email, required this.password});
}
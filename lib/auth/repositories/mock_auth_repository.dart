import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/repositories/auth_repository.dart' show AuthException;
import 'package:play_smart/shared/types/domain_types.dart';
import 'package:play_smart/shared/utils/mock_data.dart';

/// In-memory auth repository used by unit tests. Not wired into the app —
/// see `AuthRepository` (Supabase-backed) for the production implementation.
class MockAuthRepository {
  User? _currentUser;
  final List<User> _users = List.from(MockData.users);

  /// Get current logged-in user.
  User? get currentUser => _currentUser;

  /// Check if there's an active session.
  bool get hasSession => _currentUser != null;

  /// Sign up a new user.
  Future<User> signUp(SignUpData data) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Check if email already exists
    if (_users.any((u) => u.email == data.email)) {
      throw AuthException('An account with this email already exists.');
    }

    // Validate password length
    if (data.password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }

    // Determine if user is under 18
    bool isUnder18 = false;
    if (data.dateOfBirth != null) {
      final age = DateTime.now().year - data.dateOfBirth!.year;
      if (age < 18) isUnder18 = true;
    }

    // Create new user
    final newUser = User(
      id: 'user-${DateTime.now().millisecondsSinceEpoch}',
      name: data.name,
      email: data.email,
      role: data.role,
      dateOfBirth: data.dateOfBirth,
      isUnder18: isUnder18,
      verificationStatus: data.role == AccountRole.athlete
          ? VerificationStatus.approved
          : VerificationStatus.pending,
    );

    _users.add(newUser);
    _currentUser = newUser;

    return newUser;
  }

  /// Sign in with email and password.
  Future<User> signIn(SignInData data) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final user = _users.cast<User?>().firstWhere(
          (u) => u!.email == data.email,
          orElse: () => null,
        );

    if (user == null) {
      throw AuthException('No account found with this email.');
    }

    // In a real app, we'd verify the password hash here.
    // For mock, any password works as long as the email exists.
    _currentUser = user;
    return user;
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _currentUser = null;
  }

  /// Get the current authenticated user.
  Future<User?> getSession() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return _currentUser;
  }

  /// Look up any user by id.
  Future<User?> getUserById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _users.firstWhere((u) => u.id == id);
    } catch (_) {
      return null;
    }
  }
}

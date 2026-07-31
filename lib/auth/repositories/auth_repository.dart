import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Mock/In-memory Auth repository — ready to be wired up with Firebase Auth.
class AuthRepository {
  User? _cachedUser;

  User? get currentUser => _cachedUser;

  bool get hasSession => _cachedUser != null;

  Future<User> signUp(SignUpData data) async {
    if (data.password.length < 6) {
      throw AuthException('Password must be at least 6 characters.');
    }

    final user = User(
      id: 'mock_user_${DateTime.now().millisecondsSinceEpoch}',
      name: data.name,
      email: data.email,
      role: data.role,
      verificationStatus: VerificationStatus.approved,
      subscriptionTier: SubscriptionTier.free,
    );
    _cachedUser = user;
    return user;
  }

  Future<User> signIn(SignInData data) async {
    final user = User(
      id: 'mock_user_123',
      name: 'Julius Mukubya',
      email: data.email,
      role: AccountRole.athlete,
      verificationStatus: VerificationStatus.approved,
      subscriptionTier: SubscriptionTier.free,
    );
    _cachedUser = user;
    return user;
  }

  Future<void> signOut() async {
    _cachedUser = null;
  }

  Future<User?> getSession() async {
    return _cachedUser;
  }

  Future<User?> getUserById(String id) async {
    if (_cachedUser != null && _cachedUser!.id == id) {
      return _cachedUser;
    }
    return User(
      id: id,
      name: 'Mock Athlete',
      email: 'mock@playsmart.io',
      role: AccountRole.athlete,
      verificationStatus: VerificationStatus.approved,
      subscriptionTier: SubscriptionTier.free,
    );
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

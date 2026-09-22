import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/repositories/auth_repository.dart';
import 'package:play_smart/shared/types/domain_types.dart';

/// Auth service — handles business logic for authentication flows.
/// Enforces role-based access rules and verification gates.
class AuthService {
  final AuthRepository _repository;

  AuthService(this._repository);

  /// Register a new user.
  Future<User> signUp(SignUpData data) async {
    return _repository.signUp(data);
  }

  /// Sign in an existing user.
  Future<User> signIn(SignInData data) async {
    return _repository.signIn(data);
  }

  /// Sign in with Google.
  Future<User> signInWithGoogle() async {
    return _repository.signInWithGoogle();
  }

  /// Request phone verification OTP via SMS.
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(User user) onVerificationCompleted,
    required void Function(String errorMessage) onVerificationFailed,
    void Function(String verificationId)? onCodeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    return _repository.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      onCodeSent: onCodeSent,
      onVerificationCompleted: onVerificationCompleted,
      onVerificationFailed: onVerificationFailed,
      onCodeAutoRetrievalTimeout: onCodeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
    );
  }

  /// Confirm phone verification OTP.
  Future<User> signInWithPhoneOtp({
    required String verificationId,
    required String smsCode,
    String? name,
    AccountRole? role,
  }) async {
    return _repository.signInWithPhoneOtp(
      verificationId: verificationId,
      smsCode: smsCode,
      name: name,
      role: role,
    );
  }

  /// Sign out the current user.
  Future<void> signOut() async {
    await _repository.signOut();
  }

  /// Get the current session user.
  Future<User?> getSession() async {
    return _repository.getSession();
  }

  /// Check if a recruiter or club user can access gated features.
  bool canAccessGatedFeatures(User user) {
    if (user.role == AccountRole.athlete) return true;
    return user.verificationStatus == VerificationStatus.approved;
  }

  /// Check if a recruiter can shortlist (must be on a paid tier or free with limits).
  bool canShortlist(User user) {
    if (user.role == AccountRole.athlete) return false;
    if (user.role == AccountRole.guest) return false;
    // Free tier can shortlist with limits (enforced in shortlisting boundary)
    return user.verificationStatus == VerificationStatus.approved;
  }

  /// Check if user can message (must be verified recruiter/club or any athlete).
  bool canSendMessageRequest(User user) {
    if (user.role == AccountRole.athlete) return false;
    if (user.role == AccountRole.guest) return false;
    if (user.isUnder18) return false;
    return user.verificationStatus == VerificationStatus.approved;
  }

  /// Get the redirect route after sign-in based on role and onboarding state.
  String getPostSignInRoute(User user) {
    // Athletes go to setup if first time, otherwise discover
    if (user.role == AccountRole.athlete) {
      return AppRoutes.discover;
    }

    // Recruiters and clubs need to submit verification
    if (user.verificationStatus == VerificationStatus.pending) {
      return AppRoutes.verification;
    }

    return AppRoutes.discover;
  }

  /// Check if account is under 18 and apply restrictions.
  bool isUnder18(User user) => user.isUnder18;
}

/// Route constants to avoid circular imports with AppRouter.
class AppRoutes {
  static const String splash = '/';
  static const String landing = '/landing';
  static const String signUp = '/signup';
  static const String signIn = '/signin';
  static const String athleteSetup = '/onboarding/athlete';
  static const String verification = '/onboarding/verification';
  static const String discover = '/discover';
  static const String search = '/search';
  static const String athleteProfile = '/athlete/:id';
  static const String myProfile = '/profile';
  static const String upload = '/upload';
  static const String shortlists = '/shortlists';
  static const String opportunities = '/opportunities';
  static const String messages = '/messages';
  static const String notifications = '/notifications';
  static const String billing = '/account/billing';
  static const String admin = '/admin';
}
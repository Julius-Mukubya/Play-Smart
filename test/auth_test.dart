import 'package:flutter_test/flutter_test.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/auth/repositories/auth_repository.dart';
import 'package:play_smart/auth/repositories/mock_auth_repository.dart';
import 'package:play_smart/auth/services/auth_service.dart';
import 'package:play_smart/shared/types/domain_types.dart';

void main() {
  // These tests exercise auth business rules (duplicate email, password
  // length, under-18 detection, verification defaults) against the in-memory
  // mock — the real `AuthRepository` talks to Supabase and is not unit-tested
  // here. See lib/supabase-integration.md for how to verify it against a live
  // project.
  group('AuthRepository', () {
    late MockAuthRepository repository;

    setUp(() {
      repository = MockAuthRepository();
    });

    test('signUp creates a new user', () async {
      final data = SignUpData(
        name: 'Test User',
        email: 'test@example.com',
        password: 'password123',
        role: AccountRole.athlete,
      );

      final user = await repository.signUp(data);
      expect(user.name, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.role, AccountRole.athlete);
      expect(user.isUnder18, false);
    });

    test('signUp detects duplicate email', () async {
      final data = SignUpData(
        name: 'Duplicate',
        email: 'john@example.com', // Already exists in mock data
        password: 'password123',
        role: AccountRole.athlete,
      );

      expect(
        () async => await repository.signUp(data),
        throwsA(isA<AuthException>()),
      );
    });

    test('signUp rejects short password', () async {
      final data = SignUpData(
        name: 'Short Password',
        email: 'short@example.com',
        password: '123',
        role: AccountRole.athlete,
      );

      expect(
        () async => await repository.signUp(data),
        throwsA(isA<AuthException>()),
      );
    });

    test('signUp marks user as under 18 correctly', () async {
      final data = SignUpData(
        name: 'Young Athlete',
        email: 'young@example.com',
        password: 'password123',
        role: AccountRole.athlete,
        dateOfBirth: DateTime(2010, 1, 1),
      );

      final user = await repository.signUp(data);
      expect(user.isUnder18, true);
    });

    test('signUp sets verification to pending for non-athletes', () async {
      final data = SignUpData(
        name: 'New Recruiter',
        email: 'recruiter@example.com',
        password: 'password123',
        role: AccountRole.recruiter,
      );

      final user = await repository.signUp(data);
      expect(user.verificationStatus, VerificationStatus.pending);
    });

    test('signIn with existing email succeeds', () async {
      final data = SignInData(
        email: 'john@example.com',
        password: 'anypassword',
      );

      final user = await repository.signIn(data);
      expect(user.email, 'john@example.com');
    });

    test('signIn with non-existing email throws', () async {
      final data = SignInData(
        email: 'nonexistent@example.com',
        password: 'password',
      );

      expect(
        () async => await repository.signIn(data),
        throwsA(isA<AuthException>()),
      );
    });

    test('signOut clears current user', () async {
      // Sign in first
      await repository.signIn(SignInData(
        email: 'john@example.com',
        password: 'password',
      ));
      expect(repository.hasSession, true);

      // Sign out
      await repository.signOut();
      expect(repository.hasSession, false);
    });

    test('verifyPhoneNumber sends OTP code for valid phone', () async {
      String? sentVerificationId;
      await repository.verifyPhoneNumber(
        phoneNumber: '+256700123456',
        onCodeSent: (vId, token) {
          sentVerificationId = vId;
        },
        onVerificationCompleted: (_) {},
        onVerificationFailed: (_) {},
      );
      expect(sentVerificationId, isNotNull);
    });

    test('verifyPhoneNumber fails for invalid short phone number', () async {
      String? failureMessage;
      await repository.verifyPhoneNumber(
        phoneNumber: '123',
        onCodeSent: (_, __) {},
        onVerificationCompleted: (_) {},
        onVerificationFailed: (msg) {
          failureMessage = msg;
        },
      );
      expect(failureMessage, 'Invalid phone number.');
    });

    test('signInWithPhoneOtp succeeds with valid code', () async {
      final user = await repository.signInWithPhoneOtp(
        verificationId: 'test-v-id',
        smsCode: '123456',
        name: 'Phone Athlete',
        role: AccountRole.athlete,
      );
      expect(user.name, 'Phone Athlete');
      expect(user.role, AccountRole.athlete);
      expect(repository.hasSession, true);
    });

    test('signInWithPhoneOtp fails with invalid code', () async {
      expect(
        () async => await repository.signInWithPhoneOtp(
          verificationId: 'test-v-id',
          smsCode: '999',
        ),
        throwsA(isA<AuthException>()),
      );
    });
  });

  group('AuthService', () {
    late AuthService service;
    late AuthRepository repository;

    setUp(() {
      repository = AuthRepository();
      service = AuthService(repository);
    });

    test('canAccessGatedFeatures returns true for athletes', () {
      final athlete = MockData.users.firstWhere((u) => u.role == AccountRole.athlete);
      expect(service.canAccessGatedFeatures(athlete), true);
    });

    test('canAccessGatedFeatures returns false for unverified recruiters', () {
      final unverified = MockData.users.firstWhere(
        (u) => u.role == AccountRole.recruiter && u.verificationStatus == VerificationStatus.pending,
      );
      expect(service.canAccessGatedFeatures(unverified), false);
    });

    test('canAccessGatedFeatures returns true for verified recruiters', () {
      final verified = MockData.users.firstWhere(
        (u) => u.role == AccountRole.recruiter && u.verificationStatus == VerificationStatus.approved,
      );
      expect(service.canAccessGatedFeatures(verified), true);
    });

    test('canShortlist returns false for athletes', () {
      final athlete = MockData.users.firstWhere((u) => u.role == AccountRole.athlete);
      expect(service.canShortlist(athlete), false);
    });

    test('getPostSignInRoute returns discover for athletes', () {
      final athlete = MockData.users.firstWhere((u) => u.role == AccountRole.athlete);
      expect(service.getPostSignInRoute(athlete), AppRoutes.discover);
    });

    test('getPostSignInRoute returns verification for unverified recruiters', () {
      final unverified = MockData.users.firstWhere(
        (u) => u.role == AccountRole.recruiter && u.verificationStatus == VerificationStatus.pending,
      );
      expect(service.getPostSignInRoute(unverified), AppRoutes.verification);
    });
  });
}

// MockData subset needed for tests above
class MockData {
  static final List<User> users = [
    User(
      id: 'athlete-1',
      name: 'John Muwonge',
      email: 'john@example.com',
      role: AccountRole.athlete,
      verificationStatus: VerificationStatus.approved,
      subscriptionTier: SubscriptionTier.free,
    ),
    User(
      id: 'recruiter-1',
      name: 'James Kintu',
      email: 'james@scout.com',
      role: AccountRole.recruiter,
      verificationStatus: VerificationStatus.approved,
      subscriptionTier: SubscriptionTier.recruiterPro,
    ),
    User(
      id: 'recruiter-2',
      name: 'Grace Achieng',
      email: 'grace@scout.com',
      role: AccountRole.recruiter,
      verificationStatus: VerificationStatus.pending,
      subscriptionTier: SubscriptionTier.free,
    ),
  ];
}
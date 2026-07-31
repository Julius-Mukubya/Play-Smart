import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:play_smart/auth/models/auth_state.dart';
import 'package:play_smart/shared/types/domain_types.dart' as domain;

/// Auth repository integrated with Firebase Auth and Google Sign-In.
class AuthRepository {
  final fb.FirebaseAuth _auth = fb.FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  domain.User? get currentUser {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return domain.User(
      id: fbUser.uid,
      name: fbUser.displayName ?? 'Google User',
      email: fbUser.email ?? '',
      role: domain.AccountRole.athlete,
      verificationStatus: domain.VerificationStatus.approved,
      subscriptionTier: domain.SubscriptionTier.free,
    );
  }

  bool get hasSession => _auth.currentUser != null;

  Future<domain.User> signUp(SignUpData data) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: data.email,
        password: data.password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw AuthException('Failed to create user.');
      }
      
      // Update display name
      await fbUser.updateDisplayName(data.name);

      return domain.User(
        id: fbUser.uid,
        name: data.name,
        email: data.email,
        role: data.role,
        verificationStatus: domain.VerificationStatus.approved,
        subscriptionTier: domain.SubscriptionTier.free,
      );
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<domain.User> signIn(SignInData data) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: data.email,
        password: data.password,
      );
      final fbUser = credential.user;
      if (fbUser == null) {
        throw AuthException('User not found.');
      }
      return domain.User(
        id: fbUser.uid,
        name: fbUser.displayName ?? 'User',
        email: fbUser.email ?? '',
        role: domain.AccountRole.athlete,
        verificationStatus: domain.VerificationStatus.approved,
        subscriptionTier: domain.SubscriptionTier.free,
      );
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<domain.User> signInWithGoogle() async {
    try {
      final fb.UserCredential credential;
      if (kIsWeb) {
        fb.GoogleAuthProvider authProvider = fb.GoogleAuthProvider();
        credential = await _auth.signInWithPopup(authProvider);
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw AuthException('Google Sign-In cancelled.');
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final fb.AuthCredential authCredential = fb.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
          accessToken: googleAuth.accessToken,
        );
        credential = await _auth.signInWithCredential(authCredential);
      }

      final fbUser = credential.user;
      if (fbUser == null) {
        throw AuthException('Failed to retrieve user from Google Auth.');
      }

      return domain.User(
        id: fbUser.uid,
        name: fbUser.displayName ?? 'Google User',
        email: fbUser.email ?? '',
        role: domain.AccountRole.athlete,
        verificationStatus: domain.VerificationStatus.approved,
        subscriptionTier: domain.SubscriptionTier.free,
      );
    } catch (e) {
      throw AuthException(e.toString());
    }
  }

  Future<void> signOut() async {
    if (!kIsWeb) {
      await _googleSignIn.signOut();
    }
    await _auth.signOut();
  }

  Future<domain.User?> getSession() async {
    final fbUser = _auth.currentUser;
    if (fbUser == null) return null;
    return domain.User(
      id: fbUser.uid,
      name: fbUser.displayName ?? 'Google User',
      email: fbUser.email ?? '',
      role: domain.AccountRole.athlete,
      verificationStatus: domain.VerificationStatus.approved,
      subscriptionTier: domain.SubscriptionTier.free,
    );
  }

  Future<domain.User?> getUserById(String id) async {
    final fbUser = _auth.currentUser;
    if (fbUser != null && fbUser.uid == id) {
      return currentUser;
    }
    return domain.User(
      id: id,
      name: 'User',
      email: 'user@playsmart.io',
      role: domain.AccountRole.athlete,
      verificationStatus: domain.VerificationStatus.approved,
      subscriptionTier: domain.SubscriptionTier.free,
    );
  }
}

class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}

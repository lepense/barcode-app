import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';

import '../domain/auth_repository.dart';

/// Firebase implementation of [AuthRepository].
class FirebaseAuthRepository implements AuthRepository {
  final fb.FirebaseAuth _auth;

  FirebaseAuthRepository({fb.FirebaseAuth? auth})
      : _auth = auth ?? fb.FirebaseAuth.instance;

  @override
  Stream<AuthUser?> get authStateChanges {
    return _auth.authStateChanges().map(_mapUser);
  }

  @override
  AuthUser? get currentUser => _mapUser(_auth.currentUser);

  @override
  Future<AuthUser> signInWithGoogle() async {
    late GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthException('Google sign-in cancelled');
      }
      throw AuthException('Google sign-in failed: ${e.description}');
    }

    // v7: authentication is a sync getter, only idToken (no accessToken)
    final googleAuth = googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    final user = _mapUser(result.user);
    if (user == null) throw AuthException('Sign-in failed');
    return user;
  }

  @override
  Future<AuthUser> signInWithApple() async {
    // Apple sign-in requires sign_in_with_apple package (iOS only)
    // Deferred — will be implemented when iOS build is ready
    throw AuthException('Apple sign-in not available on this platform');
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = _mapUser(result.user);
      if (user == null) throw AuthException('Sign-in failed');
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<AuthUser> signUpWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await result.user?.updateDisplayName(displayName);
      // Reload to pick up display name
      await result.user?.reload();
      final user = _mapUser(_auth.currentUser);
      if (user == null) throw AuthException('Sign-up failed');
      return user;
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on fb.FirebaseAuthException catch (e) {
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  @override
  Future<void> logout() async {
    await Future.wait([
      _auth.signOut(),
      GoogleSignIn.instance.signOut(),
    ]);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException('No user signed in');
    try {
      await user.delete();
    } on fb.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw AuthException(
          'Please sign out and sign back in before deleting your account',
        );
      }
      throw AuthException(_mapFirebaseError(e.code));
    }
  }

  AuthUser? _mapUser(fb.User? user) {
    if (user == null) return null;

    String provider = 'email';
    if (user.providerData.isNotEmpty) {
      final providerId = user.providerData.first.providerId;
      if (providerId == 'google.com') provider = 'google';
      if (providerId == 'apple.com') provider = 'apple';
    }

    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      provider: provider,
    );
  }

  String _mapFirebaseError(String code) {
    return switch (code) {
      'user-not-found' => 'No account found with this email',
      'wrong-password' => 'Incorrect password',
      'invalid-credential' => 'Invalid email or password',
      'email-already-in-use' => 'An account already exists with this email',
      'weak-password' => 'Password must be at least 6 characters',
      'invalid-email' => 'Please enter a valid email address',
      'user-disabled' => 'This account has been disabled',
      'too-many-requests' => 'Too many attempts. Please try again later',
      'network-request-failed' => 'Network error. Check your connection',
      _ => 'Something went wrong. Please try again',
    };
  }
}

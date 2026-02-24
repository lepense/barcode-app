import '../domain/auth_repository.dart';

/// Firebase implementation of [AuthRepository].
/// TODO: Implement in Phase 2 when Firebase is configured.
class FirebaseAuthRepository implements AuthRepository {
  @override
  Stream<AuthUser?> get authStateChanges {
    // TODO: return FirebaseAuth.instance.authStateChanges().map(...)
    return Stream.value(null);
  }

  @override
  AuthUser? get currentUser => null;

  @override
  Future<AuthUser> signInWithGoogle() async {
    throw UnimplementedError('Google sign-in not yet implemented');
  }

  @override
  Future<AuthUser> signInWithApple() async {
    throw UnimplementedError('Apple sign-in not yet implemented');
  }

  @override
  Future<AuthUser> signInWithEmail(String email, String password) async {
    throw UnimplementedError('Email sign-in not yet implemented');
  }

  @override
  Future<AuthUser> signUpWithEmail(
      String email, String password, String displayName) async {
    throw UnimplementedError('Email sign-up not yet implemented');
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    throw UnimplementedError('Password reset not yet implemented');
  }

  @override
  Future<void> logout() async {
    throw UnimplementedError('Logout not yet implemented');
  }

  @override
  Future<void> deleteAccount() async {
    throw UnimplementedError('Delete account not yet implemented');
  }
}

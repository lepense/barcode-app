/// Abstract auth repository — implementation uses Firebase Auth.
abstract class AuthRepository {
  /// Stream of authenticated user (null = signed out)
  Stream<AuthUser?> get authStateChanges;

  /// Current user snapshot
  AuthUser? get currentUser;

  Future<AuthUser> signInWithGoogle();
  Future<AuthUser> signInWithApple();
  Future<AuthUser> signInWithEmail(String email, String password);
  Future<AuthUser> signUpWithEmail(String email, String password, String displayName);
  Future<void> sendPasswordReset(String email);
  Future<void> logout();
  Future<void> deleteAccount();
}

/// Domain model for an authenticated user.
class AuthUser {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final String provider; // "google", "apple", "email"

  const AuthUser({
    required this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.provider,
  });
}

/// Auth-specific exception with user-friendly message.
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

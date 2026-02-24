import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/data/firebase_auth_repository.dart';
import '../../features/auth/domain/auth_repository.dart';

/// Provides the auth repository implementation.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

/// Stream of the current auth state.
final authStateProvider = StreamProvider<AuthUser?>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return repo.authStateChanges;
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/encryption_service.dart';
import 'database_provider.dart';
import '../../features/cards/data/drift_card_repository.dart';
import '../../features/cards/domain/card_model.dart';
import '../../features/cards/domain/card_repository.dart';

/// Provides the initialised [AesEncryptionService].
///
/// The FutureProvider ensures `init()` is awaited before the service is used.
final encryptionServiceProvider =
    FutureProvider<EncryptionService>((ref) async {
  final service = AesEncryptionService();
  await service.init();
  return service;
});

/// Provides the concrete [CardRepository].
final cardRepositoryProvider = Provider<CardRepository>((ref) {
  final db = ref.watch(databaseProvider);
  // Encryption is loaded asynchronously; fall back to a no-op until ready.
  // Screens that need the repo should first watch [encryptionServiceProvider].
  final encryptionAsync = ref.watch(encryptionServiceProvider);
  return encryptionAsync.when(
    data: (enc) => DriftCardRepository(db, enc),
    loading: () => DriftCardRepository(db, _NoOpEncryptionService()),
    error: (_, __) => DriftCardRepository(db, _NoOpEncryptionService()),
  );
});

/// Streams the full list of cards, rebuilt on every DB change.
final cardsStreamProvider = StreamProvider<List<LoyaltyCard>>((ref) {
  return ref.watch(cardRepositoryProvider).watchAllCards();
});

/// No-op encryption used during the brief init window (key not yet loaded).
class _NoOpEncryptionService implements EncryptionService {
  @override
  String encrypt(String plaintext) => plaintext;
  @override
  String decrypt(String ciphertext) => ciphertext;
}

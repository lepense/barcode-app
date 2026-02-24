/// Abstract encryption service for barcode values.
/// Implementation will use AES-256 via the `encrypt` package.
abstract class EncryptionService {
  /// Encrypt plaintext barcode value.
  String encrypt(String plaintext);

  /// Decrypt encrypted barcode value.
  String decrypt(String ciphertext);
}

/// TODO: Implement in Phase 3 with proper key management.
class AesEncryptionService implements EncryptionService {
  @override
  String encrypt(String plaintext) {
    // Placeholder — returns plaintext until encryption is implemented
    return plaintext;
  }

  @override
  String decrypt(String ciphertext) {
    // Placeholder — returns ciphertext until decryption is implemented
    return ciphertext;
  }
}

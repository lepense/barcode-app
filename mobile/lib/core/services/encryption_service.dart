import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract encryption service for barcode values.
abstract class EncryptionService {
  /// Encrypt plaintext barcode value.
  String encrypt(String plaintext);

  /// Decrypt encrypted barcode value.
  String decrypt(String ciphertext);
}

/// AES-256 implementation using flutter_secure_storage for key persistence.
///
/// Key is generated once and stored in the device Keychain/Keystore.
/// Must call [init] before using encrypt/decrypt.
class AesEncryptionService implements EncryptionService {
  static const _keyStorageKey = 'barcode_app_aes_key';
  static const _ivStorageKey = 'barcode_app_aes_iv';

  final FlutterSecureStorage _storage;
  late Key _key;
  late IV _iv;

  AesEncryptionService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Must be called once at app startup (e.g., inside a FutureProvider).
  Future<void> init() async {
    final storedKey = await _storage.read(key: _keyStorageKey);
    final storedIv = await _storage.read(key: _ivStorageKey);

    if (storedKey != null && storedIv != null) {
      _key = Key.fromBase64(storedKey);
      _iv = IV.fromBase64(storedIv);
    } else {
      _key = Key.fromSecureRandom(32); // AES-256
      _iv = IV.fromSecureRandom(16);
      await _storage.write(key: _keyStorageKey, value: _key.base64);
      await _storage.write(key: _ivStorageKey, value: _iv.base64);
    }
  }

  @override
  String encrypt(String plaintext) {
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    return encrypter.encrypt(plaintext, iv: _iv).base64;
  }

  @override
  String decrypt(String ciphertext) {
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    return encrypter.decrypt64(ciphertext, iv: _iv);
  }
}

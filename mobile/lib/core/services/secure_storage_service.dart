import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Abstract secure storage for tokens and sensitive keys.
abstract class SecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// Implementation using flutter_secure_storage (Keychain on iOS, Keystore on Android).
class FlutterSecureStorageService implements SecureStorageService {
  final FlutterSecureStorage _storage;

  FlutterSecureStorageService()
      : _storage = const FlutterSecureStorage();

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}

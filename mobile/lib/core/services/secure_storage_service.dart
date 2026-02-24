/// Abstract secure storage for tokens and sensitive keys.
/// Implementation will use flutter_secure_storage.
abstract class SecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
}

/// TODO: Implement in Phase 2 with flutter_secure_storage.
class FlutterSecureStorageService implements SecureStorageService {
  @override
  Future<void> write(String key, String value) async {
    // TODO: Implement with FlutterSecureStorage
  }

  @override
  Future<String?> read(String key) async {
    // TODO: Implement with FlutterSecureStorage
    return null;
  }

  @override
  Future<void> delete(String key) async {
    // TODO: Implement with FlutterSecureStorage
  }

  @override
  Future<void> deleteAll() async {
    // TODO: Implement with FlutterSecureStorage
  }
}

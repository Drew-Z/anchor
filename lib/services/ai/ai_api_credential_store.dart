import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract class AiApiCredentialStore {
  Future<String?> readApiKey(String providerId);

  Future<void> writeApiKey(String providerId, String apiKey);

  Future<void> deleteApiKey(String providerId);
}

class SecureAiApiCredentialStore implements AiApiCredentialStore {
  static const String _keyPrefix = 'anchor_learning.ai.api_key.';

  final FlutterSecureStorage _storage;

  const SecureAiApiCredentialStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(),
  }) : _storage = storage;

  @override
  Future<String?> readApiKey(String providerId) {
    return _storage.read(key: _storageKey(providerId));
  }

  @override
  Future<void> writeApiKey(String providerId, String apiKey) {
    return _storage.write(key: _storageKey(providerId), value: apiKey);
  }

  @override
  Future<void> deleteApiKey(String providerId) {
    return _storage.delete(key: _storageKey(providerId));
  }

  String _storageKey(String providerId) {
    final normalized = providerId
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '_');
    return '$_keyPrefix${normalized.isEmpty ? 'custom' : normalized}';
  }
}

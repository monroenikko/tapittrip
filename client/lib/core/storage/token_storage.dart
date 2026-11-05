import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class TokenStorage {
  Future<String?> readToken();
  Future<void> writeToken(String token);
  Future<void> deleteToken();
}

class SecureTokenStorage implements TokenStorage {
  const SecureTokenStorage([this._storage = const FlutterSecureStorage()]);

  final FlutterSecureStorage _storage;
  static const _key = 'tapittrip_access_token';

  @override
  Future<String?> readToken() => _storage.read(key: _key);

  @override
  Future<void> writeToken(String token) =>
      _storage.write(key: _key, value: token);

  @override
  Future<void> deleteToken() => _storage.delete(key: _key);
}

class InMemoryTokenStorage implements TokenStorage {
  InMemoryTokenStorage([this._token]);

  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async => _token = token;

  @override
  Future<void> deleteToken() async => _token = null;
}

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return const SecureTokenStorage();
});

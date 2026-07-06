import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenRepository {
  final FlutterSecureStorage _storage;
  static const _tokenKey = 'github_token';

  TokenRepository({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<void> saveToken(String token) => _storage.write(key: _tokenKey, value: token);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
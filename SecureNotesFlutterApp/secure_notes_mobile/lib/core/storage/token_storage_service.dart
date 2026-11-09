import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  static const String _accessTokenKey = 'access_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _expiresAtKey = 'access_token_expires_at';

  final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(),
  );

  Future<void> saveAccessToken({
    required String accessToken,
    required String tokenType,
    required DateTime expiresAt,
  }) async {
    await _storage.write(key: _accessTokenKey, value: accessToken);

    await _storage.write(key: _tokenTypeKey, value: tokenType);

    await _storage.write(
      key: _expiresAtKey,
      value: expiresAt.toUtc().toIso8601String(),
    );
  }

  Future<String?> readAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<String?> readTokenType() async {
    return _storage.read(key: _tokenTypeKey);
  }

  Future<DateTime?> readExpiresAt() async {
    final String? storedValue = await _storage.read(key: _expiresAtKey);

    if (storedValue == null) {
      return null;
    }

    return DateTime.tryParse(storedValue);
  }

  Future<void> deleteAccessToken() async {
    await _storage.delete(key: _accessTokenKey);

    await _storage.delete(key: _tokenTypeKey);

    await _storage.delete(key: _expiresAtKey);
  }
}

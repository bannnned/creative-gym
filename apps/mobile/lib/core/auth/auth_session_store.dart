import 'package:flutter_secure_storage/flutter_secure_storage.dart';

abstract interface class AuthSessionStore {
  Future<String?> readToken();

  Future<void> writeToken(String token);

  Future<void> clear();
}

class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'creative_gym_session_token';

  final FlutterSecureStorage _storage;
  String? _cachedToken;
  bool _hasLoaded = false;

  @override
  Future<String?> readToken() async {
    if (!_hasLoaded) {
      _cachedToken = await _storage.read(key: _tokenKey);
      _hasLoaded = true;
    }

    return _cachedToken;
  }

  @override
  Future<void> writeToken(String token) async {
    _cachedToken = token;
    _hasLoaded = true;
    await _storage.write(key: _tokenKey, value: token);
  }

  @override
  Future<void> clear() async {
    _cachedToken = null;
    _hasLoaded = true;
    await _storage.delete(key: _tokenKey);
  }
}

class MemoryAuthSessionStore implements AuthSessionStore {
  String? _token;

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> writeToken(String token) async {
    _token = token;
  }

  @override
  Future<void> clear() async {
    _token = null;
  }
}

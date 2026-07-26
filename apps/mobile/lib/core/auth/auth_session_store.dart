import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StoredTestAccount {
  const StoredTestAccount({
    required this.userId,
    required this.token,
    required this.label,
    required this.isAdmin,
  });

  final String userId;
  final String token;
  final String label;
  final bool isAdmin;

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'token': token,
    'label': label,
    'is_admin': isAdmin,
  };

  factory StoredTestAccount.fromJson(Map<String, dynamic> json) {
    return StoredTestAccount(
      userId: json['user_id'] as String? ?? '',
      token: json['token'] as String? ?? '',
      label: json['label'] as String? ?? 'Участник',
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }
}

abstract interface class AuthSessionStore {
  Future<String?> readToken();

  Future<void> writeToken(String token);

  Future<void> clear();

  Future<List<StoredTestAccount>> readTestAccounts();

  Future<void> writeTestAccounts(List<StoredTestAccount> accounts);
}

class SecureAuthSessionStore implements AuthSessionStore {
  SecureAuthSessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'creative_gym_session_token';
  static const _testAccountsKey = 'creative_gym_test_accounts';

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

  @override
  Future<List<StoredTestAccount>> readTestAccounts() async {
    final encoded = await _storage.read(key: _testAccountsKey);
    if (encoded == null || encoded.isEmpty) {
      return const [];
    }
    try {
      final values = jsonDecode(encoded);
      if (values is! List<dynamic>) {
        return const [];
      }
      return values
          .whereType<Map<String, dynamic>>()
          .map(StoredTestAccount.fromJson)
          .where(
            (account) => account.userId.isNotEmpty && account.token.isNotEmpty,
          )
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  @override
  Future<void> writeTestAccounts(List<StoredTestAccount> accounts) async {
    await _storage.write(
      key: _testAccountsKey,
      value: jsonEncode(accounts.map((account) => account.toJson()).toList()),
    );
  }
}

class MemoryAuthSessionStore implements AuthSessionStore {
  String? _token;
  List<StoredTestAccount> _testAccounts = const [];

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

  @override
  Future<List<StoredTestAccount>> readTestAccounts() async =>
      List.unmodifiable(_testAccounts);

  @override
  Future<void> writeTestAccounts(List<StoredTestAccount> accounts) async {
    _testAccounts = List.unmodifiable(accounts);
  }
}

import 'package:creative_gym_mobile/core/auth/auth_session_store.dart';
import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/auth/domain/test_account.dart';
import 'package:creative_gym_mobile/features/auth/domain/auth_user.dart';
import 'package:creative_gym_mobile/features/auth/data/passkey_service.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  AuthRepository(
    this._apiClient,
    this._sessionStore,
    this._usesRemoteAuth, {
    this.onSessionChanged,
    PasskeyService? passkeys,
  }) : _passkeys = passkeys ?? PasskeyService(_apiClient);

  final ApiClient _apiClient;
  final AuthSessionStore _sessionStore;
  final bool _usesRemoteAuth;
  final PasskeyService _passkeys;
  final void Function()? onSessionChanged;

  static const maxTestAccounts = 8;

  Future<bool> restoreSession() async {
    if (!_usesRemoteAuth) {
      return false;
    }

    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      await _apiClient.getJson('/api/v1/auth/me');
      return true;
    } on DioException catch (error) {
      final apiError = error.error;
      if (apiError is ApiException && apiError.statusCode == 401) {
        await _sessionStore.clear();
        onSessionChanged?.call();
        return false;
      }

      // Keep a known session during a temporary network outage. The next screen
      // can show its regular retry state instead of creating another account.
      return true;
    }
  }

  Future<void> signInAsGuest() async {
    if (!_usesRemoteAuth) {
      return;
    }

    try {
      final response = await _apiClient.postJson('/api/v1/auth/guest');
      final token = response['token'];
      if (token is! String || token.isEmpty) {
        throw const ApiException(
          code: 'invalid_session_response',
          message: 'The server did not return a session token.',
        );
      }

      await _sessionStore.writeToken(token);
      onSessionChanged?.call();
    } on DioException catch (error) {
      final apiError = error.error;
      if (apiError is ApiException) {
        throw apiError;
      }
      rethrow;
    }
  }

  Future<AuthUser> getCurrentUser() async {
    final response = await _request(
      () => _apiClient.getJson('/api/v1/auth/me'),
    );
    return _userFromEnvelope(response);
  }

  Future<Map<String, dynamic>> startEmailVerification(String email) async {
    await ensureSession();
    return _request(
      () => _apiClient.postJson(
        '/api/v1/auth/email/start',
        body: {'email': email.trim()},
      ),
    );
  }

  Future<String> startYandex() async {
    await ensureSession();
    final response = await _request(
      () => _apiClient.postJson('/api/v1/auth/yandex/start'),
    );
    final authorizationUrl = response['authorization_url'];
    if (authorizationUrl is! String || authorizationUrl.isEmpty) {
      throw const ApiException(
        code: 'invalid_yandex_response',
        message: 'The server did not return a Yandex authorization URL.',
      );
    }
    return authorizationUrl;
  }

  Future<AuthUser> exchangeCode(String code) async {
    final response = await _request(
      () => _apiClient.postJson('/api/v1/auth/exchange', body: {'code': code}),
    );
    await _storeSession(response);
    return _userFromEnvelope(response);
  }

  Future<AuthUser> signInWithPasskey() async {
    final response = await _passkeys.authenticate();
    await _storeSession(response);
    return _userFromEnvelope(response);
  }

  Future<AuthUser> createPasskey() async {
    await ensureSession();
    await _passkeys.register();
    return getCurrentUser();
  }

  Future<void> ensureSession() async {
    if (!_usesRemoteAuth) {
      return;
    }
    final token = await _sessionStore.readToken();
    if (token == null || token.isEmpty) {
      await signInAsGuest();
    }
  }

  Future<void> _storeSession(Map<String, dynamic> response) async {
    final token = response['token'];
    if (token is! String || token.isEmpty) {
      throw const ApiException(
        code: 'invalid_session_response',
        message: 'The server did not return a session token.',
      );
    }
    await _sessionStore.writeToken(token);
    onSessionChanged?.call();
  }

  AuthUser _userFromEnvelope(Map<String, dynamic> response) {
    final user = response['user'];
    if (user is! Map<String, dynamic>) {
      throw const ApiException(
        code: 'invalid_session_response',
        message: 'The server did not return the current user.',
      );
    }
    return AuthUser.fromJson(user);
  }

  Future<List<TestAccount>> getTestAccounts({
    required bool currentIsAdmin,
  }) async {
    var activeToken = await _sessionStore.readToken();
    if (activeToken == null || activeToken.isEmpty) {
      if (_usesRemoteAuth) {
        throw const ApiException(
          code: 'session_required',
          statusCode: 401,
          message: 'A valid session is required.',
        );
      }
      activeToken = 'mock-current-session';
      await _sessionStore.writeToken(activeToken);
    }

    final accounts = (await _sessionStore.readTestAccounts()).toList();
    final activeIndex = accounts.indexWhere(
      (account) => account.token == activeToken,
    );
    if (activeIndex == -1) {
      final userId = _usesRemoteAuth
          ? await _loadCurrentUserId()
          : 'mock-current-user';
      accounts.add(
        StoredTestAccount(
          userId: userId,
          token: activeToken,
          label: currentIsAdmin
              ? 'Администратор'
              : _nextParticipantLabel(accounts),
          isAdmin: currentIsAdmin,
        ),
      );
      await _sessionStore.writeTestAccounts(accounts);
    } else if (currentIsAdmin && !accounts[activeIndex].isAdmin) {
      final current = accounts[activeIndex];
      accounts[activeIndex] = StoredTestAccount(
        userId: current.userId,
        token: current.token,
        label: 'Администратор',
        isAdmin: true,
      );
      await _sessionStore.writeTestAccounts(accounts);
    }

    return _summaries(accounts, activeToken);
  }

  Future<List<TestAccount>> createTestAccount() async {
    final status = await _request(
      () => _apiClient.getJson('/api/v1/admin/status'),
    );
    if (status['is_admin'] != true) {
      throw const ApiException(
        code: 'admin_required',
        statusCode: 403,
        message: 'Admin access is required.',
      );
    }

    final accounts = (await getTestAccounts(currentIsAdmin: true)).toList();
    final testAccountCount = accounts
        .where((account) => !account.isAdmin)
        .length;
    if (testAccountCount >= maxTestAccounts) {
      throw const ApiException(
        code: 'test_account_limit',
        message: 'The test account limit has been reached.',
      );
    }

    final response = await _request(
      () => _apiClient.postJson('/api/v1/auth/guest'),
    );
    final token = response['token'];
    final user = response['user'];
    final userId = user is Map<String, dynamic> ? user['id'] : null;
    if (token is! String ||
        token.isEmpty ||
        userId is! String ||
        userId.isEmpty) {
      throw const ApiException(
        code: 'invalid_session_response',
        message: 'The server did not return a test session.',
      );
    }

    final stored = await _sessionStore.readTestAccounts();
    final updated = [
      ...stored,
      StoredTestAccount(
        userId: userId,
        token: token,
        label: _nextParticipantLabel(stored),
        isAdmin: false,
      ),
    ];
    await _sessionStore.writeTestAccounts(updated);
    await _sessionStore.writeToken(token);
    onSessionChanged?.call();
    return _summaries(updated, token);
  }

  Future<void> switchTestAccount(String userId) async {
    final accounts = await _sessionStore.readTestAccounts();
    final account = _findStoredAccount(accounts, userId);
    if (account == null) {
      throw const ApiException(
        code: 'test_account_not_found',
        message: 'The test account is not available.',
      );
    }
    await _sessionStore.writeToken(account.token);
    onSessionChanged?.call();
  }

  Future<List<TestAccount>> removeTestAccount(String userId) async {
    final activeToken = await _sessionStore.readToken();
    final accounts = await _sessionStore.readTestAccounts();
    final account = _findStoredAccount(accounts, userId);
    if (account == null) {
      return _summaries(accounts, activeToken ?? '');
    }
    if (account.isAdmin || account.token == activeToken) {
      throw const ApiException(
        code: 'test_account_protected',
        message: 'The active or admin account cannot be removed.',
      );
    }

    final updated = accounts
        .where((item) => item.userId != userId)
        .toList(growable: false);
    await _sessionStore.writeTestAccounts(updated);
    return _summaries(updated, activeToken ?? '');
  }

  Future<String> _loadCurrentUserId() async {
    final response = await _request(
      () => _apiClient.getJson('/api/v1/auth/me'),
    );
    final user = response['user'];
    final userId = user is Map<String, dynamic> ? user['id'] : null;
    if (userId is! String || userId.isEmpty) {
      throw const ApiException(
        code: 'invalid_session_response',
        message: 'The server did not return the current user.',
      );
    }
    return userId;
  }

  List<TestAccount> _summaries(
    List<StoredTestAccount> accounts,
    String activeToken,
  ) {
    return accounts
        .map(
          (account) => TestAccount(
            userId: account.userId,
            label: account.label,
            isAdmin: account.isAdmin,
            isCurrent: account.token == activeToken,
          ),
        )
        .toList(growable: false);
  }

  String _nextParticipantLabel(List<StoredTestAccount> accounts) {
    var number = 1;
    final used = accounts.map((account) => account.label).toSet();
    while (used.contains('Участник $number')) {
      number++;
    }
    return 'Участник $number';
  }

  StoredTestAccount? _findStoredAccount(
    List<StoredTestAccount> accounts,
    String userId,
  ) {
    for (final account in accounts) {
      if (account.userId == userId) {
        return account;
      }
    }
    return null;
  }

  Future<Map<String, dynamic>> _request(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      final wrapped = error.error;
      throw wrapped is ApiException ? wrapped : error;
    }
  }
}

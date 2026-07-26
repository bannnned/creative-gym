import 'package:creative_gym_mobile/core/auth/auth_session_store.dart';
import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:dio/dio.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._sessionStore, this._usesRemoteAuth);

  final ApiClient _apiClient;
  final AuthSessionStore _sessionStore;
  final bool _usesRemoteAuth;

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
    } on DioException catch (error) {
      final apiError = error.error;
      if (apiError is ApiException) {
        throw apiError;
      }
      rethrow;
    }
  }

  Future<void> startNewGuestSession() async {
    await _sessionStore.clear();
    await signInAsGuest();
  }
}

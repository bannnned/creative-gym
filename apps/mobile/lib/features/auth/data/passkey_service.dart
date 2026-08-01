import 'dart:convert';

import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:passkeys/authenticator.dart';
import 'package:passkeys/types.dart';

class PasskeyService {
  PasskeyService(this._client, {PasskeyAuthenticator? authenticator})
    : _authenticator = authenticator ?? PasskeyAuthenticator();

  final ApiClient _client;
  final PasskeyAuthenticator _authenticator;

  Future<void> register() async {
    final start = await _client.postJson(
      '/api/v1/auth/passkeys/register/options',
    );
    final challengeId = start['challenge_id'] as String? ?? '';
    final options = _publicKeyOptions(start);
    final request = RegisterRequestType.fromJsonString(jsonEncode(options));
    final response = await _authenticator.register(request);
    await _client.postJson(
      '/api/v1/auth/passkeys/register/verify?challenge_id=${Uri.encodeQueryComponent(challengeId)}',
      body: response.toJson(),
    );
  }

  Future<Map<String, dynamic>> authenticate() async {
    final start = await _client.postJson('/api/v1/auth/passkeys/login/options');
    final challengeId = start['challenge_id'] as String? ?? '';
    final options = _publicKeyOptions(start);
    final request = AuthenticateRequestType.fromJsonString(
      jsonEncode(options),
      preferImmediatelyAvailableCredentials: false,
    );
    final response = await _authenticator.authenticate(request);
    return _client.postJson(
      '/api/v1/auth/passkeys/login/verify?challenge_id=${Uri.encodeQueryComponent(challengeId)}',
      body: response.toJson(),
    );
  }

  Map<String, dynamic> _publicKeyOptions(Map<String, dynamic> envelope) {
    final options = envelope['options'];
    if (options is! Map<String, dynamic>) {
      throw const FormatException('Missing passkey options.');
    }
    final publicKey = options['publicKey'];
    if (publicKey is Map<String, dynamic>) {
      return publicKey;
    }
    return options;
  }
}

import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/admin/domain/admin_challenge.dart';
import 'package:creative_gym_mobile/features/admin/domain/admin_repository.dart';
import 'package:dio/dio.dart';

class ApiAdminRepository implements AdminRepository {
  const ApiAdminRepository(this._client);

  final ApiClient _client;

  @override
  Future<bool> isAdmin() async {
    final json = await _request(() => _client.getJson('/api/v1/admin/status'));
    return json['is_admin'] as bool? ?? false;
  }

  @override
  Future<void> unlock(String code) async {
    await _request(
      () => _client.postJson('/api/v1/admin/unlock', body: {'code': code}),
    );
  }

  @override
  Future<AdminChallenge> getChallenge(String challengeId) async {
    final json = await _request(
      () => _client.getJson('/api/v1/challenges/$challengeId'),
    );
    return _challengeFromEnvelope(json);
  }

  @override
  Future<AdminChallenge> createChallenge(AdminChallengeDraft draft) async {
    final json = await _request(
      () => _client.postJson('/api/v1/admin/challenges', body: draft.toJson()),
    );
    return _challengeFromEnvelope(json);
  }

  @override
  Future<AdminChallenge> updateChallenge(
    String challengeId,
    AdminChallengeDraft draft,
  ) async {
    final json = await _request(
      () => _client.patchJson(
        '/api/v1/admin/challenges/$challengeId',
        body: draft.toJson(),
      ),
    );
    return _challengeFromEnvelope(json);
  }

  @override
  Future<void> archiveChallenge(String challengeId) async {
    try {
      await _client.delete('/api/v1/admin/challenges/$challengeId');
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  AdminChallenge _challengeFromEnvelope(Map<String, dynamic> json) {
    final challenge = json['challenge'] as Map<String, dynamic>? ?? const {};
    return AdminChallenge.fromJson(challenge);
  }

  Future<Map<String, dynamic>> _request(
    Future<Map<String, dynamic>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  Object _unwrap(DioException error) {
    final wrapped = error.error;
    return wrapped is ApiException ? wrapped : error;
  }
}

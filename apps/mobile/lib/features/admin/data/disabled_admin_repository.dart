import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/features/admin/domain/admin_challenge.dart';
import 'package:creative_gym_mobile/features/admin/domain/admin_repository.dart';

class DisabledAdminRepository implements AdminRepository {
  const DisabledAdminRepository();

  static const _error = ApiException(
    code: 'admin_unavailable',
    message: 'Admin mode is unavailable in mock mode.',
  );

  @override
  Future<bool> isAdmin() async => false;

  @override
  Future<void> unlock(String code) async => throw _error;

  @override
  Future<AdminChallenge> getChallenge(String challengeId) async => throw _error;

  @override
  Future<AdminChallenge> createChallenge(AdminChallengeDraft draft) async =>
      throw _error;

  @override
  Future<AdminChallenge> updateChallenge(
    String challengeId,
    AdminChallengeDraft draft,
  ) async => throw _error;

  @override
  Future<void> archiveChallenge(String challengeId) async => throw _error;
}

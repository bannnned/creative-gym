import 'package:creative_gym_mobile/features/admin/domain/admin_challenge.dart';

abstract interface class AdminRepository {
  Future<bool> isAdmin();

  Future<void> unlock(String code);

  Future<AdminChallenge> getChallenge(String challengeId);

  Future<AdminChallenge> createChallenge(AdminChallengeDraft draft);

  Future<AdminChallenge> updateChallenge(
    String challengeId,
    AdminChallengeDraft draft,
  );

  Future<void> archiveChallenge(String challengeId);
}

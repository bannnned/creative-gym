import 'package:creative_gym_mobile/features/profile/domain/profile_data.dart';

abstract interface class ProfileRepository {
  Future<ProfileData> getProfile();
}

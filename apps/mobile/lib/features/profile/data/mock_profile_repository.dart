import 'package:creative_gym_mobile/features/profile/data/mock_profile_data.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_data.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_repository.dart';

class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository();

  @override
  Future<ProfileData> getProfile() async => mockProfileData;
}

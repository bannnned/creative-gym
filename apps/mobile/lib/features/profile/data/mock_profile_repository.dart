import 'package:creative_gym_mobile/features/profile/data/mock_profile_data.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_data.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_repository.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';

class MockProfileRepository implements ProfileRepository {
  const MockProfileRepository();

  @override
  Future<ProfileData> getProfile({String? userId}) async {
    if (userId == null) {
      return mockProfileData;
    }
    return ProfileData(
      userId: userId,
      displayName: 'Участник',
      isCurrentUser: false,
      points: mockProfileData.points,
      firstPlaces: mockProfileData.firstPlaces,
      secondPlaces: mockProfileData.secondPlaces,
      thirdPlaces: mockProfileData.thirdPlaces,
      works: mockProfileData.works,
    );
  }

  @override
  Future<String> uploadAvatar(SelectedPhoto photo) async {
    return '/demo/profile/avatar';
  }
}

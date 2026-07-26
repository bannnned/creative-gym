import 'package:creative_gym_mobile/features/profile/domain/profile_data.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';

abstract interface class ProfileRepository {
  Future<ProfileData> getProfile({String? userId});

  Future<String> uploadAvatar(SelectedPhoto photo);
}

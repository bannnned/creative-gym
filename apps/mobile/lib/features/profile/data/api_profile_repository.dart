import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_data.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_repository.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';
import 'package:dio/dio.dart';

class ApiProfileRepository implements ProfileRepository {
  const ApiProfileRepository(this._client);

  final ApiClient _client;

  @override
  Future<ProfileData> getProfile({String? userId}) async {
    final path = userId == null
        ? '/api/v1/profile/me'
        : '/api/v1/profiles/$userId';
    final json = await _client.getJson(path);
    final profile = json['profile'] as Map<String, dynamic>? ?? const {};
    final works = (profile['works'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (work) => ProfileWork(
            id: work['id'] as String? ?? '',
            title: work['title'] as String? ?? 'Работа',
            paletteStart: 0xFF91B7A8,
            paletteEnd: 0xFF244D42,
            composition: 0,
            mediaUrl: work['media_url'] as String? ?? '',
            place: (work['place'] as num?)?.toInt(),
          ),
        )
        .toList(growable: false);
    return ProfileData(
      userId: profile['id'] as String? ?? userId ?? '',
      displayName: profile['display_name'] as String? ?? 'Участник',
      avatarUrl: profile['avatar_url'] as String? ?? '',
      isCurrentUser: profile['is_current_user'] as bool? ?? userId == null,
      emailVerified: profile['email_verified'] as bool? ?? false,
      pendingPrizePoints:
          (profile['pending_prize_points'] as num?)?.toInt() ?? 0,
      points: (profile['points'] as num?)?.toInt() ?? 0,
      firstPlaces: (profile['first_places'] as num?)?.toInt() ?? 0,
      secondPlaces: (profile['second_places'] as num?)?.toInt() ?? 0,
      thirdPlaces: (profile['third_places'] as num?)?.toInt() ?? 0,
      works: works,
    );
  }

  @override
  Future<String> uploadAvatar(SelectedPhoto photo) async {
    try {
      final json = await _client.putMultipart(
        '/api/v1/profile/me/avatar',
        formData: FormData.fromMap({
          'avatar': MultipartFile.fromBytes(
            photo.bytes,
            filename: photo.fileName,
          ),
        }),
      );
      return json['avatar_url'] as String? ?? '';
    } on DioException catch (error) {
      final wrapped = error.error;
      if (wrapped is Exception) {
        throw wrapped;
      }
      rethrow;
    }
  }
}

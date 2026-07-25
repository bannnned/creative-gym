import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_data.dart';
import 'package:creative_gym_mobile/features/profile/domain/profile_repository.dart';

class ApiProfileRepository implements ProfileRepository {
  const ApiProfileRepository(this._client);

  final ApiClient _client;

  @override
  Future<ProfileData> getProfile() async {
    final json = await _client.getJson('/api/v1/profile/me');
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
      points: (profile['points'] as num?)?.toInt() ?? 0,
      firstPlaces: (profile['first_places'] as num?)?.toInt() ?? 0,
      secondPlaces: (profile['second_places'] as num?)?.toInt() ?? 0,
      thirdPlaces: (profile['third_places'] as num?)?.toInt() ?? 0,
      works: works,
    );
  }
}

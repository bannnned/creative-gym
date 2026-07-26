import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/results/domain/results_repository.dart';
import 'package:creative_gym_mobile/features/results/domain/room_result.dart';

class ApiResultsRepository implements ResultsRepository {
  const ApiResultsRepository(this._client);

  final ApiClient _client;

  @override
  Future<RoomResult?> getRoomResult(String roomId) async {
    final json = await _client.getJson('/api/v1/rooms/$roomId/results');
    final result = json['result'];
    if (result is! Map<String, dynamic>) {
      return null;
    }
    final items = (result['ranked_submissions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_submission)
        .toList(growable: false);
    ResultSubmission? current;
    final currentJson = result['current_user_submission'];
    if (currentJson is Map<String, dynamic>) {
      current = _submission(currentJson);
    }
    return RoomResult(
      roomId: result['room_id'] as String? ?? roomId,
      participantsCount: (result['participants_count'] as num?)?.toInt() ?? 0,
      submissionsCount: (result['submissions_count'] as num?)?.toInt() ?? 0,
      completionLabel: 'Голосование завершено',
      encouragementLabel:
          'Каждая работа — часть общей тренировки наблюдательности.',
      currentUserSubmission: current,
      rankedSubmissions: items,
    );
  }

  ResultSubmission _submission(Map<String, dynamic> json) {
    return ResultSubmission(
      id: json['id'] as String? ?? '',
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? 'Работа',
      authorLabel: json['author_label'] as String? ?? 'Участник',
      authorUserId: json['author_user_id'] as String? ?? '',
      wins: (json['wins'] as num?)?.toInt() ?? 0,
      comparisons: (json['comparisons'] as num?)?.toInt() ?? 0,
      paletteStart: 0xFF91B7A8,
      paletteEnd: 0xFF244D42,
      mediaUrl: json['media_url'] as String? ?? '',
      isCurrentUser: json['is_current_user'] as bool? ?? false,
    );
  }
}

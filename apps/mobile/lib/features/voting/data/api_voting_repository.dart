import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/voting/domain/vote_pair.dart';
import 'package:creative_gym_mobile/features/voting/domain/voting_repository.dart';

class ApiVotingRepository implements VotingRepository {
  const ApiVotingRepository(this._client);

  final ApiClient _client;

  @override
  Future<VotePair?> getNextPair(String roomId) async {
    final json = await _client.getJson('/api/v1/rooms/$roomId/votes/next-pair');
    final pair = json['pair'];
    if (pair is! Map<String, dynamic>) {
      return null;
    }
    final progress = json['progress'];
    final left = pair['left'] as Map<String, dynamic>? ?? const {};
    final right = pair['right'] as Map<String, dynamic>? ?? const {};
    final leftId = left['id'] as String? ?? '';
    final rightId = right['id'] as String? ?? '';
    return VotePair(
      id: '$leftId:$rightId',
      leftLabel: 'Фото слева',
      rightLabel: 'Фото справа',
      leftPalette: _leftFallback,
      rightPalette: _rightFallback,
      leftSubmissionId: leftId,
      rightSubmissionId: rightId,
      leftMediaUrl: left['media_url'] as String? ?? '',
      rightMediaUrl: right['media_url'] as String? ?? '',
      completed: progress is Map<String, dynamic>
          ? (progress['completed'] as num?)?.toInt() ?? 0
          : 0,
      target: progress is Map<String, dynamic>
          ? (progress['target'] as num?)?.toInt() ?? 0
          : 0,
    );
  }

  @override
  Future<void> castVote(
    String roomId,
    VotePair pair,
    String chosenSubmissionId,
  ) async {
    await _client.postJson(
      '/api/v1/rooms/$roomId/votes',
      body: {
        'left_submission_id': pair.leftSubmissionId,
        'right_submission_id': pair.rightSubmissionId,
        'chosen_submission_id': chosenSubmissionId,
      },
    );
  }

  @override
  Future<void> skip(String roomId, VotePair pair) async {}

  static const _leftFallback = VotePhotoPalette(
    start: 0xFFE8B96E,
    middle: 0xFF8ABBAA,
    end: 0xFF173F35,
  );
  static const _rightFallback = VotePhotoPalette(
    start: 0xFFAFCDF4,
    middle: 0xFF87A89B,
    end: 0xFF24334D,
  );
}

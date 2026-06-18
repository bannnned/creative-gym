import 'package:creative_gym_mobile/features/challenges/data/api_challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/data/mock_challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/domain/challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';

class FallbackChallengesRepository implements ChallengesRepository {
  FallbackChallengesRepository({
    required this._api,
    required this._mock,
  });

  final ApiChallengesRepository _api;
  final MockChallengesRepository _mock;

  @override
  Future<List<WeeklyWorkout>> getActiveWorkouts() async {
    try {
      return await _api.getActiveWorkouts();
    } catch (_) {
      return _mock.getActiveWorkouts();
    }
  }

  @override
  Future<WeeklyWorkout?> getWorkoutById(String challengeId) async {
    try {
      return await _api.getWorkoutById(challengeId);
    } catch (_) {
      return _mock.getWorkoutById(challengeId);
    }
  }

  @override
  Future<GymRoom> joinChallenge(String challengeId) async {
    try {
      return await _api.joinChallenge(challengeId);
    } catch (_) {
      return _mock.joinChallenge(challengeId);
    }
  }
}

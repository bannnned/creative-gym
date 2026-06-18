import 'package:creative_gym_mobile/features/challenges/data/mock_weekly_workouts.dart';
import 'package:creative_gym_mobile/features/challenges/domain/challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/features/rooms/data/mock_gym_rooms.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';

class MockChallengesRepository implements ChallengesRepository {
  const MockChallengesRepository();

  @override
  Future<List<WeeklyWorkout>> getActiveWorkouts() async {
    return mockWeeklyWorkouts;
  }

  @override
  Future<WeeklyWorkout?> getWorkoutById(String challengeId) async {
    return findMockWeeklyWorkoutById(challengeId);
  }

  @override
  Future<GymRoom> joinChallenge(String challengeId) async {
    final workout = await getWorkoutById(challengeId);
    if (workout == null || workout.roomId.isEmpty) {
      throw StateError('Challenge room is not available in mock data.');
    }

    final room = findMockGymRoomById(workout.roomId);
    if (room == null) {
      throw StateError('Mock room not found for challenge $challengeId.');
    }

    return room;
  }
}

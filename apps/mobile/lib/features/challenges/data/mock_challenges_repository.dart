import 'dart:typed_data';

import 'package:creative_gym_mobile/features/challenges/data/mock_weekly_workouts.dart';
import 'package:creative_gym_mobile/features/challenges/domain/challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/features/rooms/data/mock_gym_rooms.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';

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

  @override
  Future<Uint8List?> loadCover(WeeklyWorkout workout) async => null;

  @override
  Future<void> uploadCover(String challengeId, SelectedPhoto photo) async {
    throw UnsupportedError('Cover upload is unavailable in mock mode.');
  }
}

import 'dart:typed_data';

import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/submissions/domain/selected_photo.dart';

abstract class ChallengesRepository {
  Future<List<WeeklyWorkout>> getActiveWorkouts();

  Future<WeeklyWorkout?> getWorkoutById(String challengeId);

  Future<GymRoom> joinChallenge(String challengeId);

  Future<Uint8List?> loadCover(WeeklyWorkout workout);

  Future<void> uploadCover(String challengeId, SelectedPhoto photo);
}

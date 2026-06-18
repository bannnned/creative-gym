import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';

abstract class ChallengesRepository {
  Future<List<WeeklyWorkout>> getActiveWorkouts();

  Future<WeeklyWorkout?> getWorkoutById(String challengeId);

  Future<GymRoom> joinChallenge(String challengeId);
}

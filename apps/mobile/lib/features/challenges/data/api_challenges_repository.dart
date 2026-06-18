import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/challenges/data/dto/challenge_dto.dart';
import 'package:creative_gym_mobile/features/challenges/data/mappers/challenge_mapper.dart';
import 'package:creative_gym_mobile/features/challenges/domain/challenges_repository.dart';
import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';
import 'package:creative_gym_mobile/features/rooms/data/dto/room_dto.dart';
import 'package:creative_gym_mobile/features/rooms/data/mappers/room_mapper.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:dio/dio.dart';

class ApiChallengesRepository implements ChallengesRepository {
  const ApiChallengesRepository(this._client);

  final ApiClient _client;

  @override
  Future<List<WeeklyWorkout>> getActiveWorkouts() async {
    final json = await _getJson('/api/v1/challenges/active');
    final response = ActiveChallengesResponse.fromJson(json);
    return response.challenges
        .map(ChallengeMapper.toWeeklyWorkout)
        .toList(growable: false);
  }

  @override
  Future<WeeklyWorkout?> getWorkoutById(String challengeId) async {
    try {
      final json = await _getJson('/api/v1/challenges/$challengeId');
      final response = ChallengeDetailResponse.fromJson(json);
      return ChallengeMapper.toWeeklyWorkout(response.challenge);
    } on ApiException catch (error) {
      if (error.statusCode == 404) {
        return null;
      }

      rethrow;
    }
  }

  @override
  Future<GymRoom> joinChallenge(String challengeId) async {
    final json = await _postJson('/api/v1/challenges/$challengeId/join');
    final response = JoinChallengeResponse.fromJson(json);
    return RoomMapper.toGymRoom(response.room);
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    try {
      return await _client.getJson(path);
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  Future<Map<String, dynamic>> _postJson(String path) async {
    try {
      return await _client.postJson(path);
    } on DioException catch (error) {
      throw _unwrap(error);
    }
  }

  ApiException _unwrap(DioException error) {
    final wrapped = error.error;
    if (wrapped is ApiException) {
      return wrapped;
    }

    return ApiException(message: error.message ?? 'Request failed.');
  }
}

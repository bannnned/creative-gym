import 'package:creative_gym_mobile/core/errors/api_exception.dart';
import 'package:creative_gym_mobile/core/network/api_client.dart';
import 'package:creative_gym_mobile/features/rooms/data/dto/room_dto.dart';
import 'package:creative_gym_mobile/features/rooms/data/mappers/room_mapper.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/rooms/domain/rooms_repository.dart';
import 'package:dio/dio.dart';

class ApiRoomsRepository implements RoomsRepository {
  const ApiRoomsRepository(this._client);

  final ApiClient _client;

  @override
  Future<GymRoom?> getRoomById(String roomId) async {
    try {
      final json = await _client.getJson('/api/v1/rooms/$roomId');
      final response = RoomDetailResponse.fromJson(json);
      return RoomMapper.toGymRoom(response.room);
    } on DioException catch (error) {
      final wrapped = error.error;
      if (wrapped is ApiException && wrapped.statusCode == 404) {
        return null;
      }

      if (wrapped is ApiException) {
        throw wrapped;
      }

      throw ApiException(message: error.message ?? 'Request failed.');
    }
  }
}

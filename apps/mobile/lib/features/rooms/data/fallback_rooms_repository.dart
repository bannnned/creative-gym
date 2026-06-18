import 'package:creative_gym_mobile/features/rooms/data/api_rooms_repository.dart';
import 'package:creative_gym_mobile/features/rooms/data/mock_rooms_repository.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/rooms/domain/rooms_repository.dart';

class FallbackRoomsRepository implements RoomsRepository {
  FallbackRoomsRepository({
    required this._api,
    required this._mock,
  });

  final ApiRoomsRepository _api;
  final MockRoomsRepository _mock;

  @override
  Future<GymRoom?> getRoomById(String roomId) async {
    try {
      return await _api.getRoomById(roomId);
    } catch (_) {
      return _mock.getRoomById(roomId);
    }
  }
}

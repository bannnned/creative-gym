import 'package:creative_gym_mobile/features/rooms/data/mock_gym_rooms.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
import 'package:creative_gym_mobile/features/rooms/domain/rooms_repository.dart';

class MockRoomsRepository implements RoomsRepository {
  const MockRoomsRepository();

  @override
  Future<GymRoom?> getRoomById(String roomId) async {
    return findMockGymRoomById(roomId);
  }
}

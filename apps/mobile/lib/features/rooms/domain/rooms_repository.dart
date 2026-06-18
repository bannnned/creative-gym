import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';

abstract class RoomsRepository {
  Future<GymRoom?> getRoomById(String roomId);
}

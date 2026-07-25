import 'package:creative_gym_mobile/features/results/domain/room_result.dart';

abstract interface class ResultsRepository {
  Future<RoomResult?> getRoomResult(String roomId);
}

import 'package:creative_gym_mobile/features/results/data/mock_room_results.dart';
import 'package:creative_gym_mobile/features/results/domain/results_repository.dart';
import 'package:creative_gym_mobile/features/results/domain/room_result.dart';

class MockResultsRepository implements ResultsRepository {
  const MockResultsRepository();

  @override
  Future<RoomResult?> getRoomResult(String roomId) async {
    return findMockRoomResultByRoomId(roomId);
  }
}

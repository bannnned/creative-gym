import 'package:creative_gym_mobile/features/rooms/data/dto/room_dto.dart';
import 'package:creative_gym_mobile/features/rooms/data/mappers/room_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps persisted voting completion from the room response', () {
    final dto = RoomDto.fromJson({
      'id': 'room-1',
      'challenge_id': 'challenge-1',
      'challenge_title': 'Тест',
      'challenge_theme': 'Тема',
      'phase': 'voting',
      'participant_count': 4,
      'capacity': 16,
      'viewer_has_submission': true,
      'viewer_votes_completed': 3,
      'viewer_votes_target': 3,
      'submission_ends_at': '2026-07-26T10:00:00Z',
      'voting_ends_at': '2026-07-28T10:00:00Z',
    });

    final room = RoomMapper.toGymRoom(dto);

    expect(room.votingCompleted, 3);
    expect(room.votingTarget, 3);
    expect(room.hasCompletedVoting, isTrue);
  });
}

import 'package:creative_gym_mobile/features/challenges/data/dto/challenge_dto.dart';
import 'package:creative_gym_mobile/features/challenges/data/mappers/challenge_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps challenge dto into weekly workout domain model', () {
    final workout = ChallengeMapper.toWeeklyWorkout(
      ChallengeDto(
        id: 'challenge-1',
        kind: 'photo',
        title: 'Morning Light',
        theme: 'Light and Shadow',
        description: 'Find soft morning light.',
        rules: const ['Submit one photo.'],
        status: 'submitting',
        phase: 'submission',
        submissionStartsAt: DateTime.utc(2026, 6, 10),
        submissionEndsAt: DateTime.utc(2026, 6, 15),
        votingStartsAt: DateTime.utc(2026, 6, 15),
        votingEndsAt: DateTime.utc(2026, 6, 17),
        participantCount: 12,
        roomCapacity: 16,
        viewerRoomId: 'room-1',
        viewerHasJoined: true,
      ),
    );

    expect(workout.id, 'challenge-1');
    expect(workout.title, 'Morning Light');
    expect(workout.phase, 'Прием работ');
    expect(workout.roomId, 'room-1');
    expect(workout.isJoined, isTrue);
    expect(workout.participantsLabel, '12 участников');
  });
}

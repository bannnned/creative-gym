import 'package:creative_gym_mobile/core/utils/challenge_labels.dart';
import 'package:creative_gym_mobile/features/challenges/data/dto/challenge_dto.dart';
import 'package:creative_gym_mobile/features/challenges/data/mappers/challenge_mapper.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';
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
        coverUrl: '/api/v1/challenges/challenge-1/cover?v=1',
        viewerCanEdit: true,
      ),
    );

    expect(workout.id, 'challenge-1');
    expect(workout.title, 'Morning Light');
    expect(workout.phase, 'Прием работ');
    expect(workout.roomId, 'room-1');
    expect(workout.isJoined, isTrue);
    expect(workout.participantsLabel, '12 участников');
    expect(workout.coverUrl, contains('/cover'));
    expect(workout.viewerCanEdit, isTrue);
  });

  test('maps current API upcoming and results phase names', () {
    expect(weeklyWorkoutPhaseLabel('upcoming'), 'Скоро старт');
    expect(weeklyWorkoutPhaseLabel('results'), 'Результаты');
    expect(gymRoomPhaseFromApi('upcoming'), GymRoomPhase.upcoming);
    expect(gymRoomPhaseFromApi('results'), GymRoomPhase.results);
  });
}

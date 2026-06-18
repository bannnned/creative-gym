import 'package:creative_gym_mobile/core/utils/challenge_labels.dart';
import 'package:creative_gym_mobile/features/challenges/data/dto/challenge_dto.dart';
import 'package:creative_gym_mobile/features/challenges/domain/weekly_workout.dart';

class ChallengeMapper {
  const ChallengeMapper._();

  static WeeklyWorkout toWeeklyWorkout(ChallengeDto dto) {
    return WeeklyWorkout(
      id: dto.id,
      title: dto.title,
      theme: dto.theme,
      description: dto.description,
      phase: weeklyWorkoutPhaseLabel(dto.phase),
      submissionDeadlineLabel: deadlineLabelForPhase(
        apiPhase: dto.phase,
        submissionEndsAt: dto.submissionEndsAt,
        votingEndsAt: dto.votingEndsAt,
      ),
      submissionWindowLabel: submissionWindowLabel(
        dto.submissionStartsAt,
        dto.submissionEndsAt,
      ),
      votingWindowLabel: votingWindowLabel(
        dto.votingStartsAt,
        dto.votingEndsAt,
      ),
      participantsLabel: participantsLabel(dto.participantCount),
      roomSizeLabel: roomSizeLabel(dto.roomCapacity),
      roomId: dto.viewerRoomId ?? '',
      rules: dto.rules,
      isJoined: dto.viewerHasJoined,
    );
  }
}

import 'package:creative_gym_mobile/core/utils/challenge_labels.dart';
import 'package:creative_gym_mobile/features/rooms/data/dto/room_dto.dart';
import 'package:creative_gym_mobile/features/rooms/domain/gym_room.dart';

class RoomMapper {
  const RoomMapper._();

  static GymRoom toGymRoom(RoomDto dto) {
    final phase = gymRoomPhaseFromApi(dto.phase);
    final hasSubmission = dto.viewerHasSubmission;

    return GymRoom(
      id: dto.id,
      challengeId: dto.challengeId,
      challengeTitle: dto.challengeTitle,
      challengeTheme: dto.challengeTheme,
      phase: phase,
      deadlineLabel: deadlineLabelForPhase(
        apiPhase: dto.phase,
        submissionEndsAt: dto.submissionEndsAt,
        votingEndsAt: dto.votingEndsAt,
      ),
      participantCount: dto.participantCount,
      maxParticipants: dto.capacity,
      hasSubmission: hasSubmission,
      submissionStatusLabel: submissionStatusLabel(
        phase: phase,
        hasSubmission: hasSubmission,
      ),
      nextStepLabel: roomNextStepLabel(
        phase: phase,
        hasSubmission: hasSubmission,
      ),
    );
  }
}

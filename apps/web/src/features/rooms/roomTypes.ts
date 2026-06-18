import type { ChallengePhase } from '../challenges/challengeTypes';

export type Room = {
  id: string;
  challengeId: string;
  challengeTitle: string;
  challengeTheme: string;
  phase: ChallengePhase;
  participantCount: number;
  capacity: number;
  viewerHasSubmission: boolean;
  submissionEndsAt: string;
  votingEndsAt: string;
};

export type RoomDto = {
  id: string;
  challenge_id: string;
  challenge_title: string;
  challenge_theme: string;
  phase: ChallengePhase;
  participant_count: number;
  capacity: number;
  viewer_has_submission: boolean;
  submission_ends_at: string;
  voting_ends_at: string;
};

export function mapRoom(dto: RoomDto): Room {
  return {
    id: dto.id,
    challengeId: dto.challenge_id,
    challengeTitle: dto.challenge_title,
    challengeTheme: dto.challenge_theme,
    phase: dto.phase,
    participantCount: dto.participant_count,
    capacity: dto.capacity,
    viewerHasSubmission: dto.viewer_has_submission,
    submissionEndsAt: dto.submission_ends_at,
    votingEndsAt: dto.voting_ends_at
  };
}

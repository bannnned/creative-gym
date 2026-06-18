export type ChallengePhase = 'upcoming' | 'submission' | 'voting' | 'results';

export type Challenge = {
  id: string;
  kind: string;
  title: string;
  theme: string;
  description: string;
  rules: string[];
  status: string;
  phase: ChallengePhase;
  submissionStartsAt: string;
  submissionEndsAt: string;
  votingStartsAt: string;
  votingEndsAt: string;
  participantCount: number;
  roomCapacity: number;
  viewerRoomId: string | null;
  viewerHasJoined: boolean;
};

export type ChallengeDto = {
  id: string;
  kind: string;
  title: string;
  theme: string;
  description: string;
  rules: string[];
  status: string;
  phase: ChallengePhase;
  submission_starts_at: string;
  submission_ends_at: string;
  voting_starts_at: string;
  voting_ends_at: string;
  participant_count: number;
  room_capacity: number;
  viewer_room_id: string | null;
  viewer_has_joined: boolean;
};

export function mapChallenge(dto: ChallengeDto): Challenge {
  return {
    id: dto.id,
    kind: dto.kind,
    title: dto.title,
    theme: dto.theme,
    description: dto.description,
    rules: dto.rules,
    status: dto.status,
    phase: dto.phase,
    submissionStartsAt: dto.submission_starts_at,
    submissionEndsAt: dto.submission_ends_at,
    votingStartsAt: dto.voting_starts_at,
    votingEndsAt: dto.voting_ends_at,
    participantCount: dto.participant_count,
    roomCapacity: dto.room_capacity,
    viewerRoomId: dto.viewer_room_id,
    viewerHasJoined: dto.viewer_has_joined
  };
}

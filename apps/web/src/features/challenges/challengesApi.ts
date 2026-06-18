import { getJson, postJson } from '../../shared/api/client';
import { mapRoom, type Room, type RoomDto } from '../rooms/roomTypes';
import { mapChallenge, type Challenge, type ChallengeDto } from './challengeTypes';

type ChallengesResponse = {
  challenges: ChallengeDto[];
};

type ChallengeResponse = {
  challenge: ChallengeDto;
};

type JoinResponse = {
  room: RoomDto;
};

export async function listActiveChallenges(): Promise<Challenge[]> {
  const response = await getJson<ChallengesResponse>('/api/v1/challenges/active');
  return response.challenges.map(mapChallenge);
}

export async function getChallenge(challengeId: string): Promise<Challenge> {
  const response = await getJson<ChallengeResponse>(
    `/api/v1/challenges/${challengeId}`
  );
  return mapChallenge(response.challenge);
}

export async function joinChallenge(challengeId: string): Promise<Room> {
  const response = await postJson<JoinResponse>(
    `/api/v1/challenges/${challengeId}/join`
  );
  return mapRoom(response.room);
}

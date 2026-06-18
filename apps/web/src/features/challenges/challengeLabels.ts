import type { Challenge, ChallengePhase } from './challengeTypes';

export function phaseLabel(phase: ChallengePhase): string {
  switch (phase) {
    case 'upcoming':
      return 'Скоро';
    case 'submission':
      return 'Прием работ';
    case 'voting':
      return 'Голосование';
    case 'results':
      return 'Результаты';
  }
}

export function deadlineLabel(challenge: Challenge): string {
  if (challenge.phase === 'voting') {
    return `Голосование до ${formatDate(challenge.votingEndsAt)}`;
  }

  if (challenge.phase === 'results') {
    return 'Завершено';
  }

  return `Прием до ${formatDate(challenge.submissionEndsAt)}`;
}

export function formatDate(value: string): string {
  return new Intl.DateTimeFormat('ru-RU', {
    day: 'numeric',
    month: 'short'
  }).format(new Date(value));
}

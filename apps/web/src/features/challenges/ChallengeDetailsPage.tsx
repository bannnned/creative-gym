import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link, Navigate, useNavigate, useParams } from 'react-router-dom';
import { StatePanel } from '../../shared/ui/StatePanel';
import { deadlineLabel, formatDate, phaseLabel } from './challengeLabels';
import { getChallenge, joinChallenge } from './challengesApi';

export function ChallengeDetailsPage() {
  const { challengeId } = useParams();
  const navigate = useNavigate();
  const queryClient = useQueryClient();

  const challengeQuery = useQuery({
    queryKey: ['challenge', challengeId],
    queryFn: () => getChallenge(challengeId ?? ''),
    enabled: Boolean(challengeId)
  });

  const joinMutation = useMutation({
    mutationFn: () => joinChallenge(challengeId ?? ''),
    onSuccess: async (room) => {
      await queryClient.invalidateQueries({ queryKey: ['challenges'] });
      navigate(`/rooms/${room.id}`);
    }
  });

  if (!challengeId) {
    return <Navigate to="/challenges" replace />;
  }

  if (challengeQuery.isPending) {
    return <StatePanel title="Загружаем тренировку" />;
  }

  if (challengeQuery.isError) {
    return (
      <StatePanel
        title="Не удалось открыть тренировку"
        message={challengeQuery.error.message}
        action={{
          label: 'Повторить',
          onClick: () => void challengeQuery.refetch()
        }}
      />
    );
  }

  const challenge = challengeQuery.data;

  return (
    <section className="stack">
      <Link className="text-link" to="/challenges">
        Назад к Weekly Workouts
      </Link>

      <article className="detail-panel">
        <div className="detail-panel__header">
          <div>
            <p className="eyebrow">{challenge.theme}</p>
            <h1>{challenge.title}</h1>
          </div>
          <span className="status-pill">{phaseLabel(challenge.phase)}</span>
        </div>

        <p className="lead">{challenge.description}</p>

        <dl className="meta-grid large">
          <div>
            <dt>Прием работ</dt>
            <dd>
              {formatDate(challenge.submissionStartsAt)} -{' '}
              {formatDate(challenge.submissionEndsAt)}
            </dd>
          </div>
          <div>
            <dt>Голосование</dt>
            <dd>
              {formatDate(challenge.votingStartsAt)} -{' '}
              {formatDate(challenge.votingEndsAt)}
            </dd>
          </div>
          <div>
            <dt>Участники</dt>
            <dd>
              {challenge.participantCount}/{challenge.roomCapacity}
            </dd>
          </div>
          <div>
            <dt>Сейчас</dt>
            <dd>{deadlineLabel(challenge)}</dd>
          </div>
        </dl>

        <section className="rules-panel">
          <h2>Правила</h2>
          <ul>
            {challenge.rules.map((rule) => (
              <li key={rule}>{rule}</li>
            ))}
          </ul>
        </section>

        {challenge.viewerRoomId ? (
          <Link className="button primary" to={`/rooms/${challenge.viewerRoomId}`}>
            Открыть Gym Room
          </Link>
        ) : (
          <button
            className="button primary"
            type="button"
            disabled={joinMutation.isPending}
            onClick={() => joinMutation.mutate()}
          >
            {joinMutation.isPending ? 'Входим...' : 'Присоединиться'}
          </button>
        )}

        {joinMutation.isError ? (
          <p className="form-error">{joinMutation.error.message}</p>
        ) : null}
      </article>
    </section>
  );
}

import { useQuery } from '@tanstack/react-query';
import { Link } from 'react-router-dom';
import { StatePanel } from '../../shared/ui/StatePanel';
import { deadlineLabel, phaseLabel } from './challengeLabels';
import { listActiveChallenges } from './challengesApi';

export function ChallengesPage() {
  const challengesQuery = useQuery({
    queryKey: ['challenges', 'active'],
    queryFn: listActiveChallenges
  });

  if (challengesQuery.isPending) {
    return <StatePanel title="Загружаем Weekly Workouts" />;
  }

  if (challengesQuery.isError) {
    return (
      <StatePanel
        title="Не удалось загрузить тренировки"
        message={challengesQuery.error.message}
        action={{
          label: 'Повторить',
          onClick: () => void challengesQuery.refetch()
        }}
      />
    );
  }

  const challenges = challengesQuery.data;

  return (
    <section className="stack">
      <div className="page-heading">
        <p className="eyebrow">Weekly Workouts</p>
        <h1>Активные фото-тренировки</h1>
      </div>

      {challenges.length === 0 ? (
        <StatePanel
          title="Пока нет активных тренировок"
          message="Новые задания появятся здесь."
        />
      ) : (
        <div className="challenge-list">
          {challenges.map((challenge) => (
            <article className="challenge-card" key={challenge.id}>
              <div className="challenge-card__media">
                <span>{phaseLabel(challenge.phase)}</span>
              </div>
              <div className="challenge-card__body">
                <div>
                  <p className="eyebrow">{challenge.theme}</p>
                  <h2>{challenge.title}</h2>
                  <p>{challenge.description}</p>
                </div>
                <dl className="meta-grid">
                  <div>
                    <dt>Дедлайн</dt>
                    <dd>{deadlineLabel(challenge)}</dd>
                  </div>
                  <div>
                    <dt>Комната</dt>
                    <dd>
                      {challenge.participantCount}/{challenge.roomCapacity}
                    </dd>
                  </div>
                </dl>
                <Link
                  className="button primary"
                  to={
                    challenge.viewerRoomId
                      ? `/rooms/${challenge.viewerRoomId}`
                      : `/challenges/${challenge.id}`
                  }
                >
                  {challenge.viewerHasJoined ? 'Открыть Gym Room' : 'Подробнее'}
                </Link>
              </div>
            </article>
          ))}
        </div>
      )}
    </section>
  );
}

import { useQuery } from '@tanstack/react-query';
import { Link, Navigate, useParams } from 'react-router-dom';
import { phaseLabel, formatDate } from '../challenges/challengeLabels';
import { StatePanel } from '../../shared/ui/StatePanel';
import { getRoom } from './roomsApi';

export function RoomPage() {
  const { roomId } = useParams();

  const roomQuery = useQuery({
    queryKey: ['room', roomId],
    queryFn: () => getRoom(roomId ?? ''),
    enabled: Boolean(roomId)
  });

  if (!roomId) {
    return <Navigate to="/challenges" replace />;
  }

  if (roomQuery.isPending) {
    return <StatePanel title="Загружаем Gym Room" />;
  }

  if (roomQuery.isError) {
    return (
      <StatePanel
        title="Не удалось открыть комнату"
        message={roomQuery.error.message}
        action={{
          label: 'Повторить',
          onClick: () => void roomQuery.refetch()
        }}
      />
    );
  }

  const room = roomQuery.data;

  return (
    <section className="stack">
      <Link className="text-link" to={`/challenges/${room.challengeId}`}>
        Назад к тренировке
      </Link>

      <article className="detail-panel">
        <div className="detail-panel__header">
          <div>
            <p className="eyebrow">{room.challengeTheme}</p>
            <h1>{room.challengeTitle}</h1>
          </div>
          <span className="status-pill">{phaseLabel(room.phase)}</span>
        </div>

        <dl className="meta-grid large">
          <div>
            <dt>Комната</dt>
            <dd>
              {room.participantCount}/{room.capacity}
            </dd>
          </div>
          <div>
            <dt>Прием работ</dt>
            <dd>до {formatDate(room.submissionEndsAt)}</dd>
          </div>
          <div>
            <dt>Голосование</dt>
            <dd>до {formatDate(room.votingEndsAt)}</dd>
          </div>
          <div>
            <dt>Фото</dt>
            <dd>{room.viewerHasSubmission ? 'Загружено' : 'Не загружено'}</dd>
          </div>
        </dl>

        <section className="room-action-panel">
          <h2>{room.viewerHasSubmission ? 'Фото принято' : 'Одна фотография'}</h2>
          <p>
            {room.phase === 'submission'
              ? 'Загрузка будет подключена следующим шагом через S3.'
              : 'Действие для этой фазы появится вместе с полным MVP loop.'}
          </p>
          <button className="button secondary" type="button" disabled>
            {room.viewerHasSubmission ? 'Заменить фото' : 'Добавить фото'}
          </button>
        </section>
      </article>
    </section>
  );
}

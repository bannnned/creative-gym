import { useEffect, useState, type ChangeEvent } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { Link, Navigate, useParams } from 'react-router-dom';
import { phaseLabel, formatDate } from '../challenges/challengeLabels';
import { StatePanel } from '../../shared/ui/StatePanel';
import { getRoom } from './roomsApi';
import {
  deleteSubmission,
  getMySubmission,
  submissionMediaUrl,
  uploadSubmission
} from './submissionsApi';

const maxPhotoBytes = 10 * 1024 * 1024;

export function RoomPage() {
  const { roomId } = useParams();
  const queryClient = useQueryClient();
  const [selectedPhoto, setSelectedPhoto] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [formError, setFormError] = useState<string | null>(null);

  const roomQuery = useQuery({
    queryKey: ['room', roomId],
    queryFn: () => getRoom(roomId ?? ''),
    enabled: Boolean(roomId)
  });

  const submissionQuery = useQuery({
    queryKey: ['submission', roomId],
    queryFn: () => getMySubmission(roomId ?? ''),
    enabled: Boolean(roomId)
  });

  const uploadMutation = useMutation({
    mutationFn: (photo: File) => uploadSubmission(roomId ?? '', photo),
    onSuccess: async () => {
      setSelectedPhoto(null);
      setFormError(null);
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: ['room', roomId] }),
        queryClient.invalidateQueries({ queryKey: ['submission', roomId] })
      ]);
    },
    onError: (error) => {
      setFormError(error instanceof Error ? error.message : 'Не удалось загрузить фото.');
    }
  });

  const deleteMutation = useMutation({
    mutationFn: (submissionId: string) => deleteSubmission(submissionId),
    onSuccess: async () => {
      setFormError(null);
      await Promise.all([
        queryClient.invalidateQueries({ queryKey: ['room', roomId] }),
        queryClient.invalidateQueries({ queryKey: ['submission', roomId] })
      ]);
    },
    onError: (error) => {
      setFormError(error instanceof Error ? error.message : 'Не удалось удалить фото.');
    }
  });

  useEffect(() => {
    if (!selectedPhoto) {
      setPreviewUrl(null);
      return;
    }

    const objectUrl = URL.createObjectURL(selectedPhoto);
    setPreviewUrl(objectUrl);

    return () => URL.revokeObjectURL(objectUrl);
  }, [selectedPhoto]);

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
  const submission = submissionQuery.data ?? null;
  const canUpload = room.phase === 'submission';
  const isBusy = uploadMutation.isPending || deleteMutation.isPending;

  function handlePhotoChange(event: ChangeEvent<HTMLInputElement>) {
    const file = event.target.files?.[0] ?? null;
    setFormError(null);

    if (!file) {
      setSelectedPhoto(null);
      return;
    }

    if (!['image/jpeg', 'image/png', 'image/webp'].includes(file.type)) {
      setSelectedPhoto(null);
      setFormError('Подойдет JPEG, PNG или WebP.');
      return;
    }

    if (file.size > maxPhotoBytes) {
      setSelectedPhoto(null);
      setFormError('Фото должно быть не больше 10 МБ.');
      return;
    }

    setSelectedPhoto(file);
  }

  function handleSubmit() {
    if (!selectedPhoto) {
      setFormError('Выбери фото перед загрузкой.');
      return;
    }

    uploadMutation.mutate(selectedPhoto);
  }

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
            <dd>{submission ? 'Загружено' : 'Не загружено'}</dd>
          </div>
        </dl>

        <section className="room-action-panel">
          <div>
            <h2>{submission ? 'Фото принято' : 'Одна фотография'}</h2>
            <p>
              {canUpload
                ? 'Можно загрузить, удалить или заменить фото до окончания приема работ.'
                : 'Прием работ для этой комнаты сейчас закрыт.'}
            </p>
          </div>

          {submission && (
            <figure className="submission-preview">
              <img src={submissionMediaUrl(submission)} alt="Загруженное фото" />
              <figcaption>{formatBytes(submission.byteSize)}</figcaption>
            </figure>
          )}

          {canUpload && (
            <div className="submission-form">
              <label className="file-picker">
                <input
                  type="file"
                  accept="image/jpeg,image/png,image/webp"
                  onChange={handlePhotoChange}
                  disabled={isBusy}
                />
                <span>{selectedPhoto ? selectedPhoto.name : 'Выбрать фото'}</span>
              </label>

              {previewUrl && (
                <figure className="submission-preview pending">
                  <img src={previewUrl} alt="Предпросмотр выбранного фото" />
                  <figcaption>{selectedPhoto ? formatBytes(selectedPhoto.size) : ''}</figcaption>
                </figure>
              )}

              {formError && <p className="form-error">{formError}</p>}

              <div className="submission-actions">
                <button
                  className="button primary"
                  type="button"
                  onClick={handleSubmit}
                  disabled={!selectedPhoto || isBusy}
                >
                  {uploadMutation.isPending
                    ? 'Загружаем...'
                    : submission
                      ? 'Заменить фото'
                      : 'Добавить фото'}
                </button>
                {submission && (
                  <button
                    className="button secondary"
                    type="button"
                    onClick={() => deleteMutation.mutate(submission.id)}
                    disabled={isBusy}
                  >
                    {deleteMutation.isPending ? 'Удаляем...' : 'Удалить'}
                  </button>
                )}
              </div>
            </div>
          )}

          {submissionQuery.isError && (
            <p className="form-error">{submissionQuery.error.message}</p>
          )}
        </section>
      </article>
    </section>
  );
}

function formatBytes(bytes: number): string {
  if (bytes < 1024 * 1024) {
    return `${Math.max(1, Math.round(bytes / 1024))} КБ`;
  }

  return `${(bytes / 1024 / 1024).toFixed(1)} МБ`;
}

package submissions

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) GetMine(ctx context.Context, roomID string, userID string) (*Submission, error) {
	if err := ensureRoomMember(ctx, r.pool, roomID, userID); err != nil {
		return nil, err
	}

	var submission Submission
	err := r.pool.QueryRow(ctx, `
SELECT
  s.id::text,
  s.room_id::text,
  s.user_id::text,
  m.content_type,
  m.byte_size,
  s.created_at,
  s.updated_at
FROM submissions s
JOIN LATERAL (
  SELECT content_type, byte_size
  FROM media_objects
  WHERE submission_id = s.id
    AND status = 'uploaded'
    AND deleted_at IS NULL
  ORDER BY created_at DESC
  LIMIT 1
) m ON true
WHERE s.room_id = $1
  AND s.user_id = $2
  AND s.status = 'active'
  AND s.deleted_at IS NULL`, roomID, userID).Scan(
		&submission.ID,
		&submission.RoomID,
		&submission.UserID,
		&submission.ContentType,
		&submission.ByteSize,
		&submission.CreatedAt,
		&submission.UpdatedAt,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}

		return nil, fmt.Errorf("query own submission: %w", err)
	}

	return &submission, nil
}

func (r *Repository) UpsertMine(ctx context.Context, roomID string, userID string, media MediaObject) (Submission, []ObjectRef, error) {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted})
	if err != nil {
		return Submission{}, nil, fmt.Errorf("begin submission transaction: %w", err)
	}
	defer rollback(ctx, tx)

	if err := ensureSubmissionOpen(ctx, tx, roomID, userID); err != nil {
		return Submission{}, nil, err
	}

	var submission Submission
	err = tx.QueryRow(ctx, `
INSERT INTO submissions (room_id, user_id, status, deleted_at, updated_at)
VALUES ($1, $2, 'active', NULL, now())
ON CONFLICT (room_id, user_id)
DO UPDATE SET
  status = 'active',
  deleted_at = NULL,
  updated_at = now()
RETURNING id::text, room_id::text, user_id::text, created_at, updated_at`, roomID, userID).Scan(
		&submission.ID,
		&submission.RoomID,
		&submission.UserID,
		&submission.CreatedAt,
		&submission.UpdatedAt,
	)
	if err != nil {
		return Submission{}, nil, fmt.Errorf("upsert submission: %w", err)
	}

	replacedObjects, err := markActiveMediaDeleted(ctx, tx, submission.ID)
	if err != nil {
		return Submission{}, nil, err
	}

	err = tx.QueryRow(ctx, `
INSERT INTO media_objects (
  submission_id,
  kind,
  bucket,
  object_key,
  content_type,
  byte_size,
  status
)
VALUES ($1, 'image', $2, $3, $4, $5, 'uploaded')
RETURNING content_type, byte_size`, submission.ID, media.Bucket, media.ObjectKey, media.ContentType, media.ByteSize).Scan(
		&submission.ContentType,
		&submission.ByteSize,
	)
	if err != nil {
		return Submission{}, nil, fmt.Errorf("insert media object: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return Submission{}, nil, fmt.Errorf("commit submission transaction: %w", err)
	}

	return submission, replacedObjects, nil
}

func markActiveMediaDeleted(ctx context.Context, tx pgx.Tx, submissionID string) ([]ObjectRef, error) {
	rows, err := tx.Query(ctx, `
UPDATE media_objects
SET status = 'deleted', deleted_at = now()
WHERE submission_id = $1
  AND status = 'uploaded'
  AND deleted_at IS NULL
RETURNING bucket, object_key`, submissionID)
	if err != nil {
		return nil, fmt.Errorf("mark previous media deleted: %w", err)
	}
	defer rows.Close()

	objects := make([]ObjectRef, 0)
	for rows.Next() {
		var object ObjectRef
		if err := rows.Scan(&object.Bucket, &object.ObjectKey); err != nil {
			return nil, fmt.Errorf("scan previous media object: %w", err)
		}

		objects = append(objects, object)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate previous media objects: %w", err)
	}

	return objects, nil
}

func (r *Repository) DeleteMine(ctx context.Context, submissionID string, userID string) ([]ObjectRef, error) {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted})
	if err != nil {
		return nil, fmt.Errorf("begin delete submission transaction: %w", err)
	}
	defer rollback(ctx, tx)

	var roomID string
	err = tx.QueryRow(ctx, `
SELECT room_id::text
FROM submissions
WHERE id = $1
  AND user_id = $2
  AND status = 'active'
  AND deleted_at IS NULL
FOR UPDATE`, submissionID, userID).Scan(&roomID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrSubmissionNotFound
		}

		return nil, fmt.Errorf("query submission for delete: %w", err)
	}

	if err := ensureSubmissionOpen(ctx, tx, roomID, userID); err != nil {
		return nil, err
	}

	rows, err := tx.Query(ctx, `
SELECT bucket, object_key
FROM media_objects
WHERE submission_id = $1
  AND status = 'uploaded'
  AND deleted_at IS NULL`, submissionID)
	if err != nil {
		return nil, fmt.Errorf("query media objects for delete: %w", err)
	}

	objects, err := pgx.CollectRows(rows, pgx.RowToStructByName[ObjectRef])
	if err != nil {
		return nil, fmt.Errorf("collect media objects for delete: %w", err)
	}

	_, err = tx.Exec(ctx, `
UPDATE media_objects
SET status = 'deleted', deleted_at = now()
WHERE submission_id = $1
  AND deleted_at IS NULL`, submissionID)
	if err != nil {
		return nil, fmt.Errorf("mark media deleted: %w", err)
	}

	_, err = tx.Exec(ctx, `
UPDATE submissions
SET status = 'deleted', deleted_at = now(), updated_at = now()
WHERE id = $1`, submissionID)
	if err != nil {
		return nil, fmt.Errorf("mark submission deleted: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit delete submission transaction: %w", err)
	}

	return objects, nil
}

func (r *Repository) GetMineMedia(ctx context.Context, submissionID string, userID string) (MediaObject, error) {
	var media MediaObject
	err := r.pool.QueryRow(ctx, `
SELECT
  s.id::text,
  m.bucket,
  m.object_key,
  m.content_type,
  m.byte_size
FROM submissions s
JOIN media_objects m ON m.submission_id = s.id
WHERE s.id = $1
  AND s.user_id = $2
  AND s.status = 'active'
  AND s.deleted_at IS NULL
  AND m.status = 'uploaded'
  AND m.deleted_at IS NULL
ORDER BY m.created_at DESC
LIMIT 1`, submissionID, userID).Scan(
		&media.SubmissionID,
		&media.Bucket,
		&media.ObjectKey,
		&media.ContentType,
		&media.ByteSize,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return MediaObject{}, ErrMediaNotFound
		}

		return MediaObject{}, fmt.Errorf("query own submission media: %w", err)
	}

	return media, nil
}

type queryer interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func ensureRoomMember(ctx context.Context, queryer queryer, roomID string, userID string) error {
	var exists bool
	err := queryer.QueryRow(ctx, `
SELECT EXISTS (
  SELECT 1
  FROM room_members
  WHERE room_id = $1 AND user_id = $2
)`, roomID, userID).Scan(&exists)
	if err != nil {
		return fmt.Errorf("check room membership: %w", err)
	}

	if !exists {
		return ErrRoomNotFound
	}

	return nil
}

func ensureSubmissionOpen(ctx context.Context, queryer queryer, roomID string, userID string) error {
	var isOpen bool
	err := queryer.QueryRow(ctx, `
SELECT now() >= c.submission_starts_at AND now() < c.submission_ends_at
FROM rooms r
JOIN challenges c ON c.id = r.challenge_id
JOIN room_members rm ON rm.room_id = r.id AND rm.user_id = $2
WHERE r.id = $1`, roomID, userID).Scan(&isOpen)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrRoomNotFound
		}

		return fmt.Errorf("check submission window: %w", err)
	}

	if !isOpen {
		return ErrSubmissionClosed
	}

	return nil
}

func rollback(ctx context.Context, tx pgx.Tx) {
	if err := tx.Rollback(ctx); err != nil && !errors.Is(err, pgx.ErrTxClosed) {
		return
	}
}

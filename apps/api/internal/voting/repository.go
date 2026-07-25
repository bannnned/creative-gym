package voting

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) NextPair(ctx context.Context, roomID string, userID string) (*Pair, error) {
	progress, err := r.progress(ctx, roomID, userID)
	if err != nil {
		return nil, err
	}
	if progress.Target == 0 || progress.Completed >= progress.Target {
		return nil, nil
	}

	var pair Pair
	err = r.pool.QueryRow(ctx, `
WITH eligible AS (
  SELECT s.id
  FROM submissions s
  WHERE s.room_id = $1
    AND s.user_id <> $2
    AND s.status = 'active'
    AND s.deleted_at IS NULL
    AND EXISTS (
      SELECT 1
      FROM media_objects m
      WHERE m.submission_id = s.id
        AND m.status = 'uploaded'
        AND m.deleted_at IS NULL
    )
),
pairs AS (
  SELECT left_submission.id AS left_id, right_submission.id AS right_id
  FROM eligible left_submission
  JOIN eligible right_submission ON left_submission.id < right_submission.id
)
SELECT left_id::text, right_id::text
FROM pairs
WHERE NOT EXISTS (
  SELECT 1
  FROM votes v
  WHERE v.room_id = $1
    AND v.voter_user_id = $2
    AND v.left_submission_id = pairs.left_id
    AND v.right_submission_id = pairs.right_id
)
ORDER BY random()
LIMIT 1`, roomID, userID).Scan(&pair.Left.ID, &pair.Right.ID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}
		return nil, fmt.Errorf("query next vote pair: %w", err)
	}

	pair.Progress = progress
	return &pair, nil
}

func (r *Repository) CastVote(
	ctx context.Context,
	roomID string,
	userID string,
	leftSubmissionID string,
	rightSubmissionID string,
	chosenSubmissionID string,
) (Progress, error) {
	if leftSubmissionID == rightSubmissionID ||
		(chosenSubmissionID != leftSubmissionID && chosenSubmissionID != rightSubmissionID) {
		return Progress{}, ErrInvalidPair
	}
	if rightSubmissionID < leftSubmissionID {
		leftSubmissionID, rightSubmissionID = rightSubmissionID, leftSubmissionID
	}

	progress, err := r.progress(ctx, roomID, userID)
	if err != nil {
		return Progress{}, err
	}
	if progress.Target == 0 || progress.Completed >= progress.Target {
		return Progress{}, ErrVotingComplete
	}

	var valid bool
	err = r.pool.QueryRow(ctx, `
SELECT count(*) = 2
FROM submissions s
WHERE s.room_id = $1
  AND s.id = ANY($2::uuid[])
  AND s.user_id <> $3
  AND s.status = 'active'
  AND s.deleted_at IS NULL
  AND EXISTS (
    SELECT 1
    FROM media_objects m
    WHERE m.submission_id = s.id
      AND m.status = 'uploaded'
      AND m.deleted_at IS NULL
  )`, roomID, []string{leftSubmissionID, rightSubmissionID}, userID).Scan(&valid)
	if err != nil {
		return Progress{}, fmt.Errorf("validate vote pair: %w", err)
	}
	if !valid {
		return Progress{}, ErrInvalidPair
	}

	_, err = r.pool.Exec(ctx, `
INSERT INTO votes (
  room_id,
  voter_user_id,
  left_submission_id,
  right_submission_id,
  chosen_submission_id
)
VALUES ($1, $2, $3, $4, $5)`,
		roomID,
		userID,
		leftSubmissionID,
		rightSubmissionID,
		chosenSubmissionID,
	)
	if err != nil {
		if isUniqueViolation(err) {
			return Progress{}, ErrAlreadyVoted
		}
		return Progress{}, fmt.Errorf("insert vote: %w", err)
	}

	return r.progress(ctx, roomID, userID)
}

func (r *Repository) progress(ctx context.Context, roomID string, userID string) (Progress, error) {
	var isOpen bool
	var eligibleCount int
	var completed int
	err := r.pool.QueryRow(ctx, `
SELECT
  now() >= c.voting_starts_at AND now() < c.voting_ends_at,
  (
    SELECT count(*)::int
    FROM submissions s
    WHERE s.room_id = r.id
      AND s.user_id <> $2
      AND s.status = 'active'
      AND s.deleted_at IS NULL
      AND EXISTS (
        SELECT 1
        FROM media_objects m
        WHERE m.submission_id = s.id
          AND m.status = 'uploaded'
          AND m.deleted_at IS NULL
      )
  ),
  (
    SELECT count(*)::int
    FROM votes v
    WHERE v.room_id = r.id AND v.voter_user_id = $2
  )
FROM rooms r
JOIN challenges c ON c.id = r.challenge_id
JOIN room_members rm ON rm.room_id = r.id AND rm.user_id = $2
WHERE r.id = $1`, roomID, userID).Scan(&isOpen, &eligibleCount, &completed)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Progress{}, ErrRoomNotFound
		}
		return Progress{}, fmt.Errorf("query voting progress: %w", err)
	}
	if !isOpen {
		return Progress{}, ErrVotingClosed
	}

	target := eligibleCount * (eligibleCount - 1) / 2
	if target > MaxVotesPerUser {
		target = MaxVotesPerUser
	}
	return Progress{Completed: completed, Target: target}, nil
}

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}

package rooms

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

var (
	ErrChallengeNotFound = errors.New("challenge not found")
	ErrRoomNotFound      = errors.New("room not found")
)

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) JoinChallenge(ctx context.Context, challengeID string, userID string) (Room, error) {
	tx, err := r.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.ReadCommitted})
	if err != nil {
		return Room{}, fmt.Errorf("begin join challenge transaction: %w", err)
	}
	defer rollback(ctx, tx)

	if err := ensureJoinableChallenge(ctx, tx, challengeID); err != nil {
		return Room{}, err
	}

	existingRoomID, err := findExistingRoomID(ctx, tx, challengeID, userID)
	if err != nil {
		return Room{}, err
	}

	if existingRoomID != nil {
		room, err := getRoomByID(ctx, tx, *existingRoomID, userID)
		if err != nil {
			return Room{}, err
		}

		if err := tx.Commit(ctx); err != nil {
			return Room{}, fmt.Errorf("commit existing room join transaction: %w", err)
		}

		return room, nil
	}

	roomID, err := findOpenRoomID(ctx, tx, challengeID)
	if err != nil {
		return Room{}, err
	}

	if roomID == nil {
		createdRoomID, err := createRoom(ctx, tx, challengeID)
		if err != nil {
			return Room{}, err
		}
		roomID = &createdRoomID
	}

	inserted, err := insertRoomMember(ctx, tx, *roomID, challengeID, userID)
	if err != nil {
		return Room{}, err
	}

	if !inserted {
		existingRoomID, err := findExistingRoomID(ctx, tx, challengeID, userID)
		if err != nil {
			return Room{}, err
		}

		if existingRoomID == nil {
			return Room{}, fmt.Errorf("room membership conflict did not resolve to an existing room")
		}

		roomID = existingRoomID
	}

	room, err := getRoomByID(ctx, tx, *roomID, userID)
	if err != nil {
		return Room{}, err
	}

	if err := tx.Commit(ctx); err != nil {
		return Room{}, fmt.Errorf("commit join challenge transaction: %w", err)
	}

	return room, nil
}

func (r *Repository) GetByID(ctx context.Context, roomID string, viewerUserID string) (Room, error) {
	room, err := getRoomByID(ctx, r.pool, roomID, viewerUserID)
	if err != nil {
		return Room{}, err
	}

	return room, nil
}

func ensureJoinableChallenge(ctx context.Context, tx pgx.Tx, challengeID string) error {
	var exists bool
	err := tx.QueryRow(ctx, `
SELECT EXISTS (
  SELECT 1
  FROM challenges
  WHERE id = $1 AND status IN ('scheduled', 'submitting', 'voting')
)`, challengeID).Scan(&exists)
	if err != nil {
		return fmt.Errorf("check challenge joinability: %w", err)
	}

	if !exists {
		return ErrChallengeNotFound
	}

	return nil
}

func findExistingRoomID(ctx context.Context, tx pgx.Tx, challengeID string, userID string) (*string, error) {
	var roomID string
	err := tx.QueryRow(ctx, `
SELECT room_id::text
FROM room_members
WHERE challenge_id = $1 AND user_id = $2
LIMIT 1`, challengeID, userID).Scan(&roomID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}

		return nil, fmt.Errorf("query existing room membership: %w", err)
	}

	return &roomID, nil
}

func findOpenRoomID(ctx context.Context, tx pgx.Tx, challengeID string) (*string, error) {
	var roomID string
	err := tx.QueryRow(ctx, `
SELECT r.id::text
FROM rooms r
WHERE r.challenge_id = $1 AND r.status = 'open'
  AND (
    SELECT count(*)
    FROM room_members rm
    WHERE rm.room_id = r.id
  ) < r.capacity
ORDER BY r.created_at ASC
LIMIT 1
FOR UPDATE SKIP LOCKED`, challengeID).Scan(&roomID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, nil
		}

		return nil, fmt.Errorf("query open room: %w", err)
	}

	return &roomID, nil
}

func createRoom(ctx context.Context, tx pgx.Tx, challengeID string) (string, error) {
	var roomID string
	err := tx.QueryRow(ctx, `
INSERT INTO rooms (challenge_id, status, capacity)
VALUES ($1, 'open', 16)
RETURNING id::text`, challengeID).Scan(&roomID)
	if err != nil {
		return "", fmt.Errorf("create room: %w", err)
	}

	return roomID, nil
}

func insertRoomMember(ctx context.Context, tx pgx.Tx, roomID string, challengeID string, userID string) (bool, error) {
	_, err := tx.Exec(ctx, `
INSERT INTO room_members (room_id, challenge_id, user_id)
VALUES ($1, $2, $3)`, roomID, challengeID, userID)
	if err != nil {
		if isUniqueViolation(err) {
			return false, nil
		}

		return false, fmt.Errorf("insert room member: %w", err)
	}

	return true, nil
}

type roomQueryer interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func getRoomByID(ctx context.Context, queryer roomQueryer, roomID string, viewerUserID string) (Room, error) {
	var room Room
	err := queryer.QueryRow(ctx, `
SELECT
  r.id::text,
  c.id::text,
  c.title,
  c.theme,
  c.submission_starts_at,
  c.submission_ends_at,
  c.voting_starts_at,
  c.voting_ends_at,
  (
    SELECT count(*)::int
    FROM room_members rm
    WHERE rm.room_id = r.id
  ) AS participant_count,
  r.capacity,
  EXISTS (
    SELECT 1
    FROM submissions s
    WHERE s.room_id = r.id
      AND s.user_id = $2
      AND s.status = 'active'
      AND s.deleted_at IS NULL
  ) AS viewer_has_submission
FROM rooms r
JOIN challenges c ON c.id = r.challenge_id
WHERE r.id = $1`, roomID, viewerUserID).Scan(
		&room.ID,
		&room.ChallengeID,
		&room.ChallengeTitle,
		&room.ChallengeTheme,
		&room.SubmissionStartsAt,
		&room.SubmissionEndsAt,
		&room.VotingStartsAt,
		&room.VotingEndsAt,
		&room.ParticipantCount,
		&room.Capacity,
		&room.ViewerHasSubmission,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Room{}, ErrRoomNotFound
		}

		return Room{}, fmt.Errorf("query room by id: %w", err)
	}

	return room, nil
}

func isUniqueViolation(err error) bool {
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}

func rollback(ctx context.Context, tx pgx.Tx) {
	if err := tx.Rollback(ctx); err != nil && !errors.Is(err, pgx.ErrTxClosed) {
		// Commit closes the transaction too; rollback after commit is expected to fail.
		return
	}
}

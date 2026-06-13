package challenges

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrNotFound = errors.New("challenge not found")

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) ListActive(ctx context.Context, viewerUserID string) ([]Challenge, error) {
	rows, err := r.pool.Query(ctx, challengeSelectSQL(`
WHERE c.status IN ('scheduled', 'submitting', 'voting')
ORDER BY c.submission_starts_at ASC
`), viewerUserID)
	if err != nil {
		return nil, fmt.Errorf("query active challenges: %w", err)
	}
	defer rows.Close()

	challenges, err := scanChallenges(rows)
	if err != nil {
		return nil, err
	}

	return challenges, nil
}

func (r *Repository) GetByID(ctx context.Context, challengeID string, viewerUserID string) (Challenge, error) {
	row := r.pool.QueryRow(ctx, challengeSelectSQL(`
WHERE c.id = $2
`), viewerUserID, challengeID)

	challenge, err := scanChallenge(row)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Challenge{}, ErrNotFound
		}

		return Challenge{}, fmt.Errorf("query challenge by id: %w", err)
	}

	return challenge, nil
}

func challengeSelectSQL(whereClause string) string {
	return `
SELECT
  c.id::text,
  c.kind,
  c.title,
  c.theme,
  c.description,
  c.rules,
  c.status,
  c.submission_starts_at,
  c.submission_ends_at,
  c.voting_starts_at,
  c.voting_ends_at,
  (
    SELECT count(*)::int
    FROM rooms r
    JOIN room_members rm ON rm.room_id = r.id
    WHERE r.challenge_id = c.id
  ) AS participant_count,
  COALESCE((
    SELECT r.capacity
    FROM rooms r
    WHERE r.challenge_id = c.id
    ORDER BY r.created_at ASC
    LIMIT 1
  ), 16) AS room_capacity,
  (
    SELECT r.id::text
    FROM rooms r
    JOIN room_members rm ON rm.room_id = r.id
    WHERE r.challenge_id = c.id AND rm.user_id = $1
    ORDER BY rm.joined_at ASC
    LIMIT 1
  ) AS viewer_room_id
FROM challenges c
` + whereClause
}

type challengeScanner interface {
	Scan(dest ...any) error
}

func scanChallenges(rows pgx.Rows) ([]Challenge, error) {
	challenges := make([]Challenge, 0)
	for rows.Next() {
		challenge, err := scanChallenge(rows)
		if err != nil {
			return nil, err
		}

		challenges = append(challenges, challenge)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate challenges: %w", err)
	}

	return challenges, nil
}

func scanChallenge(row challengeScanner) (Challenge, error) {
	var challenge Challenge
	var rulesJSON []byte

	err := row.Scan(
		&challenge.ID,
		&challenge.Kind,
		&challenge.Title,
		&challenge.Theme,
		&challenge.Description,
		&rulesJSON,
		&challenge.Status,
		&challenge.SubmissionStartsAt,
		&challenge.SubmissionEndsAt,
		&challenge.VotingStartsAt,
		&challenge.VotingEndsAt,
		&challenge.ParticipantCount,
		&challenge.RoomCapacity,
		&challenge.ViewerRoomID,
	)
	if err != nil {
		return Challenge{}, err
	}

	if err := json.Unmarshal(rulesJSON, &challenge.Rules); err != nil {
		return Challenge{}, fmt.Errorf("decode challenge rules: %w", err)
	}

	challenge.ViewerHasJoined = challenge.ViewerRoomID != nil
	return challenge, nil
}

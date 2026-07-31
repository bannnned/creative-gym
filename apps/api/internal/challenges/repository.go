package challenges

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrNotFound = errors.New("challenge not found")

type Mutation struct {
	Title              string
	Theme              string
	Description        string
	Rules              []string
	SubmissionStartsAt time.Time
	SubmissionEndsAt   time.Time
	VotingStartsAt     time.Time
	VotingEndsAt       time.Time
}

func (m Mutation) Validate() error {
	if strings.TrimSpace(m.Title) == "" {
		return errors.New("title is required")
	}
	if strings.TrimSpace(m.Theme) == "" {
		return errors.New("theme is required")
	}
	if strings.TrimSpace(m.Description) == "" {
		return errors.New("description is required")
	}
	if !m.SubmissionStartsAt.Before(m.SubmissionEndsAt) {
		return errors.New("submission start must be before submission end")
	}
	if m.VotingStartsAt.Before(m.SubmissionEndsAt) {
		return errors.New("voting cannot start before submissions end")
	}
	if !m.VotingStartsAt.Before(m.VotingEndsAt) {
		return errors.New("voting start must be before voting end")
	}

	return nil
}

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) ListActive(ctx context.Context, viewerUserID string) ([]Challenge, error) {
	rows, err := r.pool.Query(ctx, challengeSelectSQL(`
WHERE c.status <> 'cancelled'
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
  c.created_by_user_id::text,
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
  viewer_room.id,
  cc.updated_at AS cover_updated_at,
  (
    COALESCE(c.created_by_user_id = $1, false)
    OR EXISTS (
      SELECT 1 FROM users viewer
      WHERE viewer.id = $1 AND viewer.is_admin = true
    )
  ) AS viewer_can_edit,
  COALESCE(viewer_room.has_submission, false) AS viewer_has_submission,
  COALESCE(viewer_room.eligible_submission_count > 1, false)
    AS viewer_has_voting_options,
  COALESCE(
    viewer_room.eligible_submission_count > 1
    AND viewer_room.votes_completed >= LEAST(
      10,
      viewer_room.eligible_submission_count
        * (viewer_room.eligible_submission_count - 1) / 2
    ),
    false
  ) AS viewer_has_completed_voting
FROM challenges c
LEFT JOIN challenge_covers cc ON cc.challenge_id = c.id
LEFT JOIN LATERAL (
  SELECT
    r.id::text AS id,
    EXISTS (
      SELECT 1
      FROM submissions s
      WHERE s.room_id = r.id
        AND s.user_id = $1
        AND s.status = 'active'
        AND s.deleted_at IS NULL
    ) AS has_submission,
    (
      SELECT count(*)::int
      FROM votes v
      WHERE v.room_id = r.id
        AND v.voter_user_id = $1
    ) AS votes_completed,
    (
      SELECT count(*)::int
      FROM submissions s
      WHERE s.room_id = r.id
        AND s.user_id <> $1
        AND s.status = 'active'
        AND s.deleted_at IS NULL
        AND EXISTS (
          SELECT 1
          FROM media_objects m
          WHERE m.submission_id = s.id
            AND m.status = 'uploaded'
            AND m.deleted_at IS NULL
        )
    ) AS eligible_submission_count
  FROM rooms r
  JOIN room_members rm ON rm.room_id = r.id AND rm.user_id = $1
  WHERE r.challenge_id = c.id
  ORDER BY rm.joined_at ASC
  LIMIT 1
) viewer_room ON true
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
		&challenge.CreatedByUserID,
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
		&challenge.CoverUpdatedAt,
		&challenge.ViewerCanEdit,
		&challenge.ViewerHasSubmission,
		&challenge.ViewerHasVotingOptions,
		&challenge.ViewerHasCompletedVoting,
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

func (r *Repository) Create(
	ctx context.Context,
	createdByUserID string,
	mutation Mutation,
) (Challenge, error) {
	if err := mutation.Validate(); err != nil {
		return Challenge{}, err
	}

	rulesJSON, err := json.Marshal(mutation.Rules)
	if err != nil {
		return Challenge{}, fmt.Errorf("encode challenge rules: %w", err)
	}

	var challengeID string
	err = r.pool.QueryRow(ctx, `
INSERT INTO challenges (
  created_by_user_id,
  kind,
  title,
  theme,
  description,
  rules,
  status,
  submission_starts_at,
  submission_ends_at,
  voting_starts_at,
  voting_ends_at
)
VALUES ($1, 'photo', $2, $3, $4, $5, $6, $7, $8, $9, $10)
RETURNING id::text
`,
		createdByUserID,
		strings.TrimSpace(mutation.Title),
		strings.TrimSpace(mutation.Theme),
		strings.TrimSpace(mutation.Description),
		rulesJSON,
		statusAt(time.Now(), mutation),
		mutation.SubmissionStartsAt,
		mutation.SubmissionEndsAt,
		mutation.VotingStartsAt,
		mutation.VotingEndsAt,
	).Scan(&challengeID)
	if err != nil {
		return Challenge{}, fmt.Errorf("create challenge: %w", err)
	}

	return r.GetByID(ctx, challengeID, createdByUserID)
}

func (r *Repository) Update(
	ctx context.Context,
	challengeID string,
	viewerUserID string,
	mutation Mutation,
) (Challenge, error) {
	if err := mutation.Validate(); err != nil {
		return Challenge{}, err
	}

	rulesJSON, err := json.Marshal(mutation.Rules)
	if err != nil {
		return Challenge{}, fmt.Errorf("encode challenge rules: %w", err)
	}

	command, err := r.pool.Exec(ctx, `
UPDATE challenges
SET
  title = $3,
  theme = $4,
  description = $5,
  rules = $6,
  status = $7,
  submission_starts_at = $8,
  submission_ends_at = $9,
  voting_starts_at = $10,
  voting_ends_at = $11,
  updated_at = now()
WHERE id = $1
  AND EXISTS (
    SELECT 1 FROM users
    WHERE id = $2 AND is_admin = true
  )
`,
		challengeID,
		viewerUserID,
		strings.TrimSpace(mutation.Title),
		strings.TrimSpace(mutation.Theme),
		strings.TrimSpace(mutation.Description),
		rulesJSON,
		statusAt(time.Now(), mutation),
		mutation.SubmissionStartsAt,
		mutation.SubmissionEndsAt,
		mutation.VotingStartsAt,
		mutation.VotingEndsAt,
	)
	if err != nil {
		return Challenge{}, fmt.Errorf("update challenge: %w", err)
	}
	if command.RowsAffected() != 1 {
		return Challenge{}, ErrNotFound
	}

	return r.GetByID(ctx, challengeID, viewerUserID)
}

func (r *Repository) Archive(
	ctx context.Context,
	challengeID string,
	viewerUserID string,
) error {
	command, err := r.pool.Exec(ctx, `
UPDATE challenges
SET status = 'cancelled', updated_at = now()
WHERE id = $1
  AND EXISTS (
    SELECT 1 FROM users
    WHERE id = $2 AND is_admin = true
  )
`, challengeID, viewerUserID)
	if err != nil {
		return fmt.Errorf("archive challenge: %w", err)
	}
	if command.RowsAffected() != 1 {
		return ErrNotFound
	}

	return nil
}

func statusAt(now time.Time, mutation Mutation) string {
	switch {
	case now.Before(mutation.SubmissionStartsAt):
		return "scheduled"
	case now.Before(mutation.SubmissionEndsAt):
		return "submitting"
	case now.Before(mutation.VotingEndsAt):
		return "voting"
	default:
		return "finished"
	}
}

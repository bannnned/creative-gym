package results

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

func (r *Repository) GetRoomResult(ctx context.Context, roomID string, userID string) (RoomResult, error) {
	var result RoomResult
	var ready bool
	err := r.pool.QueryRow(ctx, `
SELECT
  r.id::text,
  c.title,
  now() >= c.voting_ends_at,
  (SELECT count(*)::int FROM room_members rm2 WHERE rm2.room_id = r.id)
FROM rooms r
JOIN challenges c ON c.id = r.challenge_id
JOIN room_members rm ON rm.room_id = r.id AND rm.user_id = $2
WHERE r.id = $1`, roomID, userID).Scan(
		&result.RoomID,
		&result.ChallengeTitle,
		&ready,
		&result.ParticipantsCount,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return RoomResult{}, ErrRoomNotFound
		}
		return RoomResult{}, fmt.Errorf("query result room: %w", err)
	}
	if !ready {
		return RoomResult{}, ErrResultsPending
	}

	rows, err := r.pool.Query(ctx, rankedSubmissionsSQL, roomID, userID)
	if err != nil {
		return RoomResult{}, fmt.Errorf("query ranked submissions: %w", err)
	}
	defer rows.Close()

	for rows.Next() {
		var item SubmissionResult
		if err := rows.Scan(
			&item.ID,
			&item.Title,
			&item.AuthorLabel,
			&item.Wins,
			&item.Comparisons,
			&item.Rank,
			&item.IsCurrentUser,
		); err != nil {
			return RoomResult{}, fmt.Errorf("scan ranked submission: %w", err)
		}
		result.RankedSubmissions = append(result.RankedSubmissions, item)
		if item.IsCurrentUser {
			current := item
			result.CurrentSubmission = &current
		}
	}
	if err := rows.Err(); err != nil {
		return RoomResult{}, fmt.Errorf("iterate ranked submissions: %w", err)
	}
	result.SubmissionsCount = len(result.RankedSubmissions)
	return result, nil
}

const rankedSubmissionsSQL = `
WITH scored AS (
  SELECT
    s.id,
    s.user_id,
    c.title,
    u.display_name,
    count(v.id) FILTER (WHERE v.chosen_submission_id = s.id)::int AS wins,
    count(v.id) FILTER (
      WHERE v.left_submission_id = s.id OR v.right_submission_id = s.id
    )::int AS comparisons,
    s.created_at
  FROM submissions s
  JOIN users u ON u.id = s.user_id
  JOIN rooms r ON r.id = s.room_id
  JOIN challenges c ON c.id = r.challenge_id
  JOIN media_objects m ON m.submission_id = s.id
    AND m.status = 'uploaded'
    AND m.deleted_at IS NULL
  LEFT JOIN votes v ON v.room_id = s.room_id
    AND (v.left_submission_id = s.id OR v.right_submission_id = s.id)
  WHERE s.room_id = $1
    AND s.status = 'active'
    AND s.deleted_at IS NULL
  GROUP BY s.id, s.user_id, c.title, u.display_name, s.created_at
),
ranked AS (
  SELECT
    *,
    row_number() OVER (
      ORDER BY
        CASE WHEN comparisons = 0 THEN 0 ELSE wins::numeric / comparisons END DESC,
        comparisons DESC,
        wins DESC,
        created_at ASC,
        id ASC
    )::int AS rank
  FROM scored
)
SELECT
  id::text,
  title,
  display_name,
  wins,
  comparisons,
  rank,
  user_id = $2
FROM ranked
ORDER BY rank`

func (r *Repository) GetProfile(ctx context.Context, userID string) (Profile, error) {
	rows, err := r.pool.Query(ctx, `
WITH scored AS (
  SELECT
    s.id,
    s.room_id,
    s.user_id,
    c.title,
    c.voting_ends_at,
    count(v.id) FILTER (WHERE v.chosen_submission_id = s.id)::int AS wins,
    count(v.id) FILTER (
      WHERE v.left_submission_id = s.id OR v.right_submission_id = s.id
    )::int AS comparisons,
    s.created_at
  FROM submissions s
  JOIN rooms r ON r.id = s.room_id
  JOIN challenges c ON c.id = r.challenge_id
  JOIN media_objects m ON m.submission_id = s.id
    AND m.status = 'uploaded'
    AND m.deleted_at IS NULL
  LEFT JOIN votes v ON v.room_id = s.room_id
    AND (v.left_submission_id = s.id OR v.right_submission_id = s.id)
  WHERE s.status = 'active' AND s.deleted_at IS NULL
  GROUP BY s.id, s.room_id, s.user_id, c.title, c.voting_ends_at, s.created_at
),
ranked AS (
  SELECT
    *,
    row_number() OVER (
      PARTITION BY room_id
      ORDER BY
        CASE WHEN comparisons = 0 THEN 0 ELSE wins::numeric / comparisons END DESC,
        comparisons DESC,
        wins DESC,
        created_at ASC,
        id ASC
    )::int AS rank
  FROM scored
)
SELECT
  id::text,
  title,
  CASE
    WHEN now() >= voting_ends_at AND comparisons > 0 THEN rank
    ELSE NULL
  END,
  now() >= voting_ends_at
FROM ranked
WHERE user_id = $1
ORDER BY created_at DESC`, userID)
	if err != nil {
		return Profile{}, fmt.Errorf("query profile works: %w", err)
	}
	defer rows.Close()

	var profile Profile
	for rows.Next() {
		var work ProfileWork
		if err := rows.Scan(&work.ID, &work.Title, &work.Place, &work.Finished); err != nil {
			return Profile{}, fmt.Errorf("scan profile work: %w", err)
		}
		profile.Works = append(profile.Works, work)
		profile.Points += pointsForWork(work)
		if work.Place != nil {
			switch *work.Place {
			case 1:
				profile.FirstPlaces++
			case 2:
				profile.SecondPlaces++
			case 3:
				profile.ThirdPlaces++
			}
		}
	}
	if err := rows.Err(); err != nil {
		return Profile{}, fmt.Errorf("iterate profile works: %w", err)
	}
	return profile, nil
}

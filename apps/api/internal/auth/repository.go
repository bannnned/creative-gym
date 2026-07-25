package auth

import (
	"context"
	"errors"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrSessionNotFound = errors.New("session not found")

type GuestSession struct {
	UserID      string
	DisplayName string
	ExpiresAt   time.Time
}

type SessionRepository interface {
	CreateGuestSession(
		ctx context.Context,
		displayName string,
		tokenHash string,
		expiresAt time.Time,
	) (GuestSession, error)
	UserIDByTokenHash(ctx context.Context, tokenHash string) (string, error)
}

type Repository struct {
	pool *pgxpool.Pool
}

func NewRepository(pool *pgxpool.Pool) *Repository {
	return &Repository{pool: pool}
}

func (r *Repository) CreateGuestSession(
	ctx context.Context,
	displayName string,
	tokenHash string,
	expiresAt time.Time,
) (GuestSession, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return GuestSession{}, fmt.Errorf("begin guest session transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	var userID string
	err = tx.QueryRow(ctx, `
INSERT INTO users (display_name)
VALUES ($1)
RETURNING id::text
`, displayName).Scan(&userID)
	if err != nil {
		return GuestSession{}, fmt.Errorf("create guest user: %w", err)
	}

	_, err = tx.Exec(ctx, `
INSERT INTO sessions (user_id, token_hash, expires_at)
VALUES ($1::uuid, $2, $3)
`, userID, tokenHash, expiresAt)
	if err != nil {
		return GuestSession{}, fmt.Errorf("create guest session: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return GuestSession{}, fmt.Errorf("commit guest session transaction: %w", err)
	}

	return GuestSession{
		UserID:      userID,
		DisplayName: displayName,
		ExpiresAt:   expiresAt,
	}, nil
}

func (r *Repository) UserIDByTokenHash(
	ctx context.Context,
	tokenHash string,
) (string, error) {
	var userID string
	err := r.pool.QueryRow(ctx, `
SELECT user_id::text
FROM sessions
WHERE token_hash = $1
  AND revoked_at IS NULL
  AND expires_at > now()
`, tokenHash).Scan(&userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", ErrSessionNotFound
		}

		return "", fmt.Errorf("find session: %w", err)
	}

	return userID, nil
}

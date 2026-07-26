package results

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"
)

const avatarStoragePrefix = "s3:"

func (r *Repository) GetAvatar(
	ctx context.Context,
	userID string,
) (AvatarMedia, error) {
	var avatarSource string
	err := r.pool.QueryRow(ctx, `
SELECT COALESCE(avatar_url, '')
FROM users
WHERE id = $1`, userID).Scan(&avatarSource)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return AvatarMedia{}, ErrAvatarNotFound
		}
		return AvatarMedia{}, fmt.Errorf("query avatar: %w", err)
	}
	if !strings.HasPrefix(avatarSource, avatarStoragePrefix) {
		return AvatarMedia{}, ErrAvatarNotFound
	}

	objectKey := strings.TrimPrefix(avatarSource, avatarStoragePrefix)
	if objectKey == "" {
		return AvatarMedia{}, ErrAvatarNotFound
	}
	return AvatarMedia{ObjectKey: objectKey}, nil
}

func (r *Repository) UpsertAvatar(
	ctx context.Context,
	userID string,
	media AvatarMedia,
) (*AvatarObjectRef, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin avatar transaction: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	var previousSource string
	err = tx.QueryRow(ctx, `
SELECT COALESCE(avatar_url, '')
FROM users
WHERE id = $1
FOR UPDATE`, userID).Scan(&previousSource)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, ErrProfileNotFound
		}
		return nil, fmt.Errorf("query previous avatar: %w", err)
	}

	_, err = tx.Exec(ctx, `
UPDATE users
SET avatar_url = $2, updated_at = now()
WHERE id = $1`, userID, avatarStoragePrefix+media.ObjectKey)
	if err != nil {
		return nil, fmt.Errorf("update avatar: %w", err)
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit avatar transaction: %w", err)
	}

	if !strings.HasPrefix(previousSource, avatarStoragePrefix) {
		return nil, nil
	}
	previousKey := strings.TrimPrefix(previousSource, avatarStoragePrefix)
	if previousKey == "" {
		return nil, nil
	}
	return &AvatarObjectRef{ObjectKey: previousKey}, nil
}

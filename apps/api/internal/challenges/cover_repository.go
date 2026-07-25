package challenges

import (
	"context"
	"errors"
	"fmt"

	"github.com/jackc/pgx/v5"
)

func (r *Repository) GetCover(
	ctx context.Context,
	challengeID string,
) (CoverMedia, error) {
	var media CoverMedia
	err := r.pool.QueryRow(ctx, `
SELECT
  challenge_id::text,
  bucket,
  object_key,
  content_type,
  byte_size
FROM challenge_covers
WHERE challenge_id = $1`, challengeID).Scan(
		&media.ChallengeID,
		&media.Bucket,
		&media.ObjectKey,
		&media.ContentType,
		&media.ByteSize,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return CoverMedia{}, ErrCoverNotFound
		}
		return CoverMedia{}, fmt.Errorf("query challenge cover: %w", err)
	}

	return media, nil
}

func (r *Repository) UpsertCover(
	ctx context.Context,
	challengeID string,
	userID string,
	media CoverMedia,
) (*CoverObjectRef, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return nil, fmt.Errorf("begin cover transaction: %w", err)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	if err := ensureCoverAuthor(ctx, tx, challengeID, userID); err != nil {
		return nil, err
	}

	var replaced CoverObjectRef
	hasReplaced := true
	err = tx.QueryRow(ctx, `
SELECT bucket, object_key
FROM challenge_covers
WHERE challenge_id = $1
FOR UPDATE`, challengeID).Scan(
		&replaced.Bucket,
		&replaced.ObjectKey,
	)
	if err != nil {
		if !errors.Is(err, pgx.ErrNoRows) {
			return nil, fmt.Errorf("query previous challenge cover: %w", err)
		}
		hasReplaced = false
	}

	_, err = tx.Exec(ctx, `
INSERT INTO challenge_covers (
  challenge_id,
  bucket,
  object_key,
  content_type,
  byte_size,
  uploaded_by_user_id
)
VALUES ($1, $2, $3, $4, $5, $6)
ON CONFLICT (challenge_id)
DO UPDATE SET
  bucket = EXCLUDED.bucket,
  object_key = EXCLUDED.object_key,
  content_type = EXCLUDED.content_type,
  byte_size = EXCLUDED.byte_size,
  uploaded_by_user_id = EXCLUDED.uploaded_by_user_id,
  updated_at = now()`,
		challengeID,
		media.Bucket,
		media.ObjectKey,
		media.ContentType,
		media.ByteSize,
		userID,
	)
	if err != nil {
		return nil, fmt.Errorf("upsert challenge cover: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return nil, fmt.Errorf("commit cover transaction: %w", err)
	}

	if !hasReplaced {
		return nil, nil
	}
	return &replaced, nil
}

func (r *Repository) DeleteCover(
	ctx context.Context,
	challengeID string,
	userID string,
) (CoverObjectRef, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return CoverObjectRef{}, fmt.Errorf(
			"begin delete cover transaction: %w",
			err,
		)
	}
	defer func() {
		_ = tx.Rollback(ctx)
	}()

	if err := ensureCoverAuthor(ctx, tx, challengeID, userID); err != nil {
		return CoverObjectRef{}, err
	}

	var object CoverObjectRef
	err = tx.QueryRow(ctx, `
DELETE FROM challenge_covers
WHERE challenge_id = $1
RETURNING bucket, object_key`, challengeID).Scan(
		&object.Bucket,
		&object.ObjectKey,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return CoverObjectRef{}, ErrCoverNotFound
		}
		return CoverObjectRef{}, fmt.Errorf("delete challenge cover: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return CoverObjectRef{}, fmt.Errorf(
			"commit delete cover transaction: %w",
			err,
		)
	}

	return object, nil
}

type coverAuthorQueryer interface {
	QueryRow(ctx context.Context, sql string, args ...any) pgx.Row
}

func ensureCoverAuthor(
	ctx context.Context,
	queryer coverAuthorQueryer,
	challengeID string,
	userID string,
) error {
	var createdByUserID *string
	err := queryer.QueryRow(ctx, `
SELECT created_by_user_id::text
FROM challenges
WHERE id = $1
FOR UPDATE`, challengeID).Scan(&createdByUserID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return ErrNotFound
		}
		return fmt.Errorf("query challenge author: %w", err)
	}

	if createdByUserID == nil || *createdByUserID != userID {
		return ErrCoverForbidden
	}
	return nil
}

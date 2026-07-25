package challenges

import (
	"bytes"
	"context"
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"net/http"
	"path"
	"time"

	"creative-gym/apps/api/internal/auth"
	"creative-gym/apps/api/internal/storage"
)

const MaxCoverBytes int64 = 5 * 1024 * 1024

var (
	ErrCoverNotFound  = errors.New("challenge cover not found")
	ErrCoverForbidden = errors.New("challenge cover edit forbidden")
)

type CoverMedia struct {
	ChallengeID string
	Bucket      string
	ObjectKey   string
	ContentType string
	ByteSize    int64
}

type CoverObjectRef struct {
	Bucket    string
	ObjectKey string
}

type CoverStore interface {
	GetCover(ctx context.Context, challengeID string) (CoverMedia, error)
	UpsertCover(
		ctx context.Context,
		challengeID string,
		userID string,
		media CoverMedia,
	) (*CoverObjectRef, error)
	DeleteCover(
		ctx context.Context,
		challengeID string,
		userID string,
	) (CoverObjectRef, error)
}

type ObjectStore interface {
	Bucket() string
	Put(
		ctx context.Context,
		key string,
		body io.Reader,
		contentType string,
		byteSize int64,
	) error
	Get(ctx context.Context, bucket string, key string) (storage.Object, error)
	Delete(ctx context.Context, bucket string, key string) error
}

type coverResponse struct {
	CoverURL string `json:"cover_url"`
}

func (h *Handler) GetCover(w http.ResponseWriter, r *http.Request) {
	if h.objects == nil {
		h.writeAPIError(
			w,
			http.StatusServiceUnavailable,
			"object_storage_not_configured",
			"Object storage is not configured.",
		)
		return
	}

	challengeID := r.PathValue("challengeId")
	if challengeID == "" {
		h.writeAPIError(
			w,
			http.StatusBadRequest,
			"challenge_id_required",
			"Challenge id is required.",
		)
		return
	}

	store, ok := h.store.(CoverStore)
	if !ok {
		h.writeAPIError(
			w,
			http.StatusServiceUnavailable,
			"cover_store_unavailable",
			"Challenge covers are unavailable.",
		)
		return
	}

	media, err := store.GetCover(r.Context(), challengeID)
	if err != nil {
		if errors.Is(err, ErrCoverNotFound) {
			h.writeAPIError(
				w,
				http.StatusNotFound,
				"cover_not_found",
				"Challenge cover not found.",
			)
			return
		}

		h.writeAPIError(
			w,
			http.StatusInternalServerError,
			"cover_load_failed",
			"Failed to load challenge cover.",
		)
		return
	}

	object, err := h.objects.Get(r.Context(), media.Bucket, media.ObjectKey)
	if err != nil {
		h.writeAPIError(
			w,
			http.StatusBadGateway,
			"cover_fetch_failed",
			"Failed to fetch challenge cover.",
		)
		return
	}
	defer object.Body.Close()

	contentType := object.ContentType
	if contentType == "" {
		contentType = media.ContentType
	}
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Cache-Control", "private, max-age=31536000, immutable")
	if object.ContentLength > 0 {
		w.Header().Set(
			"Content-Length",
			fmt.Sprintf("%d", object.ContentLength),
		)
	}
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, object.Body)
}

func (h *Handler) UploadCover(w http.ResponseWriter, r *http.Request) {
	if h.objects == nil {
		h.writeAPIError(
			w,
			http.StatusServiceUnavailable,
			"object_storage_not_configured",
			"Object storage is not configured.",
		)
		return
	}

	challengeID := r.PathValue("challengeId")
	if challengeID == "" {
		h.writeAPIError(
			w,
			http.StatusBadRequest,
			"challenge_id_required",
			"Challenge id is required.",
		)
		return
	}

	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(
			w,
			http.StatusUnauthorized,
			"user_required",
			"User is required.",
		)
		return
	}

	store, ok := h.store.(CoverStore)
	if !ok {
		h.writeAPIError(
			w,
			http.StatusServiceUnavailable,
			"cover_store_unavailable",
			"Challenge covers are unavailable.",
		)
		return
	}

	fileBytes, contentType, err := readCoverUpload(w, r)
	if err != nil {
		h.writeAPIError(w, http.StatusBadRequest, "invalid_cover", err.Error())
		return
	}

	objectKey, err := newCoverObjectKey(challengeID, contentType)
	if err != nil {
		h.writeAPIError(
			w,
			http.StatusInternalServerError,
			"cover_key_failed",
			"Failed to prepare challenge cover.",
		)
		return
	}

	if err := h.objects.Put(
		r.Context(),
		objectKey,
		bytes.NewReader(fileBytes),
		contentType,
		int64(len(fileBytes)),
	); err != nil {
		h.writeAPIError(
			w,
			http.StatusBadGateway,
			"cover_upload_failed",
			"Failed to upload challenge cover.",
		)
		return
	}

	replaced, err := store.UpsertCover(
		r.Context(),
		challengeID,
		userID,
		CoverMedia{
			ChallengeID: challengeID,
			Bucket:      h.objects.Bucket(),
			ObjectKey:   objectKey,
			ContentType: contentType,
			ByteSize:    int64(len(fileBytes)),
		},
	)
	if err != nil {
		_ = h.objects.Delete(
			context.Background(),
			h.objects.Bucket(),
			objectKey,
		)

		switch {
		case errors.Is(err, ErrNotFound):
			h.writeAPIError(
				w,
				http.StatusNotFound,
				"challenge_not_found",
				"Challenge not found.",
			)
		case errors.Is(err, ErrCoverForbidden):
			h.writeAPIError(
				w,
				http.StatusForbidden,
				"cover_edit_forbidden",
				"Only the challenge author can change its cover.",
			)
		default:
			h.writeAPIError(
				w,
				http.StatusInternalServerError,
				"cover_save_failed",
				"Failed to save challenge cover.",
			)
		}
		return
	}

	if replaced != nil {
		_ = h.objects.Delete(
			context.Background(),
			replaced.Bucket,
			replaced.ObjectKey,
		)
	}

	h.writeJSON(
		w,
		http.StatusCreated,
		coverResponse{
			CoverURL: fmt.Sprintf(
				"/api/v1/challenges/%s/cover?v=%d",
				challengeID,
				time.Now().UTC().UnixNano(),
			),
		},
	)
}

func (h *Handler) DeleteCover(w http.ResponseWriter, r *http.Request) {
	if h.objects == nil {
		h.writeAPIError(
			w,
			http.StatusServiceUnavailable,
			"object_storage_not_configured",
			"Object storage is not configured.",
		)
		return
	}

	challengeID := r.PathValue("challengeId")
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(
			w,
			http.StatusUnauthorized,
			"user_required",
			"User is required.",
		)
		return
	}

	store, ok := h.store.(CoverStore)
	if !ok {
		h.writeAPIError(
			w,
			http.StatusServiceUnavailable,
			"cover_store_unavailable",
			"Challenge covers are unavailable.",
		)
		return
	}

	object, err := store.DeleteCover(r.Context(), challengeID, userID)
	if err != nil {
		switch {
		case errors.Is(err, ErrNotFound),
			errors.Is(err, ErrCoverNotFound):
			h.writeAPIError(
				w,
				http.StatusNotFound,
				"cover_not_found",
				"Challenge cover not found.",
			)
		case errors.Is(err, ErrCoverForbidden):
			h.writeAPIError(
				w,
				http.StatusForbidden,
				"cover_edit_forbidden",
				"Only the challenge author can remove its cover.",
			)
		default:
			h.writeAPIError(
				w,
				http.StatusInternalServerError,
				"cover_delete_failed",
				"Failed to remove challenge cover.",
			)
		}
		return
	}

	_ = h.objects.Delete(
		context.Background(),
		object.Bucket,
		object.ObjectKey,
	)
	w.WriteHeader(http.StatusNoContent)
}

func readCoverUpload(
	w http.ResponseWriter,
	r *http.Request,
) ([]byte, string, error) {
	const maxMultipartOverhead int64 = 1024 * 1024
	r.Body = http.MaxBytesReader(
		w,
		r.Body,
		MaxCoverBytes+maxMultipartOverhead,
	)
	if err := r.ParseMultipartForm(MaxCoverBytes + 1024); err != nil {
		return nil, "", errors.New(
			"Upload must be a multipart form with a cover field.",
		)
	}

	file, header, err := r.FormFile("cover")
	if err != nil {
		return nil, "", errors.New("Cover file is required.")
	}
	defer file.Close()

	if header.Size <= 0 {
		return nil, "", errors.New("Cover file is empty.")
	}
	if header.Size > MaxCoverBytes {
		return nil, "", errors.New("Cover must be 5 MB or smaller.")
	}

	data, err := io.ReadAll(io.LimitReader(file, MaxCoverBytes+1))
	if err != nil {
		return nil, "", errors.New("Failed to read cover.")
	}
	if int64(len(data)) > MaxCoverBytes {
		return nil, "", errors.New("Cover must be 5 MB or smaller.")
	}

	contentType := http.DetectContentType(data)
	if contentType != "image/jpeg" &&
		contentType != "image/png" &&
		contentType != "image/webp" {
		return nil, "", errors.New("Cover must be JPEG, PNG, or WebP.")
	}

	return data, contentType, nil
}

func newCoverObjectKey(challengeID string, contentType string) (string, error) {
	randomBytes := make([]byte, 16)
	if _, err := rand.Read(randomBytes); err != nil {
		return "", err
	}

	extension := map[string]string{
		"image/jpeg": ".jpg",
		"image/png":  ".png",
		"image/webp": ".webp",
	}[contentType]

	return path.Join(
		"challenge-covers",
		challengeID,
		time.Now().UTC().Format("20060102T150405Z")+
			"-"+hex.EncodeToString(randomBytes)+extension,
	), nil
}

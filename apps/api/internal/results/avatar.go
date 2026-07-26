package results

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

const MaxAvatarBytes int64 = 3 * 1024 * 1024

type AvatarMedia struct {
	ObjectKey   string
	ContentType string
	ByteSize    int64
}

type AvatarObjectRef struct {
	ObjectKey string
}

type AvatarStore interface {
	GetAvatar(ctx context.Context, userID string) (AvatarMedia, error)
	UpsertAvatar(
		ctx context.Context,
		userID string,
		media AvatarMedia,
	) (*AvatarObjectRef, error)
}

type AvatarObjectStore interface {
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

type avatarResponse struct {
	AvatarURL string `json:"avatar_url"`
}

func (h *Handler) WithObjectStore(objects AvatarObjectStore) {
	h.objects = objects
}

func (h *Handler) GetAvatar(w http.ResponseWriter, r *http.Request) {
	if h.objects == nil {
		h.writeAPIError(w, http.StatusServiceUnavailable, "object_storage_not_configured", "Object storage is not configured.")
		return
	}
	userID := r.PathValue("userId")
	if userID == "" {
		h.writeAPIError(w, http.StatusBadRequest, "user_id_required", "User id is required.")
		return
	}
	store, ok := h.store.(AvatarStore)
	if !ok {
		h.writeAPIError(w, http.StatusServiceUnavailable, "avatar_store_unavailable", "Avatars are unavailable.")
		return
	}
	media, err := store.GetAvatar(r.Context(), userID)
	if err != nil {
		if errors.Is(err, ErrAvatarNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "avatar_not_found", "Avatar not found.")
			return
		}
		h.writeAPIError(w, http.StatusInternalServerError, "avatar_load_failed", "Failed to load avatar.")
		return
	}
	object, err := h.objects.Get(r.Context(), h.objects.Bucket(), media.ObjectKey)
	if err != nil {
		h.writeAPIError(w, http.StatusBadGateway, "avatar_fetch_failed", "Failed to fetch avatar.")
		return
	}
	defer object.Body.Close()

	contentType := object.ContentType
	if contentType == "" {
		contentType = media.ContentType
	}
	if contentType == "" {
		contentType = "image/jpeg"
	}
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Cache-Control", "private, max-age=31536000, immutable")
	if object.ContentLength > 0 {
		w.Header().Set("Content-Length", fmt.Sprintf("%d", object.ContentLength))
	}
	w.WriteHeader(http.StatusOK)
	_, _ = io.Copy(w, object.Body)
}

func (h *Handler) UploadAvatar(w http.ResponseWriter, r *http.Request) {
	if h.objects == nil {
		h.writeAPIError(w, http.StatusServiceUnavailable, "object_storage_not_configured", "Object storage is not configured.")
		return
	}
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(w, http.StatusUnauthorized, "user_required", "User is required.")
		return
	}
	store, ok := h.store.(AvatarStore)
	if !ok {
		h.writeAPIError(w, http.StatusServiceUnavailable, "avatar_store_unavailable", "Avatars are unavailable.")
		return
	}
	fileBytes, contentType, err := readAvatarUpload(w, r)
	if err != nil {
		h.writeAPIError(w, http.StatusBadRequest, "invalid_avatar", err.Error())
		return
	}
	objectKey, err := newAvatarObjectKey(userID, contentType)
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "avatar_key_failed", "Failed to prepare avatar.")
		return
	}
	if err := h.objects.Put(
		r.Context(),
		objectKey,
		bytes.NewReader(fileBytes),
		contentType,
		int64(len(fileBytes)),
	); err != nil {
		h.writeAPIError(w, http.StatusBadGateway, "avatar_upload_failed", "Failed to upload avatar.")
		return
	}
	replaced, err := store.UpsertAvatar(
		r.Context(),
		userID,
		AvatarMedia{
			ObjectKey:   objectKey,
			ContentType: contentType,
			ByteSize:    int64(len(fileBytes)),
		},
	)
	if err != nil {
		_ = h.objects.Delete(context.Background(), h.objects.Bucket(), objectKey)
		if errors.Is(err, ErrProfileNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "profile_not_found", "Profile not found.")
			return
		}
		h.writeAPIError(w, http.StatusInternalServerError, "avatar_save_failed", "Failed to save avatar.")
		return
	}
	if replaced != nil {
		_ = h.objects.Delete(context.Background(), h.objects.Bucket(), replaced.ObjectKey)
	}
	h.writeJSON(
		w,
		http.StatusCreated,
		avatarResponse{
			AvatarURL: fmt.Sprintf(
				"/api/v1/profiles/%s/avatar?v=%s",
				userID,
				path.Base(objectKey),
			),
		},
	)
}

func readAvatarUpload(
	w http.ResponseWriter,
	r *http.Request,
) ([]byte, string, error) {
	const maxMultipartOverhead int64 = 1024 * 1024
	r.Body = http.MaxBytesReader(w, r.Body, MaxAvatarBytes+maxMultipartOverhead)
	if err := r.ParseMultipartForm(MaxAvatarBytes + 1024); err != nil {
		return nil, "", errors.New("Upload must be a multipart form with an avatar field.")
	}
	file, header, err := r.FormFile("avatar")
	if err != nil {
		return nil, "", errors.New("Avatar file is required.")
	}
	defer file.Close()
	if header.Size <= 0 {
		return nil, "", errors.New("Avatar file is empty.")
	}
	if header.Size > MaxAvatarBytes {
		return nil, "", errors.New("Avatar must be 3 MB or smaller.")
	}
	data, err := io.ReadAll(io.LimitReader(file, MaxAvatarBytes+1))
	if err != nil {
		return nil, "", errors.New("Failed to read avatar.")
	}
	if int64(len(data)) > MaxAvatarBytes {
		return nil, "", errors.New("Avatar must be 3 MB or smaller.")
	}
	contentType := http.DetectContentType(data)
	if contentType != "image/jpeg" &&
		contentType != "image/png" &&
		contentType != "image/webp" {
		return nil, "", errors.New("Avatar must be JPEG, PNG, or WebP.")
	}
	return data, contentType, nil
}

func newAvatarObjectKey(userID string, contentType string) (string, error) {
	randomBytes := make([]byte, 12)
	if _, err := rand.Read(randomBytes); err != nil {
		return "", err
	}
	extension := map[string]string{
		"image/jpeg": ".jpg",
		"image/png":  ".png",
		"image/webp": ".webp",
	}[contentType]
	return path.Join(
		"profile-avatars",
		userID,
		time.Now().UTC().Format("20060102T150405Z")+"-"+hex.EncodeToString(randomBytes)+extension,
	), nil
}

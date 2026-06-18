package submissions

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

type Store interface {
	GetMine(ctx context.Context, roomID string, userID string) (*Submission, error)
	UpsertMine(ctx context.Context, roomID string, userID string, media MediaObject) (Submission, []ObjectRef, error)
	DeleteMine(ctx context.Context, submissionID string, userID string) ([]ObjectRef, error)
	GetMineMedia(ctx context.Context, submissionID string, userID string) (MediaObject, error)
}

type ObjectStore interface {
	Bucket() string
	Put(ctx context.Context, key string, body io.Reader, contentType string, byteSize int64) error
	Get(ctx context.Context, bucket string, key string) (storage.Object, error)
	Delete(ctx context.Context, bucket string, key string) error
}

type Handler struct {
	store         Store
	objects       ObjectStore
	writeJSON     func(http.ResponseWriter, int, any)
	writeAPIError func(http.ResponseWriter, int, string, string)
}

func NewHandler(
	store Store,
	objects ObjectStore,
	writeJSON func(http.ResponseWriter, int, any),
	writeAPIError func(http.ResponseWriter, int, string, string),
) *Handler {
	return &Handler{
		store:         store,
		objects:       objects,
		writeJSON:     writeJSON,
		writeAPIError: writeAPIError,
	}
}

func (h *Handler) GetMine(w http.ResponseWriter, r *http.Request) {
	roomID := r.PathValue("roomId")
	if roomID == "" {
		h.writeAPIError(w, http.StatusBadRequest, "room_id_required", "Room id is required.")
		return
	}

	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(w, http.StatusUnauthorized, "user_required", "User is required.")
		return
	}

	submission, err := h.store.GetMine(r.Context(), roomID, userID)
	if err != nil {
		if errors.Is(err, ErrRoomNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "room_not_found", "Room not found.")
			return
		}

		h.writeAPIError(w, http.StatusInternalServerError, "submission_load_failed", "Failed to load submission.")
		return
	}

	if submission == nil {
		h.writeJSON(w, http.StatusOK, submissionResponseEnvelope{})
		return
	}

	response := toSubmissionResponse(*submission)
	h.writeJSON(w, http.StatusOK, submissionResponseEnvelope{Submission: &response})
}

func (h *Handler) UploadMine(w http.ResponseWriter, r *http.Request) {
	if h.objects == nil {
		h.writeAPIError(w, http.StatusServiceUnavailable, "object_storage_not_configured", "Object storage is not configured.")
		return
	}

	roomID := r.PathValue("roomId")
	if roomID == "" {
		h.writeAPIError(w, http.StatusBadRequest, "room_id_required", "Room id is required.")
		return
	}

	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(w, http.StatusUnauthorized, "user_required", "User is required.")
		return
	}

	fileBytes, contentType, err := readImageUpload(w, r)
	if err != nil {
		h.writeAPIError(w, http.StatusBadRequest, "invalid_upload", err.Error())
		return
	}

	objectKey, err := newObjectKey(roomID, userID, contentType)
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "object_key_failed", "Failed to prepare object key.")
		return
	}

	if err := h.objects.Put(r.Context(), objectKey, bytes.NewReader(fileBytes), contentType, int64(len(fileBytes))); err != nil {
		h.writeAPIError(w, http.StatusBadGateway, "object_upload_failed", "Failed to upload photo.")
		return
	}

	submission, replacedObjects, err := h.store.UpsertMine(r.Context(), roomID, userID, MediaObject{
		Bucket:      h.objects.Bucket(),
		ObjectKey:   objectKey,
		ContentType: contentType,
		ByteSize:    int64(len(fileBytes)),
	})
	if err != nil {
		_ = h.objects.Delete(context.Background(), h.objects.Bucket(), objectKey)

		if errors.Is(err, ErrRoomNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "room_not_found", "Room not found.")
			return
		}

		if errors.Is(err, ErrSubmissionClosed) {
			h.writeAPIError(w, http.StatusConflict, "submission_closed", "Submission phase is closed.")
			return
		}

		h.writeAPIError(w, http.StatusInternalServerError, "submission_save_failed", "Failed to save submission.")
		return
	}

	for _, object := range replacedObjects {
		_ = h.objects.Delete(context.Background(), object.Bucket, object.ObjectKey)
	}

	response := toSubmissionResponse(submission)
	h.writeJSON(w, http.StatusCreated, submissionResponseEnvelope{Submission: &response})
}

func (h *Handler) DeleteMine(w http.ResponseWriter, r *http.Request) {
	if h.objects == nil {
		h.writeAPIError(w, http.StatusServiceUnavailable, "object_storage_not_configured", "Object storage is not configured.")
		return
	}

	submissionID := r.PathValue("submissionId")
	if submissionID == "" {
		h.writeAPIError(w, http.StatusBadRequest, "submission_id_required", "Submission id is required.")
		return
	}

	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(w, http.StatusUnauthorized, "user_required", "User is required.")
		return
	}

	objects, err := h.store.DeleteMine(r.Context(), submissionID, userID)
	if err != nil {
		if errors.Is(err, ErrSubmissionNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "submission_not_found", "Submission not found.")
			return
		}

		if errors.Is(err, ErrSubmissionClosed) {
			h.writeAPIError(w, http.StatusConflict, "submission_closed", "Submission phase is closed.")
			return
		}

		h.writeAPIError(w, http.StatusInternalServerError, "submission_delete_failed", "Failed to delete submission.")
		return
	}

	for _, object := range objects {
		_ = h.objects.Delete(context.Background(), object.Bucket, object.ObjectKey)
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *Handler) GetMedia(w http.ResponseWriter, r *http.Request) {
	if h.objects == nil {
		h.writeAPIError(w, http.StatusServiceUnavailable, "object_storage_not_configured", "Object storage is not configured.")
		return
	}

	submissionID := r.PathValue("submissionId")
	if submissionID == "" {
		h.writeAPIError(w, http.StatusBadRequest, "submission_id_required", "Submission id is required.")
		return
	}

	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(w, http.StatusUnauthorized, "user_required", "User is required.")
		return
	}

	media, err := h.store.GetMineMedia(r.Context(), submissionID, userID)
	if err != nil {
		if errors.Is(err, ErrMediaNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "media_not_found", "Media not found.")
			return
		}

		h.writeAPIError(w, http.StatusInternalServerError, "media_load_failed", "Failed to load media.")
		return
	}

	object, err := h.objects.Get(r.Context(), media.Bucket, media.ObjectKey)
	if err != nil {
		h.writeAPIError(w, http.StatusBadGateway, "media_fetch_failed", "Failed to fetch media.")
		return
	}
	defer object.Body.Close()

	contentType := object.ContentType
	if contentType == "" {
		contentType = media.ContentType
	}
	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Cache-Control", "private, max-age=60")
	if object.ContentLength > 0 {
		w.Header().Set("Content-Length", fmt.Sprintf("%d", object.ContentLength))
	}
	w.WriteHeader(http.StatusOK)

	_, _ = io.Copy(w, object.Body)
}

func readImageUpload(w http.ResponseWriter, r *http.Request) ([]byte, string, error) {
	const maxMultipartOverhead int64 = 1024 * 1024
	r.Body = http.MaxBytesReader(w, r.Body, MaxImageBytes+maxMultipartOverhead)
	if err := r.ParseMultipartForm(MaxImageBytes + 1024); err != nil {
		return nil, "", errors.New("Upload must be a multipart form with a photo field.")
	}

	file, header, err := r.FormFile("photo")
	if err != nil {
		return nil, "", errors.New("Photo file is required.")
	}
	defer file.Close()

	if header.Size <= 0 {
		return nil, "", errors.New("Photo file is empty.")
	}

	if header.Size > MaxImageBytes {
		return nil, "", errors.New("Photo must be 10 MB or smaller.")
	}

	data, err := io.ReadAll(io.LimitReader(file, MaxImageBytes+1))
	if err != nil {
		return nil, "", errors.New("Failed to read photo.")
	}

	if int64(len(data)) > MaxImageBytes {
		return nil, "", errors.New("Photo must be 10 MB or smaller.")
	}

	contentType := http.DetectContentType(data)
	if !isAllowedImageType(contentType) {
		return nil, "", errors.New("Photo must be JPEG, PNG, or WebP.")
	}

	return data, contentType, nil
}

func isAllowedImageType(contentType string) bool {
	return contentType == "image/jpeg" ||
		contentType == "image/png" ||
		contentType == "image/webp"
}

func newObjectKey(roomID string, userID string, contentType string) (string, error) {
	randomID, err := randomHex(16)
	if err != nil {
		return "", err
	}

	return path.Join("submissions", roomID, userID, time.Now().UTC().Format("20060102T150405Z")+"-"+randomID+extensionForContentType(contentType)), nil
}

func randomHex(size int) (string, error) {
	bytes := make([]byte, size)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}

	return hex.EncodeToString(bytes), nil
}

func extensionForContentType(contentType string) string {
	switch contentType {
	case "image/jpeg":
		return ".jpg"
	case "image/png":
		return ".png"
	case "image/webp":
		return ".webp"
	default:
		return ""
	}
}

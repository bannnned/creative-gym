package results

import (
	"context"
	"errors"
	"net/http"

	"creative-gym/apps/api/internal/auth"
)

type Store interface {
	GetRoomResult(ctx context.Context, roomID string, userID string) (RoomResult, error)
	GetProfile(ctx context.Context, userID string) (Profile, error)
	GetPublicProfile(ctx context.Context, userID string) (Profile, error)
}

type Handler struct {
	store         Store
	objects       AvatarObjectStore
	writeJSON     func(http.ResponseWriter, int, any)
	writeAPIError func(http.ResponseWriter, int, string, string)
}

func NewHandler(store Store, writeJSON func(http.ResponseWriter, int, any), writeAPIError func(http.ResponseWriter, int, string, string)) *Handler {
	return &Handler{store: store, writeJSON: writeJSON, writeAPIError: writeAPIError}
}

func (h *Handler) GetRoomResult(w http.ResponseWriter, r *http.Request) {
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
	result, err := h.store.GetRoomResult(r.Context(), roomID, userID)
	if err != nil {
		switch {
		case errors.Is(err, ErrRoomNotFound):
			h.writeAPIError(w, http.StatusNotFound, "room_not_found", "Room not found.")
		case errors.Is(err, ErrResultsPending):
			h.writeAPIError(w, http.StatusConflict, "results_pending", "Results are not available yet.")
		default:
			h.writeAPIError(w, http.StatusInternalServerError, "results_failed", "Failed to load results.")
		}
		return
	}
	h.writeJSON(w, http.StatusOK, toRoomResultResponse(result))
}

func (h *Handler) GetProfile(w http.ResponseWriter, r *http.Request) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(w, http.StatusUnauthorized, "user_required", "User is required.")
		return
	}
	profile, err := h.store.GetProfile(r.Context(), userID)
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "profile_failed", "Failed to load profile.")
		return
	}
	h.writeJSON(w, http.StatusOK, toProfileResponse(profile))
}

func (h *Handler) GetPublicProfile(w http.ResponseWriter, r *http.Request) {
	targetUserID := r.PathValue("userId")
	if targetUserID == "" {
		h.writeAPIError(w, http.StatusBadRequest, "user_id_required", "User id is required.")
		return
	}
	viewerUserID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(w, http.StatusUnauthorized, "user_required", "User is required.")
		return
	}

	var (
		profile Profile
		err     error
	)
	if targetUserID == viewerUserID {
		profile, err = h.store.GetProfile(r.Context(), targetUserID)
	} else {
		profile, err = h.store.GetPublicProfile(r.Context(), targetUserID)
	}
	if err != nil {
		if errors.Is(err, ErrProfileNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "profile_not_found", "Profile not found.")
			return
		}
		h.writeAPIError(w, http.StatusInternalServerError, "profile_failed", "Failed to load profile.")
		return
	}
	h.writeJSON(w, http.StatusOK, toProfileResponse(profile))
}

package rooms

import (
	"context"
	"errors"
	"net/http"
	"time"

	"creative-gym/apps/api/internal/auth"
)

type Store interface {
	JoinChallenge(ctx context.Context, challengeID string, userID string) (Room, error)
	GetByID(ctx context.Context, roomID string, viewerUserID string) (Room, error)
}

type Handler struct {
	store         Store
	now           func() time.Time
	writeJSON     func(http.ResponseWriter, int, any)
	writeAPIError func(http.ResponseWriter, int, string, string)
}

func NewHandler(store Store, writeJSON func(http.ResponseWriter, int, any), writeAPIError func(http.ResponseWriter, int, string, string)) *Handler {
	return &Handler{
		store:         store,
		now:           time.Now,
		writeJSON:     writeJSON,
		writeAPIError: writeAPIError,
	}
}

func (h *Handler) JoinChallenge(w http.ResponseWriter, r *http.Request) {
	challengeID := r.PathValue("challengeId")
	if challengeID == "" {
		h.writeAPIError(w, http.StatusBadRequest, "challenge_id_required", "Challenge id is required.")
		return
	}

	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(w, http.StatusUnauthorized, "user_required", "User is required.")
		return
	}

	room, err := h.store.JoinChallenge(r.Context(), challengeID, userID)
	if err != nil {
		if errors.Is(err, ErrChallengeNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "challenge_not_found", "Challenge not found.")
			return
		}

		h.writeAPIError(w, http.StatusInternalServerError, "join_challenge_failed", "Failed to join challenge.")
		return
	}

	h.writeJSON(w, http.StatusOK, roomResponseEnvelope{
		Room: toRoomResponse(room, h.now()),
	})
}

func (h *Handler) GetByID(w http.ResponseWriter, r *http.Request) {
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

	room, err := h.store.GetByID(r.Context(), roomID, userID)
	if err != nil {
		if errors.Is(err, ErrRoomNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "room_not_found", "Room not found.")
			return
		}

		h.writeAPIError(w, http.StatusInternalServerError, "room_load_failed", "Failed to load room.")
		return
	}

	h.writeJSON(w, http.StatusOK, roomResponseEnvelope{
		Room: toRoomResponse(room, h.now()),
	})
}

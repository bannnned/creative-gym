package challenges

import (
	"context"
	"errors"
	"net/http"
	"time"
)

type Store interface {
	ListActive(ctx context.Context, viewerUserID string) ([]Challenge, error)
	GetByID(ctx context.Context, challengeID string, viewerUserID string) (Challenge, error)
}

type Handler struct {
	store         Store
	devUserID     string
	now           func() time.Time
	writeJSON     func(http.ResponseWriter, int, any)
	writeAPIError func(http.ResponseWriter, int, string, string)
}

func NewHandler(store Store, devUserID string, writeJSON func(http.ResponseWriter, int, any), writeAPIError func(http.ResponseWriter, int, string, string)) *Handler {
	return &Handler{
		store:         store,
		devUserID:     devUserID,
		now:           time.Now,
		writeJSON:     writeJSON,
		writeAPIError: writeAPIError,
	}
}

func (h *Handler) ListActive(w http.ResponseWriter, r *http.Request) {
	items, err := h.store.ListActive(r.Context(), h.viewerUserID(r))
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "active_challenges_failed", "Failed to load active challenges.")
		return
	}

	h.writeJSON(w, http.StatusOK, challengesResponse{
		Challenges: toChallengeResponses(items, h.now()),
	})
}

func (h *Handler) GetByID(w http.ResponseWriter, r *http.Request) {
	challengeID := r.PathValue("challengeId")
	if challengeID == "" {
		h.writeAPIError(w, http.StatusBadRequest, "challenge_id_required", "Challenge id is required.")
		return
	}

	item, err := h.store.GetByID(r.Context(), challengeID, h.viewerUserID(r))
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "challenge_not_found", "Challenge not found.")
			return
		}

		h.writeAPIError(w, http.StatusInternalServerError, "challenge_load_failed", "Failed to load challenge.")
		return
	}

	h.writeJSON(w, http.StatusOK, challengeResponseEnvelope{
		Challenge: toChallengeResponse(item, h.now()),
	})
}

func (h *Handler) viewerUserID(r *http.Request) string {
	if userID := r.Header.Get("X-Dev-User-Id"); userID != "" {
		return userID
	}

	return h.devUserID
}

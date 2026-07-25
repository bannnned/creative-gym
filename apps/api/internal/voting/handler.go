package voting

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"

	"creative-gym/apps/api/internal/auth"
)

type Store interface {
	NextPair(ctx context.Context, roomID string, userID string) (*Pair, error)
	CastVote(ctx context.Context, roomID string, userID string, leftSubmissionID string, rightSubmissionID string, chosenSubmissionID string) (Progress, error)
}

type Handler struct {
	store         Store
	writeJSON     func(http.ResponseWriter, int, any)
	writeAPIError func(http.ResponseWriter, int, string, string)
}

func NewHandler(store Store, writeJSON func(http.ResponseWriter, int, any), writeAPIError func(http.ResponseWriter, int, string, string)) *Handler {
	return &Handler{store: store, writeJSON: writeJSON, writeAPIError: writeAPIError}
}

func (h *Handler) NextPair(w http.ResponseWriter, r *http.Request) {
	roomID, userID, ok := h.requestIdentity(w, r)
	if !ok {
		return
	}
	pair, err := h.store.NextPair(r.Context(), roomID, userID)
	if err != nil {
		h.writeStoreError(w, err)
		return
	}
	h.writeJSON(w, http.StatusOK, toPairResponse(pair))
}

func (h *Handler) CastVote(w http.ResponseWriter, r *http.Request) {
	roomID, userID, ok := h.requestIdentity(w, r)
	if !ok {
		return
	}
	var request castVoteRequest
	if err := json.NewDecoder(r.Body).Decode(&request); err != nil {
		h.writeAPIError(w, http.StatusBadRequest, "invalid_vote", "Vote payload is invalid.")
		return
	}
	progress, err := h.store.CastVote(
		r.Context(),
		roomID,
		userID,
		request.LeftSubmissionID,
		request.RightSubmissionID,
		request.ChosenSubmissionID,
	)
	if err != nil {
		h.writeStoreError(w, err)
		return
	}
	h.writeJSON(w, http.StatusCreated, progressResponse{
		Completed: progress.Completed,
		Target:    progress.Target,
	})
}

func (h *Handler) requestIdentity(w http.ResponseWriter, r *http.Request) (string, string, bool) {
	roomID := r.PathValue("roomId")
	if roomID == "" {
		h.writeAPIError(w, http.StatusBadRequest, "room_id_required", "Room id is required.")
		return "", "", false
	}
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(w, http.StatusUnauthorized, "user_required", "User is required.")
		return "", "", false
	}
	return roomID, userID, true
}

func (h *Handler) writeStoreError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, ErrRoomNotFound):
		h.writeAPIError(w, http.StatusNotFound, "room_not_found", "Room not found.")
	case errors.Is(err, ErrVotingClosed):
		h.writeAPIError(w, http.StatusConflict, "voting_closed", "Voting is not open.")
	case errors.Is(err, ErrVotingComplete):
		h.writeAPIError(w, http.StatusConflict, "voting_complete", "Voting is already complete.")
	case errors.Is(err, ErrInvalidPair):
		h.writeAPIError(w, http.StatusBadRequest, "invalid_vote_pair", "Vote pair is invalid.")
	case errors.Is(err, ErrAlreadyVoted):
		h.writeAPIError(w, http.StatusConflict, "pair_already_voted", "This pair was already voted.")
	default:
		h.writeAPIError(w, http.StatusInternalServerError, "voting_failed", "Voting request failed.")
	}
}

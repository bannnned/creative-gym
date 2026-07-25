package challenges

import (
	"context"
	"crypto/sha256"
	"crypto/subtle"
	"encoding/hex"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"sync"
	"time"

	"creative-gym/apps/api/internal/auth"
)

type AdminAuthorizer interface {
	IsAdmin(ctx context.Context, userID string) (bool, error)
	GrantAdmin(ctx context.Context, userID string) error
}

type AdminChallengeStore interface {
	Create(ctx context.Context, createdByUserID string, mutation Mutation) (Challenge, error)
	Update(ctx context.Context, challengeID string, viewerUserID string, mutation Mutation) (Challenge, error)
	Archive(ctx context.Context, challengeID string, viewerUserID string) error
}

type AdminHandler struct {
	authorization  AdminAuthorizer
	challenges     AdminChallengeStore
	accessCodeHash string
	now            func() time.Time
	attemptsMu     sync.Mutex
	unlockAttempts map[string]unlockAttempt
	writeJSON      func(http.ResponseWriter, int, any)
	writeAPIError  func(http.ResponseWriter, int, string, string)
}

type adminStatusResponse struct {
	IsAdmin bool `json:"is_admin"`
}

type adminUnlockRequest struct {
	Code string `json:"code"`
}

type unlockAttempt struct {
	Failures     int
	BlockedUntil time.Time
}

type challengeMutationRequest struct {
	Title              string    `json:"title"`
	Theme              string    `json:"theme"`
	Description        string    `json:"description"`
	Rules              []string  `json:"rules"`
	SubmissionStartsAt time.Time `json:"submission_starts_at"`
	SubmissionEndsAt   time.Time `json:"submission_ends_at"`
	VotingStartsAt     time.Time `json:"voting_starts_at"`
	VotingEndsAt       time.Time `json:"voting_ends_at"`
}

func NewAdminHandler(
	authorization AdminAuthorizer,
	challenges AdminChallengeStore,
	accessCodeHash string,
	writeJSON func(http.ResponseWriter, int, any),
	writeAPIError func(http.ResponseWriter, int, string, string),
) *AdminHandler {
	return &AdminHandler{
		authorization:  authorization,
		challenges:     challenges,
		accessCodeHash: strings.ToLower(strings.TrimSpace(accessCodeHash)),
		now:            time.Now,
		unlockAttempts: make(map[string]unlockAttempt),
		writeJSON:      writeJSON,
		writeAPIError:  writeAPIError,
	}
}

func (h *AdminHandler) Status(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.requireUser(w, r)
	if !ok {
		return
	}

	isAdmin, err := h.authorization.IsAdmin(r.Context(), userID)
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "admin_status_failed", "Failed to check admin access.")
		return
	}

	h.writeJSON(w, http.StatusOK, adminStatusResponse{IsAdmin: isAdmin})
}

func (h *AdminHandler) Unlock(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.requireUser(w, r)
	if !ok {
		return
	}
	if len(h.accessCodeHash) != sha256.Size*2 {
		h.writeAPIError(w, http.StatusServiceUnavailable, "admin_access_unavailable", "Admin access is not configured.")
		return
	}
	if !h.canAttemptUnlock(userID) {
		h.writeAPIError(w, http.StatusTooManyRequests, "admin_unlock_limited", "Too many attempts. Try again later.")
		return
	}

	var request adminUnlockRequest
	if err := decodeJSON(r, &request); err != nil {
		h.writeAPIError(w, http.StatusBadRequest, "invalid_admin_code", "Enter a valid admin code.")
		return
	}

	sum := sha256.Sum256([]byte(request.Code))
	actual := hex.EncodeToString(sum[:])
	if subtle.ConstantTimeCompare([]byte(actual), []byte(h.accessCodeHash)) != 1 {
		h.recordUnlockFailure(userID)
		h.writeAPIError(w, http.StatusForbidden, "invalid_admin_code", "Admin code is incorrect.")
		return
	}

	if err := h.authorization.GrantAdmin(r.Context(), userID); err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "admin_unlock_failed", "Failed to enable admin access.")
		return
	}
	h.clearUnlockFailures(userID)

	h.writeJSON(w, http.StatusOK, adminStatusResponse{IsAdmin: true})
}

func (h *AdminHandler) CreateChallenge(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.requireAdmin(w, r)
	if !ok {
		return
	}

	mutation, ok := h.readMutation(w, r)
	if !ok {
		return
	}

	challenge, err := h.challenges.Create(r.Context(), userID, mutation)
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "challenge_create_failed", "Failed to create challenge.")
		return
	}

	h.writeJSON(w, http.StatusCreated, challengeResponseEnvelope{
		Challenge: toChallengeResponse(challenge, h.now()),
	})
}

func (h *AdminHandler) UpdateChallenge(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.requireAdmin(w, r)
	if !ok {
		return
	}

	challengeID := r.PathValue("challengeId")
	if challengeID == "" {
		h.writeAPIError(w, http.StatusBadRequest, "challenge_id_required", "Challenge id is required.")
		return
	}

	mutation, ok := h.readMutation(w, r)
	if !ok {
		return
	}

	challenge, err := h.challenges.Update(r.Context(), challengeID, userID, mutation)
	if err != nil {
		if errors.Is(err, ErrNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "challenge_not_found", "Challenge not found.")
			return
		}
		h.writeAPIError(w, http.StatusInternalServerError, "challenge_update_failed", "Failed to update challenge.")
		return
	}

	h.writeJSON(w, http.StatusOK, challengeResponseEnvelope{
		Challenge: toChallengeResponse(challenge, h.now()),
	})
}

func (h *AdminHandler) ArchiveChallenge(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.requireAdmin(w, r)
	if !ok {
		return
	}

	challengeID := r.PathValue("challengeId")
	if challengeID == "" {
		h.writeAPIError(w, http.StatusBadRequest, "challenge_id_required", "Challenge id is required.")
		return
	}

	if err := h.challenges.Archive(r.Context(), challengeID, userID); err != nil {
		if errors.Is(err, ErrNotFound) {
			h.writeAPIError(w, http.StatusNotFound, "challenge_not_found", "Challenge not found.")
			return
		}
		h.writeAPIError(w, http.StatusInternalServerError, "challenge_archive_failed", "Failed to archive challenge.")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (h *AdminHandler) readMutation(w http.ResponseWriter, r *http.Request) (Mutation, bool) {
	var request challengeMutationRequest
	if err := decodeJSON(r, &request); err != nil {
		h.writeAPIError(w, http.StatusBadRequest, "invalid_challenge", "Check the challenge fields.")
		return Mutation{}, false
	}

	mutation := Mutation{
		Title:              request.Title,
		Theme:              request.Theme,
		Description:        request.Description,
		Rules:              request.Rules,
		SubmissionStartsAt: request.SubmissionStartsAt,
		SubmissionEndsAt:   request.SubmissionEndsAt,
		VotingStartsAt:     request.VotingStartsAt,
		VotingEndsAt:       request.VotingEndsAt,
	}
	if err := mutation.Validate(); err != nil {
		h.writeAPIError(w, http.StatusBadRequest, "invalid_challenge", err.Error())
		return Mutation{}, false
	}

	return mutation, true
}

func (h *AdminHandler) requireUser(w http.ResponseWriter, r *http.Request) (string, bool) {
	userID, ok := auth.UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(w, http.StatusUnauthorized, "user_required", "User is required.")
		return "", false
	}

	return userID, true
}

func (h *AdminHandler) requireAdmin(w http.ResponseWriter, r *http.Request) (string, bool) {
	userID, ok := h.requireUser(w, r)
	if !ok {
		return "", false
	}

	isAdmin, err := h.authorization.IsAdmin(r.Context(), userID)
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "admin_status_failed", "Failed to check admin access.")
		return "", false
	}
	if !isAdmin {
		h.writeAPIError(w, http.StatusForbidden, "admin_required", "Admin access is required.")
		return "", false
	}

	return userID, true
}

func decodeJSON(r *http.Request, target any) error {
	decoder := json.NewDecoder(io.LimitReader(r.Body, 64*1024))
	decoder.DisallowUnknownFields()
	if err := decoder.Decode(target); err != nil {
		return err
	}
	if err := decoder.Decode(&struct{}{}); !errors.Is(err, io.EOF) {
		return errors.New("request body must contain one JSON object")
	}

	return nil
}

func (h *AdminHandler) canAttemptUnlock(userID string) bool {
	h.attemptsMu.Lock()
	defer h.attemptsMu.Unlock()

	attempt := h.unlockAttempts[userID]
	if attempt.BlockedUntil.IsZero() || !h.now().Before(attempt.BlockedUntil) {
		if !attempt.BlockedUntil.IsZero() {
			delete(h.unlockAttempts, userID)
		}
		return true
	}

	return false
}

func (h *AdminHandler) recordUnlockFailure(userID string) {
	h.attemptsMu.Lock()
	defer h.attemptsMu.Unlock()

	attempt := h.unlockAttempts[userID]
	attempt.Failures++
	if attempt.Failures >= 5 {
		attempt.BlockedUntil = h.now().Add(15 * time.Minute)
	}
	h.unlockAttempts[userID] = attempt
}

func (h *AdminHandler) clearUnlockFailures(userID string) {
	h.attemptsMu.Lock()
	defer h.attemptsMu.Unlock()
	delete(h.unlockAttempts, userID)
}

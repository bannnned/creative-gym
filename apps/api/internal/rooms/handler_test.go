package rooms

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"creative-gym/apps/api/internal/auth"
)

type fakeStore struct {
	joinChallenge func(ctx context.Context, challengeID string, userID string) (Room, error)
	getByID       func(ctx context.Context, roomID string, viewerUserID string) (Room, error)
}

func (s fakeStore) JoinChallenge(ctx context.Context, challengeID string, userID string) (Room, error) {
	return s.joinChallenge(ctx, challengeID, userID)
}

func (s fakeStore) GetByID(ctx context.Context, roomID string, viewerUserID string) (Room, error) {
	return s.getByID(ctx, roomID, viewerUserID)
}

func TestJoinChallenge(t *testing.T) {
	base := time.Date(2026, 6, 13, 8, 0, 0, 0, time.UTC)
	handler := NewHandler(fakeStore{
		joinChallenge: func(ctx context.Context, challengeID string, userID string) (Room, error) {
			if challengeID != "challenge-id" {
				t.Fatalf("challengeID = %q, want challenge-id", challengeID)
			}
			if userID != "user-id" {
				t.Fatalf("userID = %q, want user-id", userID)
			}

			return Room{
				ID:                 "room-id",
				ChallengeID:        challengeID,
				ChallengeTitle:     "Morning Light",
				ChallengeTheme:     "Light and Shadow",
				SubmissionStartsAt: base.Add(-24 * time.Hour),
				SubmissionEndsAt:   base.Add(24 * time.Hour),
				VotingStartsAt:     base.Add(24 * time.Hour),
				VotingEndsAt:       base.Add(72 * time.Hour),
				ParticipantCount:   1,
				Capacity:           16,
			}, nil
		},
	}, testWriteJSON, testWriteAPIError)
	handler.now = func() time.Time { return base }

	request := httptest.NewRequest(http.MethodPost, "/api/v1/challenges/challenge-id/join", nil)
	request.SetPathValue("challengeId", "challenge-id")
	request = request.WithContext(auth.ContextWithUserID(request.Context(), "user-id"))
	response := httptest.NewRecorder()

	handler.JoinChallenge(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}

	var body roomResponseEnvelope
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if body.Room.ID != "room-id" {
		t.Fatalf("room id = %q, want room-id", body.Room.ID)
	}

	if body.Room.Phase != PhaseSubmission {
		t.Fatalf("room phase = %q, want %q", body.Room.Phase, PhaseSubmission)
	}
}

func TestJoinChallengeNotFound(t *testing.T) {
	handler := NewHandler(fakeStore{
		joinChallenge: func(ctx context.Context, challengeID string, userID string) (Room, error) {
			return Room{}, ErrChallengeNotFound
		},
	}, testWriteJSON, testWriteAPIError)

	request := httptest.NewRequest(http.MethodPost, "/api/v1/challenges/missing/join", nil)
	request.SetPathValue("challengeId", "missing")
	request = request.WithContext(auth.ContextWithUserID(request.Context(), "user-id"))
	response := httptest.NewRecorder()

	handler.JoinChallenge(response, request)

	if response.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusNotFound)
	}

	if !strings.Contains(response.Body.String(), "challenge_not_found") {
		t.Fatalf("body = %q, want challenge_not_found", response.Body.String())
	}
}

func TestGetByIDError(t *testing.T) {
	handler := NewHandler(fakeStore{
		getByID: func(ctx context.Context, roomID string, viewerUserID string) (Room, error) {
			return Room{}, errors.New("database down")
		},
	}, testWriteJSON, testWriteAPIError)

	request := httptest.NewRequest(http.MethodGet, "/api/v1/rooms/room-id", nil)
	request.SetPathValue("roomId", "room-id")
	request = request.WithContext(auth.ContextWithUserID(request.Context(), "user-id"))
	response := httptest.NewRecorder()

	handler.GetByID(response, request)

	if response.Code != http.StatusInternalServerError {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusInternalServerError)
	}
}

func testWriteJSON(w http.ResponseWriter, statusCode int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(payload)
}

func testWriteAPIError(w http.ResponseWriter, statusCode int, code string, message string) {
	testWriteJSON(w, statusCode, map[string]map[string]string{
		"error": {
			"code":    code,
			"message": message,
		},
	})
}

package challenges

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
	listActive func(ctx context.Context, viewerUserID string) ([]Challenge, error)
	getByID    func(ctx context.Context, challengeID string, viewerUserID string) (Challenge, error)
}

func (s fakeStore) ListActive(ctx context.Context, viewerUserID string) ([]Challenge, error) {
	return s.listActive(ctx, viewerUserID)
}

func (s fakeStore) GetByID(ctx context.Context, challengeID string, viewerUserID string) (Challenge, error) {
	return s.getByID(ctx, challengeID, viewerUserID)
}

func TestListActive(t *testing.T) {
	base := time.Date(2026, 6, 13, 8, 0, 0, 0, time.UTC)
	handler := NewHandler(fakeStore{
		listActive: func(ctx context.Context, viewerUserID string) ([]Challenge, error) {
			if viewerUserID != "dev-user-id" {
				t.Fatalf("viewerUserID = %q, want dev-user-id", viewerUserID)
			}

			return []Challenge{{
				ID:                 "challenge-id",
				Kind:               "photo",
				Title:              "Morning Light",
				Theme:              "Light and Shadow",
				Description:        "Description",
				Rules:              []string{"Submit one photo."},
				Status:             "submitting",
				SubmissionStartsAt: base.Add(-24 * time.Hour),
				SubmissionEndsAt:   base.Add(24 * time.Hour),
				VotingStartsAt:     base.Add(24 * time.Hour),
				VotingEndsAt:       base.Add(72 * time.Hour),
				RoomCapacity:       16,
			}}, nil
		},
	}, testWriteJSON, testWriteAPIError)
	handler.now = func() time.Time { return base }

	request := httptest.NewRequest(http.MethodGet, "/api/v1/challenges/active", nil)
	request = request.WithContext(auth.ContextWithUserID(request.Context(), "dev-user-id"))
	response := httptest.NewRecorder()

	handler.ListActive(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}

	var body challengesResponse
	if err := json.NewDecoder(response.Body).Decode(&body); err != nil {
		t.Fatalf("decode response: %v", err)
	}

	if len(body.Challenges) != 1 {
		t.Fatalf("len(challenges) = %d, want 1", len(body.Challenges))
	}

	if got := body.Challenges[0].Phase; got != PhaseSubmission {
		t.Fatalf("phase = %q, want %q", got, PhaseSubmission)
	}
}

func TestGetByIDNotFound(t *testing.T) {
	handler := NewHandler(fakeStore{
		getByID: func(ctx context.Context, challengeID string, viewerUserID string) (Challenge, error) {
			return Challenge{}, ErrNotFound
		},
	}, testWriteJSON, testWriteAPIError)

	request := httptest.NewRequest(http.MethodGet, "/api/v1/challenges/missing", nil)
	request.SetPathValue("challengeId", "missing")
	request = request.WithContext(auth.ContextWithUserID(request.Context(), "dev-user-id"))
	response := httptest.NewRecorder()

	handler.GetByID(response, request)

	if response.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusNotFound)
	}

	if !strings.Contains(response.Body.String(), "challenge_not_found") {
		t.Fatalf("body = %q, want challenge_not_found", response.Body.String())
	}
}

func TestListActiveError(t *testing.T) {
	handler := NewHandler(fakeStore{
		listActive: func(ctx context.Context, viewerUserID string) ([]Challenge, error) {
			return nil, errors.New("database down")
		},
	}, testWriteJSON, testWriteAPIError)

	request := httptest.NewRequest(http.MethodGet, "/api/v1/challenges/active", nil)
	request = request.WithContext(auth.ContextWithUserID(request.Context(), "dev-user-id"))
	response := httptest.NewRecorder()

	handler.ListActive(response, request)

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

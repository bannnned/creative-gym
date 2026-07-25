package voting

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"creative-gym/apps/api/internal/auth"
)

type fakeStore struct {
	nextPair func(context.Context, string, string) (*Pair, error)
	castVote func(context.Context, string, string, string, string, string) (Progress, error)
}

func (s fakeStore) NextPair(ctx context.Context, roomID string, userID string) (*Pair, error) {
	return s.nextPair(ctx, roomID, userID)
}

func (s fakeStore) CastVote(ctx context.Context, roomID string, userID string, leftID string, rightID string, chosenID string) (Progress, error) {
	return s.castVote(ctx, roomID, userID, leftID, rightID, chosenID)
}

func TestNextPairKeepsAuthorsAnonymous(t *testing.T) {
	handler := NewHandler(fakeStore{
		nextPair: func(_ context.Context, roomID string, userID string) (*Pair, error) {
			if roomID != "room-id" || userID != "user-id" {
				t.Fatalf("unexpected identity: room=%q user=%q", roomID, userID)
			}
			return &Pair{
				Left:     Submission{ID: "left-id"},
				Right:    Submission{ID: "right-id"},
				Progress: Progress{Completed: 2, Target: 10},
			}, nil
		},
	}, testWriteJSON, testWriteAPIError)

	request := httptest.NewRequest(http.MethodGet, "/api/v1/rooms/room-id/votes/next-pair", nil)
	request.SetPathValue("roomId", "room-id")
	request = request.WithContext(auth.ContextWithUserID(request.Context(), "user-id"))
	response := httptest.NewRecorder()

	handler.NextPair(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	body := response.Body.String()
	if !strings.Contains(body, `"completed":2`) || !strings.Contains(body, `"left-id"`) {
		t.Fatalf("body = %q, want pair and progress", body)
	}
	if strings.Contains(body, "author") || strings.Contains(body, "user_id") {
		t.Fatalf("body = %q, author identity must stay hidden", body)
	}
}

func TestCastVoteRejectsRepeatedPair(t *testing.T) {
	handler := NewHandler(fakeStore{
		castVote: func(context.Context, string, string, string, string, string) (Progress, error) {
			return Progress{}, ErrAlreadyVoted
		},
	}, testWriteJSON, testWriteAPIError)

	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/rooms/room-id/votes",
		strings.NewReader(`{"left_submission_id":"left","right_submission_id":"right","chosen_submission_id":"left"}`),
	)
	request.SetPathValue("roomId", "room-id")
	request = request.WithContext(auth.ContextWithUserID(request.Context(), "user-id"))
	response := httptest.NewRecorder()

	handler.CastVote(response, request)

	if response.Code != http.StatusConflict {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusConflict)
	}
	if !strings.Contains(response.Body.String(), "pair_already_voted") {
		t.Fatalf("body = %q, want pair_already_voted", response.Body.String())
	}
}

func testWriteJSON(w http.ResponseWriter, statusCode int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(payload)
}

func testWriteAPIError(w http.ResponseWriter, statusCode int, code string, message string) {
	testWriteJSON(w, statusCode, map[string]map[string]string{
		"error": {"code": code, "message": message},
	})
}

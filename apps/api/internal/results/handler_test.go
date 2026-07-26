package results

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
	getRoomResult    func(context.Context, string, string) (RoomResult, error)
	getProfile       func(context.Context, string) (Profile, error)
	getPublicProfile func(context.Context, string) (Profile, error)
}

func (s fakeStore) GetRoomResult(ctx context.Context, roomID string, userID string) (RoomResult, error) {
	return s.getRoomResult(ctx, roomID, userID)
}

func (s fakeStore) GetProfile(ctx context.Context, userID string) (Profile, error) {
	return s.getProfile(ctx, userID)
}

func (s fakeStore) GetPublicProfile(ctx context.Context, userID string) (Profile, error) {
	return s.getPublicProfile(ctx, userID)
}

func TestGetRoomResultReturnsRankedWorks(t *testing.T) {
	handler := NewHandler(fakeStore{
		getRoomResult: func(context.Context, string, string) (RoomResult, error) {
			return RoomResult{
				RoomID:            "room-id",
				ChallengeTitle:    "Morning Light",
				ParticipantsCount: 4,
				RankedSubmissions: []SubmissionResult{
					{ID: "winner", AuthorUserID: "winner-user", Rank: 1, Wins: 8, Comparisons: 10},
					{ID: "mine", Rank: 2, Wins: 7, Comparisons: 10, IsCurrentUser: true},
				},
				SubmissionsCount: 2,
			}, nil
		},
	}, testWriteJSON, testWriteAPIError)
	request := httptest.NewRequest(http.MethodGet, "/api/v1/rooms/room-id/results", nil)
	request.SetPathValue("roomId", "room-id")
	request = request.WithContext(auth.ContextWithUserID(request.Context(), "user-id"))
	response := httptest.NewRecorder()

	handler.GetRoomResult(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	body := response.Body.String()
	if !strings.Contains(body, `"rank":1`) ||
		!strings.Contains(body, `"author_user_id":"winner-user"`) ||
		!strings.Contains(body, `"is_current_user":true`) {
		t.Fatalf("body = %q, want rankings, author, and current user", body)
	}
}

func TestGetPublicProfileReturnsPublicIdentity(t *testing.T) {
	handler := NewHandler(fakeStore{
		getPublicProfile: func(_ context.Context, userID string) (Profile, error) {
			if userID != "author-id" {
				t.Fatalf("userID = %q, want author-id", userID)
			}
			return Profile{
				UserID:      userID,
				DisplayName: "Участник",
				AvatarURL:   "/api/v1/profiles/author-id/avatar?v=avatar.jpg",
				Works:       []ProfileWork{{ID: "finished-work", Finished: true}},
			}, nil
		},
	}, testWriteJSON, testWriteAPIError)
	request := httptest.NewRequest(http.MethodGet, "/api/v1/profiles/author-id", nil)
	request.SetPathValue("userId", "author-id")
	request = request.WithContext(auth.ContextWithUserID(request.Context(), "viewer-id"))
	response := httptest.NewRecorder()

	handler.GetPublicProfile(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}
	body := response.Body.String()
	if !strings.Contains(body, `"id":"author-id"`) ||
		!strings.Contains(body, `"display_name":"Участник"`) ||
		!strings.Contains(body, `"avatar_url":"/api/v1/profiles/author-id/avatar?v=avatar.jpg"`) ||
		!strings.Contains(body, `"is_current_user":false`) {
		t.Fatalf("body = %q, want public identity", body)
	}
}

func TestProfilePoints(t *testing.T) {
	first, fourth := 1, 4
	profile := Profile{Works: []ProfileWork{
		{Finished: true, Place: &first},
		{Finished: true, Place: &fourth},
		{Finished: false},
	}}
	for _, work := range profile.Works {
		profile.Points += pointsForWork(work)
	}
	if profile.Points != 110 {
		t.Fatalf("points = %d, want 110", profile.Points)
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

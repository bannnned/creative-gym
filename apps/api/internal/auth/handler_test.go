package auth

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestCreateGuestSessionReturnsRawTokenAndStoresOnlyHash(t *testing.T) {
	sessions := &fakeSessionRepository{}
	handler := NewHandler(sessions, testWriteJSON, testWriteAPIError)
	now := time.Date(2026, 7, 25, 12, 0, 0, 0, time.UTC)
	handler.now = func() time.Time { return now }
	handler.newToken = func() (string, error) { return "raw-secret-token", nil }

	request := httptest.NewRequest(http.MethodPost, "/api/v1/auth/guest", nil)
	response := httptest.NewRecorder()

	handler.CreateGuestSession(response, request)

	if response.Code != http.StatusCreated {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusCreated)
	}
	if sessions.createHash != HashSessionToken("raw-secret-token") {
		t.Fatalf("stored hash = %q, want token hash", sessions.createHash)
	}
	if sessions.createHash == "raw-secret-token" {
		t.Fatal("raw session token must not be stored")
	}

	var payload guestSessionResponse
	if err := json.Unmarshal(response.Body.Bytes(), &payload); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	if payload.Token != "raw-secret-token" {
		t.Fatalf("token = %q, want raw-secret-token", payload.Token)
	}
	if !payload.User.IsGuest {
		t.Fatal("expected guest user")
	}
	if payload.ExpiresAt != now.Add(guestSessionTTL) {
		t.Fatalf("expires at = %s, want %s", payload.ExpiresAt, now.Add(guestSessionTTL))
	}
}

func testWriteJSON(w http.ResponseWriter, statusCode int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)
	_ = json.NewEncoder(w).Encode(payload)
}

func testWriteAPIError(
	w http.ResponseWriter,
	statusCode int,
	code string,
	message string,
) {
	testWriteJSON(w, statusCode, map[string]any{
		"error": map[string]string{
			"code":    code,
			"message": message,
		},
	})
}

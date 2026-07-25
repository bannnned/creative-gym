package auth

import (
	"context"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestDevUserMiddlewareUsesDefaultUserID(t *testing.T) {
	var gotUserID string
	handler := DevUserMiddleware("default-user")(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID, ok := UserIDFromContext(r.Context())
		if !ok {
			t.Fatal("user id missing from context")
		}
		gotUserID = userID
	}))

	handler.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/", nil))

	if gotUserID != "default-user" {
		t.Fatalf("userID = %q, want default-user", gotUserID)
	}
}

func TestDevUserMiddlewareUsesHeaderUserID(t *testing.T) {
	var gotUserID string
	handler := DevUserMiddleware("default-user")(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID, ok := UserIDFromContext(r.Context())
		if !ok {
			t.Fatal("user id missing from context")
		}
		gotUserID = userID
	}))

	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set(DevUserIDHeader, "header-user")
	handler.ServeHTTP(httptest.NewRecorder(), request)

	if gotUserID != "header-user" {
		t.Fatalf("userID = %q, want header-user", gotUserID)
	}
}

func TestSessionMiddlewareUsesBearerToken(t *testing.T) {
	sessions := &fakeSessionRepository{
		userIDByHash: map[string]string{
			HashSessionToken("valid-token"): "session-user",
		},
	}
	handler := SessionMiddleware(sessions)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		userID, ok := UserIDFromContext(r.Context())
		if !ok {
			t.Fatal("expected a user in request context")
		}
		if userID != "session-user" {
			t.Fatalf("user id = %q, want session-user", userID)
		}
		w.WriteHeader(http.StatusNoContent)
	}))

	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set("Authorization", "Bearer valid-token")
	response := httptest.NewRecorder()

	handler.ServeHTTP(response, request)

	if response.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusNoContent)
	}
}

func TestSessionMiddlewareIgnoresInvalidBearerToken(t *testing.T) {
	sessions := &fakeSessionRepository{userIDByHash: map[string]string{}}
	handler := SessionMiddleware(sessions)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if _, ok := UserIDFromContext(r.Context()); ok {
			t.Fatal("did not expect a user in request context")
		}
		w.WriteHeader(http.StatusNoContent)
	}))

	request := httptest.NewRequest(http.MethodGet, "/", nil)
	request.Header.Set("Authorization", "Bearer invalid-token")
	response := httptest.NewRecorder()

	handler.ServeHTTP(response, request)

	if response.Code != http.StatusNoContent {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusNoContent)
	}
}

type fakeSessionRepository struct {
	userIDByHash map[string]string
	created      GuestSession
	createHash   string
}

func (f *fakeSessionRepository) CreateGuestSession(
	_ context.Context,
	displayName string,
	tokenHash string,
	expiresAt time.Time,
) (GuestSession, error) {
	f.createHash = tokenHash
	f.created = GuestSession{
		UserID:      "guest-user",
		DisplayName: displayName,
		ExpiresAt:   expiresAt,
	}
	return f.created, nil
}

func (f *fakeSessionRepository) UserIDByTokenHash(
	_ context.Context,
	tokenHash string,
) (string, error) {
	userID, ok := f.userIDByHash[tokenHash]
	if !ok {
		return "", ErrSessionNotFound
	}
	return userID, nil
}

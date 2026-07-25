package challenges

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"creative-gym/apps/api/internal/auth"
)

type fakeAdminAuthorizer struct {
	isAdmin   bool
	grantedTo string
}

func (f *fakeAdminAuthorizer) IsAdmin(context.Context, string) (bool, error) {
	return f.isAdmin, nil
}

func (f *fakeAdminAuthorizer) GrantAdmin(_ context.Context, userID string) error {
	f.grantedTo = userID
	f.isAdmin = true
	return nil
}

type fakeAdminChallengeStore struct {
	archivedID string
}

func (f *fakeAdminChallengeStore) Create(context.Context, string, Mutation) (Challenge, error) {
	return Challenge{}, nil
}

func (f *fakeAdminChallengeStore) Update(context.Context, string, string, Mutation) (Challenge, error) {
	return Challenge{}, nil
}

func (f *fakeAdminChallengeStore) Archive(_ context.Context, challengeID string, _ string) error {
	f.archivedID = challengeID
	return nil
}

func TestAdminUnlockGrantsAccess(t *testing.T) {
	sum := sha256.Sum256([]byte("correct horse battery staple"))
	authorization := &fakeAdminAuthorizer{}
	handler := NewAdminHandler(
		authorization,
		&fakeAdminChallengeStore{},
		hex.EncodeToString(sum[:]),
		testWriteJSON,
		testWriteAPIError,
	)

	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/admin/unlock",
		strings.NewReader(`{"code":"correct horse battery staple"}`),
	)
	request = request.WithContext(authContext(request.Context(), "user-id"))
	response := httptest.NewRecorder()

	handler.Unlock(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body = %s", response.Code, http.StatusOK, response.Body.String())
	}
	if authorization.grantedTo != "user-id" {
		t.Fatalf("grantedTo = %q, want user-id", authorization.grantedTo)
	}
}

func TestAdminUnlockRejectsWrongCode(t *testing.T) {
	sum := sha256.Sum256([]byte("correct-code"))
	handler := NewAdminHandler(
		&fakeAdminAuthorizer{},
		&fakeAdminChallengeStore{},
		hex.EncodeToString(sum[:]),
		testWriteJSON,
		testWriteAPIError,
	)

	request := httptest.NewRequest(
		http.MethodPost,
		"/api/v1/admin/unlock",
		strings.NewReader(`{"code":"wrong-code"}`),
	)
	request = request.WithContext(authContext(request.Context(), "user-id"))
	response := httptest.NewRecorder()

	handler.Unlock(response, request)

	if response.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusForbidden)
	}
}

func TestAdminUnlockLimitsRepeatedFailures(t *testing.T) {
	sum := sha256.Sum256([]byte("correct-code"))
	handler := NewAdminHandler(
		&fakeAdminAuthorizer{},
		&fakeAdminChallengeStore{},
		hex.EncodeToString(sum[:]),
		testWriteJSON,
		testWriteAPIError,
	)

	for attempt := 1; attempt <= 6; attempt++ {
		request := httptest.NewRequest(
			http.MethodPost,
			"/api/v1/admin/unlock",
			strings.NewReader(`{"code":"wrong-code"}`),
		)
		request = request.WithContext(authContext(request.Context(), "user-id"))
		response := httptest.NewRecorder()

		handler.Unlock(response, request)

		want := http.StatusForbidden
		if attempt == 6 {
			want = http.StatusTooManyRequests
		}
		if response.Code != want {
			t.Fatalf("attempt %d status = %d, want %d", attempt, response.Code, want)
		}
	}
}

func TestAdminArchiveRequiresAdmin(t *testing.T) {
	store := &fakeAdminChallengeStore{}
	handler := NewAdminHandler(
		&fakeAdminAuthorizer{isAdmin: false},
		store,
		"",
		testWriteJSON,
		testWriteAPIError,
	)

	request := httptest.NewRequest(http.MethodDelete, "/api/v1/admin/challenges/challenge-id", nil)
	request.SetPathValue("challengeId", "challenge-id")
	request = request.WithContext(authContext(request.Context(), "user-id"))
	response := httptest.NewRecorder()

	handler.ArchiveChallenge(response, request)

	if response.Code != http.StatusForbidden {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusForbidden)
	}
	if store.archivedID != "" {
		t.Fatalf("archivedID = %q, want empty", store.archivedID)
	}
}

func authContext(ctx context.Context, userID string) context.Context {
	return auth.ContextWithUserID(ctx, userID)
}

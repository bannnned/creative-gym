package auth

import (
	"net/http"
	"net/http/httptest"
	"testing"
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

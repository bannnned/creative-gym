package httpapi

import (
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"creative-gym/apps/api/internal/config"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestHealthz(t *testing.T) {
	router := NewRouter(config.Config{
		AppEnv:      "test",
		HTTPAddr:    ":0",
		DatabaseURL: "postgres://example",
		DevUserID:   "00000000-0000-0000-0000-000000000001",
	}, slog.New(slog.NewTextHandler(io.Discard, nil)), &pgxpool.Pool{})

	request := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	response := httptest.NewRecorder()

	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}

	if contentType := response.Header().Get("Content-Type"); contentType != "application/json" {
		t.Fatalf("Content-Type = %q, want application/json", contentType)
	}

	if body := response.Body.String(); body != "{\"status\":\"ok\"}\n" {
		t.Fatalf("body = %q, want health response", body)
	}
}

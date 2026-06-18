package httpapi

import (
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
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

func TestSPAFallbackServesIndexForClientRoute(t *testing.T) {
	staticDir := t.TempDir()
	indexHTML := []byte("<!doctype html><title>Creative Gym</title><div id=\"root\"></div>")
	if err := os.WriteFile(filepath.Join(staticDir, "index.html"), indexHTML, 0o644); err != nil {
		t.Fatalf("write index.html: %v", err)
	}

	router := NewRouter(config.Config{
		AppEnv:       "test",
		HTTPAddr:     ":0",
		DatabaseURL:  "postgres://example",
		DevUserID:    "00000000-0000-0000-0000-000000000001",
		WebStaticDir: staticDir,
	}, slog.New(slog.NewTextHandler(io.Discard, nil)), &pgxpool.Pool{})

	request := httptest.NewRequest(http.MethodGet, "/challenges/123", nil)
	response := httptest.NewRecorder()

	router.ServeHTTP(response, request)

	if response.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusOK)
	}

	if body := response.Body.String(); body != string(indexHTML) {
		t.Fatalf("body = %q, want index html", body)
	}
}

func TestSPAFallbackDoesNotHandleAPIPaths(t *testing.T) {
	staticDir := t.TempDir()
	if err := os.WriteFile(filepath.Join(staticDir, "index.html"), []byte("index"), 0o644); err != nil {
		t.Fatalf("write index.html: %v", err)
	}

	router := NewRouter(config.Config{
		AppEnv:       "test",
		HTTPAddr:     ":0",
		DatabaseURL:  "postgres://example",
		DevUserID:    "00000000-0000-0000-0000-000000000001",
		WebStaticDir: staticDir,
	}, slog.New(slog.NewTextHandler(io.Discard, nil)), &pgxpool.Pool{})

	request := httptest.NewRequest(http.MethodGet, "/api/v1/missing", nil)
	response := httptest.NewRecorder()

	router.ServeHTTP(response, request)

	if response.Code != http.StatusNotFound {
		t.Fatalf("status = %d, want %d", response.Code, http.StatusNotFound)
	}
}

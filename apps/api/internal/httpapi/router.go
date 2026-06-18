package httpapi

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"os"
	"path/filepath"
	"strings"

	"creative-gym/apps/api/internal/auth"
	"creative-gym/apps/api/internal/challenges"
	"creative-gym/apps/api/internal/config"
	"creative-gym/apps/api/internal/db"
	"creative-gym/apps/api/internal/rooms"
	"github.com/jackc/pgx/v5/pgxpool"
)

type healthResponse struct {
	Status string `json:"status"`
}

type errorResponse struct {
	Error apiError `json:"error"`
}

type apiError struct {
	Code    string `json:"code"`
	Message string `json:"message"`
}

func NewRouter(cfg config.Config, logger *slog.Logger, dbPool *pgxpool.Pool) http.Handler {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, r *http.Request) {
		writeJSON(w, http.StatusOK, healthResponse{Status: "ok"})
	})
	mux.HandleFunc("GET /readyz", func(w http.ResponseWriter, r *http.Request) {
		if err := db.Ping(r.Context(), dbPool); err != nil {
			writeAPIError(w, http.StatusServiceUnavailable, "database_not_ready", "Database is not ready.")
			return
		}

		writeJSON(w, http.StatusOK, healthResponse{Status: "ok"})
	})

	challengeHandler := challenges.NewHandler(
		challenges.NewRepository(dbPool),
		writeJSON,
		writeAPIError,
	)
	roomHandler := rooms.NewHandler(
		rooms.NewRepository(dbPool),
		writeJSON,
		writeAPIError,
	)

	mux.HandleFunc("GET /api/v1/challenges/active", challengeHandler.ListActive)
	mux.HandleFunc("GET /api/v1/challenges/{challengeId}", challengeHandler.GetByID)
	mux.HandleFunc("POST /api/v1/challenges/{challengeId}/join", roomHandler.JoinChallenge)
	mux.HandleFunc("GET /api/v1/rooms/{roomId}", roomHandler.GetByID)

	var handler http.Handler = mux
	if cfg.WebStaticDir != "" {
		handler = spaHandler(cfg.WebStaticDir, handler)
	}

	handler = auth.DevUserMiddleware(cfg.DevUserID)(handler)
	handler = corsMiddleware(cfg.CORSAllowedOrigins)(handler)
	handler = requestLogger(logger)(handler)

	return handler
}

func spaHandler(staticDir string, apiHandler http.Handler) http.Handler {
	fileServer := http.FileServer(http.Dir(staticDir))
	indexPath := filepath.Join(staticDir, "index.html")

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if isAPIPath(r.URL.Path) {
			apiHandler.ServeHTTP(w, r)
			return
		}

		filePath := filepath.Join(staticDir, filepath.Clean(r.URL.Path))
		if info, err := os.Stat(filePath); err == nil && !info.IsDir() {
			fileServer.ServeHTTP(w, r)
			return
		}

		http.ServeFile(w, r, indexPath)
	})
}

func isAPIPath(path string) bool {
	return path == "/healthz" ||
		path == "/readyz" ||
		path == "/api" ||
		strings.HasPrefix(path, "/api/")
}

func requestLogger(logger *slog.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			logger.Debug("http request", "method", r.Method, "path", r.URL.Path)
			next.ServeHTTP(w, r)
		})
	}
}

func writeJSON(w http.ResponseWriter, statusCode int, payload any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	if err := json.NewEncoder(w).Encode(payload); err != nil {
		http.Error(w, "failed to encode response", http.StatusInternalServerError)
	}
}

func writeAPIError(w http.ResponseWriter, statusCode int, code string, message string) {
	writeJSON(w, statusCode, errorResponse{
		Error: apiError{
			Code:    code,
			Message: message,
		},
	})
}

func corsMiddleware(allowedOrigins []string) func(http.Handler) http.Handler {
	allowed := make(map[string]struct{}, len(allowedOrigins))
	allowAll := false
	for _, origin := range allowedOrigins {
		if origin == "*" {
			allowAll = true
			continue
		}
		allowed[origin] = struct{}{}
	}

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			origin := r.Header.Get("Origin")
			if origin != "" {
				if allowAll {
					w.Header().Set("Access-Control-Allow-Origin", "*")
				} else if _, ok := allowed[origin]; ok {
					w.Header().Set("Access-Control-Allow-Origin", origin)
					w.Header().Add("Vary", "Origin")
				}

				w.Header().Set("Access-Control-Allow-Methods", "GET, POST, DELETE, OPTIONS")
				w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Dev-User-Id")
			}

			if r.Method == http.MethodOptions {
				w.WriteHeader(http.StatusNoContent)
				return
			}

			next.ServeHTTP(w, r)
		})
	}
}

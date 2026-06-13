package httpapi

import (
	"encoding/json"
	"log/slog"
	"net/http"

	"creative-gym/apps/api/internal/auth"
	"creative-gym/apps/api/internal/challenges"
	"creative-gym/apps/api/internal/config"
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

	return requestLogger(logger)(auth.DevUserMiddleware(cfg.DevUserID)(mux))
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

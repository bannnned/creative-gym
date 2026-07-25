package auth

import (
	"crypto/sha256"
	"encoding/hex"
	"errors"
	"net/http"
	"strings"
)

const DevUserIDHeader = "X-Dev-User-Id"

func DevUserMiddleware(defaultUserID string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			userID := r.Header.Get(DevUserIDHeader)
			if userID == "" {
				userID = defaultUserID
			}

			next.ServeHTTP(w, r.WithContext(ContextWithUserID(r.Context(), userID)))
		})
	}
}

func SessionMiddleware(sessions SessionRepository) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token := bearerToken(r.Header.Get("Authorization"))
			if token == "" {
				next.ServeHTTP(w, r)
				return
			}

			userID, err := sessions.UserIDByTokenHash(
				r.Context(),
				HashSessionToken(token),
			)
			if err == nil {
				r = r.WithContext(ContextWithUserID(r.Context(), userID))
			} else if !errors.Is(err, ErrSessionNotFound) {
				// Protected handlers will return an authentication error. Keeping
				// database details out of the response avoids leaking internals.
			}

			next.ServeHTTP(w, r)
		})
	}
}

func HashSessionToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}

func bearerToken(authorization string) string {
	scheme, token, ok := strings.Cut(strings.TrimSpace(authorization), " ")
	if !ok || !strings.EqualFold(scheme, "Bearer") {
		return ""
	}

	return strings.TrimSpace(token)
}

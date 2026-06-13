package auth

import "net/http"

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

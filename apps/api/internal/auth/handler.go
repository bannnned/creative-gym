package auth

import (
	"crypto/rand"
	"encoding/base64"
	"net/http"
	"time"

	"creative-gym/apps/api/internal/config"
	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
)

const (
	guestDisplayName = "Участник"
	guestSessionTTL  = 90 * 24 * time.Hour
)

type JSONWriter func(http.ResponseWriter, int, any)
type APIErrorWriter func(http.ResponseWriter, int, string, string)

type Handler struct {
	sessions      SessionRepository
	writeJSON     JSONWriter
	writeAPIError APIErrorWriter
	now           func() time.Time
	newToken      func() (string, error)
	accounts      *Repository
	settings      config.AuthConfig
	mailer        Mailer
	webAuthn      *webauthn.WebAuthn
	httpClient    *http.Client
}

type guestSessionResponse struct {
	Token     string       `json:"token"`
	ExpiresAt time.Time    `json:"expires_at"`
	User      userResponse `json:"user"`
}

type userResponse struct {
	ID            string `json:"id"`
	DisplayName   string `json:"display_name"`
	Email         string `json:"email"`
	EmailVerified bool   `json:"email_verified"`
	HasYandex     bool   `json:"has_yandex"`
	HasPasskey    bool   `json:"has_passkey"`
	IsGuest       bool   `json:"is_guest"`
}

func NewHandler(
	sessions SessionRepository,
	writeJSON JSONWriter,
	writeAPIError APIErrorWriter,
) *Handler {
	return &Handler{
		sessions:      sessions,
		writeJSON:     writeJSON,
		writeAPIError: writeAPIError,
		now:           time.Now,
		newToken:      generateSessionToken,
		httpClient:    &http.Client{Timeout: 10 * time.Second},
	}
}

func (h *Handler) ConfigureAccounts(
	repository *Repository,
	settings config.AuthConfig,
	mailer Mailer,
) error {
	h.accounts = repository
	h.settings = settings
	h.mailer = mailer
	if !settings.PasskeyComplete() {
		return nil
	}
	instance, err := webauthn.New(&webauthn.Config{
		RPID:                  settings.PasskeyRPID,
		RPDisplayName:         settings.PasskeyRPName,
		RPOrigins:             settings.PasskeyOrigins,
		AttestationPreference: protocol.PreferNoAttestation,
		AuthenticatorSelection: protocol.AuthenticatorSelection{
			ResidentKey:      protocol.ResidentKeyRequirementRequired,
			UserVerification: protocol.VerificationRequired,
		},
	})
	if err != nil {
		return err
	}
	h.webAuthn = instance
	return nil
}

func (h *Handler) CreateGuestSession(w http.ResponseWriter, r *http.Request) {
	token, err := h.newToken()
	if err != nil {
		h.writeAPIError(
			w,
			http.StatusInternalServerError,
			"session_token_failed",
			"Could not create a session.",
		)
		return
	}

	expiresAt := h.now().UTC().Add(guestSessionTTL)
	session, err := h.sessions.CreateGuestSession(
		r.Context(),
		guestDisplayName,
		HashSessionToken(token),
		expiresAt,
	)
	if err != nil {
		h.writeAPIError(
			w,
			http.StatusInternalServerError,
			"guest_session_failed",
			"Could not create a guest session.",
		)
		return
	}

	h.writeJSON(w, http.StatusCreated, guestSessionResponse{
		Token:     token,
		ExpiresAt: session.ExpiresAt,
		User: userResponse{
			ID:          session.UserID,
			DisplayName: session.DisplayName,
			IsGuest:     true,
		},
	})
}

func (h *Handler) GetCurrentSession(w http.ResponseWriter, r *http.Request) {
	userID, ok := UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(
			w,
			http.StatusUnauthorized,
			"session_required",
			"A valid session is required.",
		)
		return
	}

	if h.accounts == nil {
		h.writeJSON(w, http.StatusOK, map[string]any{
			"user": userResponse{ID: userID, DisplayName: guestDisplayName, IsGuest: true},
		})
		return
	}
	account, err := h.accounts.GetAccount(r.Context(), userID)
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "account_failed", "Could not load the account.")
		return
	}
	h.writeJSON(w, http.StatusOK, map[string]any{"user": toUserResponse(account)})
}

func toUserResponse(account Account) userResponse {
	return userResponse{
		ID:            account.ID,
		DisplayName:   account.DisplayName,
		Email:         account.Email,
		EmailVerified: account.EmailVerified(),
		HasYandex:     account.HasYandex,
		HasPasskey:    account.PasskeyCount > 0,
		IsGuest:       account.IsGuest(),
	}
}

func generateSessionToken() (string, error) {
	tokenBytes := make([]byte, 32)
	if _, err := rand.Read(tokenBytes); err != nil {
		return "", err
	}

	return base64.RawURLEncoding.EncodeToString(tokenBytes), nil
}

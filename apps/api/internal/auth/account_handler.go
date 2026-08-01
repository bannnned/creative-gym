package auth

import (
	"crypto/sha256"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"html"
	"io"
	"net/http"
	"net/mail"
	"net/url"
	"strings"
	"time"

	"github.com/go-webauthn/webauthn/webauthn"
)

const (
	emailTokenTTL       = 30 * time.Minute
	oauthStateTTL       = 10 * time.Minute
	exchangeCodeTTL     = 5 * time.Minute
	passkeyChallengeTTL = 5 * time.Minute
)

type emailStartRequest struct {
	Email string `json:"email"`
}

type exchangeRequest struct {
	Code string `json:"code"`
}

type yandexTokenResponse struct {
	AccessToken string `json:"access_token"`
}

type yandexUserResponse struct {
	ID           string `json:"id"`
	Login        string `json:"login"`
	DisplayName  string `json:"display_name"`
	DefaultEmail string `json:"default_email"`
}

func (h *Handler) StartEmailVerification(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.requireAccountUser(w, r)
	if !ok {
		return
	}
	if h.mailer == nil || !h.settings.EmailComplete() {
		h.writeAPIError(w, http.StatusServiceUnavailable, "email_auth_unavailable", "Email confirmation is not configured yet.")
		return
	}

	var request emailStartRequest
	if err := json.NewDecoder(io.LimitReader(r.Body, 8<<10)).Decode(&request); err != nil {
		h.writeAPIError(w, http.StatusBadRequest, "invalid_email", "Enter a valid email address.")
		return
	}
	email, err := normalizeEmail(request.Email)
	if err != nil {
		h.writeAPIError(w, http.StatusBadRequest, "invalid_email", "Enter a valid email address.")
		return
	}

	token, err := h.newToken()
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "email_token_failed", "Could not create a confirmation link.")
		return
	}
	targetUserID, err := h.accounts.StoreEmailToken(
		r.Context(), userID, email, HashSessionToken(token), h.now().UTC().Add(emailTokenTTL),
	)
	if err != nil {
		if errors.Is(err, ErrRateLimited) {
			h.writeAPIError(w, http.StatusTooManyRequests, "email_rate_limited", "Wait before requesting another email.")
			return
		}
		if errors.Is(err, ErrIdentityInUse) {
			h.writeAPIError(w, http.StatusConflict, "identity_in_use", "This email belongs to another account. Sign out before using it here.")
			return
		}
		h.writeAPIError(w, http.StatusInternalServerError, "email_token_failed", "Could not create a confirmation link.")
		return
	}

	confirmationURL := h.settings.PublicBaseURL + "/api/v1/auth/email/confirm?token=" + url.QueryEscape(token)
	if err := h.mailer.SendEmailConfirmation(email, confirmationURL); err != nil {
		h.writeAPIError(w, http.StatusBadGateway, "email_delivery_failed", "The confirmation email could not be sent.")
		return
	}
	h.writeJSON(w, http.StatusAccepted, map[string]any{
		"email":      maskEmail(email),
		"expires_at": h.now().UTC().Add(emailTokenTTL),
		"sign_in":    targetUserID != userID,
	})
}

func (h *Handler) ConfirmEmail(w http.ResponseWriter, r *http.Request) {
	token := strings.TrimSpace(r.URL.Query().Get("token"))
	if token == "" || h.accounts == nil {
		h.writeConfirmationPage(w, false, "Ссылка недействительна", "Запросите новое письмо в приложении.", "")
		return
	}
	account, err := h.accounts.ConfirmEmailToken(r.Context(), HashSessionToken(token))
	if err != nil {
		message := "Запросите новое письмо в приложении."
		if errors.Is(err, ErrIdentityInUse) {
			message = "Эта почта уже связана с другим аккаунтом."
		}
		h.writeConfirmationPage(w, false, "Не удалось подтвердить почту", message, "")
		return
	}
	exchangeCode, err := h.newToken()
	if err != nil || h.accounts.StoreExchangeCode(
		r.Context(), account.ID, HashSessionToken(exchangeCode), h.now().UTC().Add(exchangeCodeTTL),
	) != nil {
		h.writeConfirmationPage(w, false, "Почта подтверждена", "Вернитесь в приложение и войдите ещё раз.", "")
		return
	}
	h.writeConfirmationPage(
		w,
		true,
		"Почта подтверждена",
		fmt.Sprintf("%s, теперь призовые очки будут учитываться.", account.DisplayName),
		h.authCallback(exchangeCode, ""),
	)
}

func (h *Handler) StartYandex(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.requireAccountUser(w, r)
	if !ok {
		return
	}
	if !h.settings.YandexComplete() {
		h.writeAPIError(w, http.StatusServiceUnavailable, "yandex_auth_unavailable", "Yandex ID is not configured yet.")
		return
	}

	state, err := h.newToken()
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "oauth_state_failed", "Could not start Yandex sign-in.")
		return
	}
	verifier, err := h.newToken()
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "oauth_state_failed", "Could not start Yandex sign-in.")
		return
	}
	if err := h.accounts.StoreOAuthState(
		r.Context(), userID, HashSessionToken(state), verifier, h.now().UTC().Add(oauthStateTTL),
	); err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "oauth_state_failed", "Could not start Yandex sign-in.")
		return
	}

	challengeHash := sha256.Sum256([]byte(verifier))
	redirectURI := h.settings.PublicBaseURL + "/api/v1/auth/yandex/callback"
	query := url.Values{
		"response_type":         {"code"},
		"client_id":             {h.settings.YandexClientID},
		"redirect_uri":          {redirectURI},
		"state":                 {state},
		"code_challenge":        {base64.RawURLEncoding.EncodeToString(challengeHash[:])},
		"code_challenge_method": {"S256"},
	}
	h.writeJSON(w, http.StatusOK, map[string]string{
		"authorization_url": "https://oauth.yandex.ru/authorize?" + query.Encode(),
	})
}

func (h *Handler) YandexCallback(w http.ResponseWriter, r *http.Request) {
	if oauthError := strings.TrimSpace(r.URL.Query().Get("error")); oauthError != "" {
		h.redirectAuthResult(w, r, "", "yandex_cancelled")
		return
	}
	code := strings.TrimSpace(r.URL.Query().Get("code"))
	stateRaw := strings.TrimSpace(r.URL.Query().Get("state"))
	if code == "" || stateRaw == "" || h.accounts == nil {
		h.redirectAuthResult(w, r, "", "invalid_yandex_callback")
		return
	}
	state, err := h.accounts.ConsumeOAuthState(r.Context(), HashSessionToken(stateRaw))
	if err != nil {
		h.redirectAuthResult(w, r, "", "expired_yandex_session")
		return
	}

	profile, err := h.exchangeYandexCode(r, code, state.CodeVerifier)
	if err != nil || profile.ID == "" {
		h.redirectAuthResult(w, r, "", "yandex_verification_failed")
		return
	}
	displayName := strings.TrimSpace(profile.DisplayName)
	if displayName == "" {
		displayName = strings.TrimSpace(profile.Login)
	}
	email := strings.ToLower(strings.TrimSpace(profile.DefaultEmail))
	targetUserID, err := h.accounts.AttachYandexIdentity(
		r.Context(), state.UserID, profile.ID, email, displayName,
	)
	if err != nil {
		if errors.Is(err, ErrIdentityInUse) {
			h.redirectAuthResult(w, r, "", "identity_in_use")
			return
		}
		h.redirectAuthResult(w, r, "", "yandex_link_failed")
		return
	}

	exchangeCode, err := h.newToken()
	if err != nil {
		h.redirectAuthResult(w, r, "", "session_failed")
		return
	}
	if err := h.accounts.StoreExchangeCode(
		r.Context(), targetUserID, HashSessionToken(exchangeCode), h.now().UTC().Add(exchangeCodeTTL),
	); err != nil {
		h.redirectAuthResult(w, r, "", "session_failed")
		return
	}
	h.redirectAuthResult(w, r, exchangeCode, "")
}

func (h *Handler) ExchangeCode(w http.ResponseWriter, r *http.Request) {
	if h.accounts == nil {
		h.writeAPIError(w, http.StatusServiceUnavailable, "auth_unavailable", "Account authentication is unavailable.")
		return
	}
	var request exchangeRequest
	if err := json.NewDecoder(io.LimitReader(r.Body, 8<<10)).Decode(&request); err != nil || strings.TrimSpace(request.Code) == "" {
		h.writeAPIError(w, http.StatusBadRequest, "invalid_exchange_code", "The sign-in code is invalid.")
		return
	}
	userID, err := h.accounts.ConsumeExchangeCode(r.Context(), HashSessionToken(strings.TrimSpace(request.Code)))
	if err != nil {
		h.writeAPIError(w, http.StatusUnauthorized, "invalid_exchange_code", "The sign-in code has expired.")
		return
	}
	h.issueSession(w, r, userID)
}

func (h *Handler) BeginPasskeyRegistration(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.requireAccountUser(w, r)
	if !ok {
		return
	}
	if h.webAuthn == nil {
		h.writeAPIError(w, http.StatusServiceUnavailable, "passkey_unavailable", "Passkeys are not configured yet.")
		return
	}
	account, err := h.accounts.GetAccount(r.Context(), userID)
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "account_failed", "Could not load the account.")
		return
	}
	if account.IsGuest() {
		h.writeAPIError(w, http.StatusConflict, "verified_identity_required", "Confirm email or Yandex ID before creating a passkey.")
		return
	}
	creation, session, err := h.webAuthn.BeginRegistration(account)
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "passkey_begin_failed", "Could not create a passkey request.")
		return
	}
	if err := h.accounts.SavePasskeyChallenge(
		r.Context(), session.Challenge, &userID, "register", *session, h.now().UTC().Add(passkeyChallengeTTL),
	); err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "passkey_begin_failed", "Could not create a passkey request.")
		return
	}
	h.writeJSON(w, http.StatusOK, map[string]any{
		"challenge_id": session.Challenge,
		"options":      creation,
	})
}

func (h *Handler) FinishPasskeyRegistration(w http.ResponseWriter, r *http.Request) {
	userID, ok := h.requireAccountUser(w, r)
	if !ok {
		return
	}
	challengeID := strings.TrimSpace(r.URL.Query().Get("challenge_id"))
	storedUserID, session, err := h.accounts.ConsumePasskeyChallenge(r.Context(), challengeID, "register")
	if err != nil || storedUserID == nil || *storedUserID != userID {
		h.writeAPIError(w, http.StatusUnauthorized, "invalid_passkey_challenge", "The passkey request has expired.")
		return
	}
	account, err := h.accounts.GetAccount(r.Context(), userID)
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "account_failed", "Could not load the account.")
		return
	}
	credential, err := h.webAuthn.FinishRegistration(account, session, r)
	if err != nil {
		h.writeAPIError(w, http.StatusBadRequest, "passkey_verification_failed", "The passkey could not be verified.")
		return
	}
	if err := h.accounts.StorePasskeyCredential(r.Context(), userID, credential); err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "passkey_store_failed", "The passkey could not be saved.")
		return
	}
	h.writeJSON(w, http.StatusCreated, map[string]bool{"created": true})
}

func (h *Handler) BeginPasskeyLogin(w http.ResponseWriter, r *http.Request) {
	if h.webAuthn == nil || h.accounts == nil {
		h.writeAPIError(w, http.StatusServiceUnavailable, "passkey_unavailable", "Passkeys are not configured yet.")
		return
	}
	assertion, session, err := h.webAuthn.BeginDiscoverableLogin()
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "passkey_begin_failed", "Could not start passkey sign-in.")
		return
	}
	if err := h.accounts.SavePasskeyChallenge(
		r.Context(), session.Challenge, nil, "login", *session, h.now().UTC().Add(passkeyChallengeTTL),
	); err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "passkey_begin_failed", "Could not start passkey sign-in.")
		return
	}
	h.writeJSON(w, http.StatusOK, map[string]any{
		"challenge_id": session.Challenge,
		"options":      assertion,
	})
}

func (h *Handler) FinishPasskeyLogin(w http.ResponseWriter, r *http.Request) {
	challengeID := strings.TrimSpace(r.URL.Query().Get("challenge_id"))
	_, session, err := h.accounts.ConsumePasskeyChallenge(r.Context(), challengeID, "login")
	if err != nil {
		h.writeAPIError(w, http.StatusUnauthorized, "invalid_passkey_challenge", "The passkey request has expired.")
		return
	}
	var authenticated Account
	credential, err := h.webAuthn.FinishDiscoverableLogin(
		func(rawID, userHandle []byte) (webauthn.User, error) {
			account, lookupErr := h.accounts.AccountByPasskey(r.Context(), rawID, userHandle)
			if lookupErr == nil {
				authenticated = account
			}
			return account, lookupErr
		},
		session,
		r,
	)
	if err != nil || authenticated.ID == "" {
		h.writeAPIError(w, http.StatusUnauthorized, "passkey_verification_failed", "The passkey could not be verified.")
		return
	}
	if err := h.accounts.UpdatePasskeyCredential(r.Context(), credential); err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "passkey_update_failed", "The passkey could not be updated.")
		return
	}
	h.issueSession(w, r, authenticated.ID)
}

func (h *Handler) issueSession(w http.ResponseWriter, r *http.Request, userID string) {
	token, err := h.newToken()
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "session_token_failed", "Could not create a session.")
		return
	}
	expiresAt := h.now().UTC().Add(guestSessionTTL)
	if err := h.accounts.CreateSessionForUser(r.Context(), userID, HashSessionToken(token), expiresAt); err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "session_failed", "Could not create a session.")
		return
	}
	account, err := h.accounts.GetAccount(r.Context(), userID)
	if err != nil {
		h.writeAPIError(w, http.StatusInternalServerError, "account_failed", "Could not load the account.")
		return
	}
	h.writeJSON(w, http.StatusOK, guestSessionResponse{
		Token: token, ExpiresAt: expiresAt, User: toUserResponse(account),
	})
}

func (h *Handler) requireAccountUser(w http.ResponseWriter, r *http.Request) (string, bool) {
	userID, ok := UserIDFromContext(r.Context())
	if !ok {
		h.writeAPIError(w, http.StatusUnauthorized, "session_required", "A valid session is required.")
		return "", false
	}
	if h.accounts == nil {
		h.writeAPIError(w, http.StatusServiceUnavailable, "auth_unavailable", "Account authentication is unavailable.")
		return "", false
	}
	return userID, true
}

func (h *Handler) exchangeYandexCode(r *http.Request, code, verifier string) (yandexUserResponse, error) {
	redirectURI := h.settings.PublicBaseURL + "/api/v1/auth/yandex/callback"
	form := url.Values{
		"grant_type":    {"authorization_code"},
		"code":          {code},
		"client_id":     {h.settings.YandexClientID},
		"redirect_uri":  {redirectURI},
		"code_verifier": {verifier},
	}
	if h.settings.YandexClientSecret != "" {
		form.Set("client_secret", h.settings.YandexClientSecret)
	}
	request, err := http.NewRequestWithContext(
		r.Context(), http.MethodPost, "https://oauth.yandex.ru/token", strings.NewReader(form.Encode()),
	)
	if err != nil {
		return yandexUserResponse{}, err
	}
	request.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	response, err := h.httpClient.Do(request)
	if err != nil {
		return yandexUserResponse{}, err
	}
	defer response.Body.Close()
	if response.StatusCode != http.StatusOK {
		return yandexUserResponse{}, fmt.Errorf("yandex token status: %d", response.StatusCode)
	}
	var token yandexTokenResponse
	if err := json.NewDecoder(io.LimitReader(response.Body, 1<<20)).Decode(&token); err != nil || token.AccessToken == "" {
		return yandexUserResponse{}, fmt.Errorf("invalid yandex token response")
	}

	infoRequest, err := http.NewRequestWithContext(
		r.Context(), http.MethodGet, "https://login.yandex.ru/info?format=json", nil,
	)
	if err != nil {
		return yandexUserResponse{}, err
	}
	infoRequest.Header.Set("Authorization", "OAuth "+token.AccessToken)
	infoResponse, err := h.httpClient.Do(infoRequest)
	if err != nil {
		return yandexUserResponse{}, err
	}
	defer infoResponse.Body.Close()
	if infoResponse.StatusCode != http.StatusOK {
		return yandexUserResponse{}, fmt.Errorf("yandex info status: %d", infoResponse.StatusCode)
	}
	var profile yandexUserResponse
	if err := json.NewDecoder(io.LimitReader(infoResponse.Body, 1<<20)).Decode(&profile); err != nil {
		return yandexUserResponse{}, err
	}
	return profile, nil
}

func (h *Handler) redirectAuthResult(w http.ResponseWriter, r *http.Request, code, errorCode string) {
	http.Redirect(w, r, h.authCallback(code, errorCode), http.StatusFound)
}

func (h *Handler) authCallback(code, errorCode string) string {
	callback, err := url.Parse(h.settings.AppCallbackURL)
	if err != nil {
		return "creativegym://auth/complete?error=invalid_callback"
	}
	query := callback.Query()
	if code != "" {
		query.Set("code", code)
	}
	if errorCode != "" {
		query.Set("error", errorCode)
	}
	callback.RawQuery = query.Encode()
	return callback.String()
}

func (h *Handler) writeConfirmationPage(w http.ResponseWriter, success bool, title, message, callbackURL string) {
	color := "#244d42"
	if !success {
		color = "#7a3c32"
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.WriteHeader(http.StatusOK)
	if callbackURL == "" {
		callbackURL = h.settings.AppCallbackURL
	}
	_, _ = fmt.Fprintf(w, `<!doctype html><html lang="ru"><meta name="viewport" content="width=device-width,initial-scale=1"><title>%s</title><body style="margin:0;background:#f5f2ea;font-family:system-ui;color:#16231f;display:grid;min-height:100vh;place-items:center"><main style="max-width:420px;padding:32px;text-align:center"><div style="font-size:48px">%s</div><h1 style="color:%s">%s</h1><p style="line-height:1.5">%s</p><a href="%s" style="display:inline-block;margin-top:16px;color:%s">Вернуться в Creative Gym</a></main></body></html>`,
		html.EscapeString(title), map[bool]string{true: "✓", false: "×"}[success], color,
		html.EscapeString(title), html.EscapeString(message), html.EscapeString(callbackURL), color,
	)
}

func normalizeEmail(value string) (string, error) {
	value = strings.ToLower(strings.TrimSpace(value))
	parsed, err := mail.ParseAddress(value)
	if err != nil || strings.ToLower(parsed.Address) != value || len(value) > 254 {
		return "", errors.New("invalid email")
	}
	return value, nil
}

func maskEmail(value string) string {
	parts := strings.Split(value, "@")
	if len(parts) != 2 || len(parts[0]) < 2 {
		return value
	}
	return parts[0][:1] + strings.Repeat("•", min(4, len(parts[0])-1)) + "@" + parts[1]
}

package auth

import (
	"errors"
	"time"

	"github.com/go-webauthn/webauthn/webauthn"
)

var (
	ErrAccountNotFound    = errors.New("account not found")
	ErrTokenNotFound      = errors.New("authentication token not found")
	ErrIdentityInUse      = errors.New("identity belongs to another account")
	ErrCredentialNotFound = errors.New("passkey credential not found")
	ErrRateLimited        = errors.New("authentication request rate limited")
)

type Account struct {
	ID              string
	DisplayName     string
	Email           string
	EmailVerifiedAt *time.Time
	HasYandex       bool
	PasskeyCount    int
	Credentials     []webauthn.Credential
}

func (a Account) EmailVerified() bool { return a.EmailVerifiedAt != nil }
func (a Account) IsGuest() bool {
	return !a.EmailVerified() && !a.HasYandex && a.PasskeyCount == 0
}

func (a Account) WebAuthnID() []byte                         { return []byte(a.ID) }
func (a Account) WebAuthnName() string                       { return a.DisplayName }
func (a Account) WebAuthnDisplayName() string                { return a.DisplayName }
func (a Account) WebAuthnCredentials() []webauthn.Credential { return a.Credentials }

type OAuthState struct {
	UserID       string
	CodeVerifier string
}

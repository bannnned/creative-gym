package auth

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"math"
	"strings"
	"time"

	"github.com/go-webauthn/webauthn/protocol"
	"github.com/go-webauthn/webauthn/webauthn"
	"github.com/jackc/pgx/v5"
)

func (r *Repository) GetAccount(ctx context.Context, userID string) (Account, error) {
	var account Account
	account.ID = userID
	err := r.pool.QueryRow(ctx, `
SELECT
  display_name,
  COALESCE(email, ''),
  email_verified_at,
  EXISTS (
    SELECT 1 FROM auth_identities ai
    WHERE ai.user_id = users.id AND ai.provider = 'yandex'
  ),
  (SELECT count(*)::int FROM passkey_credentials pc WHERE pc.user_id = users.id)
FROM users
WHERE id = $1`, userID).Scan(
		&account.DisplayName,
		&account.Email,
		&account.EmailVerifiedAt,
		&account.HasYandex,
		&account.PasskeyCount,
	)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Account{}, ErrAccountNotFound
		}
		return Account{}, fmt.Errorf("query account: %w", err)
	}

	credentials, err := r.PasskeyCredentials(ctx, userID)
	if err != nil {
		return Account{}, err
	}
	account.Credentials = credentials
	return account, nil
}

func (r *Repository) CreateSessionForUser(
	ctx context.Context,
	userID string,
	tokenHash string,
	expiresAt time.Time,
) error {
	_, err := r.pool.Exec(ctx, `
INSERT INTO sessions (user_id, token_hash, expires_at)
VALUES ($1::uuid, $2, $3)`, userID, tokenHash, expiresAt)
	if err != nil {
		return fmt.Errorf("create account session: %w", err)
	}
	return nil
}

func (r *Repository) StoreEmailToken(
	ctx context.Context,
	currentUserID string,
	email string,
	tokenHash string,
	expiresAt time.Time,
) (string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", fmt.Errorf("begin email token transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	// An address that is already known acts as a sign-in method. A fresh guest
	// can safely switch to that account; a guest with work attached must not be
	// switched silently because that would make the work appear to disappear.
	targetUserID := currentUserID
	var existingUserID string
	err = tx.QueryRow(ctx, `
SELECT id::text
FROM users
WHERE lower(email) = $1
ORDER BY email_verified_at DESC NULLS LAST, created_at
LIMIT 1`, email).Scan(&existingUserID)
	if err == nil {
		targetUserID = existingUserID
	} else if !errors.Is(err, pgx.ErrNoRows) {
		return "", fmt.Errorf("find email account: %w", err)
	}
	if targetUserID != currentUserID {
		canSwitch, switchErr := canSwitchAccount(ctx, tx, currentUserID)
		if switchErr != nil {
			return "", switchErr
		}
		if !canSwitch {
			return "", ErrIdentityInUse
		}
	}

	var sentLastMinute, sentLastHour int
	err = tx.QueryRow(ctx, `
SELECT
  count(*) FILTER (WHERE created_at > now() - interval '1 minute')::int,
  count(*) FILTER (WHERE created_at > now() - interval '1 hour')::int
FROM auth_email_tokens
WHERE user_id = $1::uuid OR email = $2`, targetUserID, email).Scan(&sentLastMinute, &sentLastHour)
	if err != nil {
		return "", fmt.Errorf("check email token rate: %w", err)
	}
	if sentLastMinute > 0 || sentLastHour >= 3 {
		return "", ErrRateLimited
	}

	_, err = tx.Exec(ctx, `
UPDATE auth_email_tokens
SET consumed_at = now()
WHERE user_id = $1::uuid AND consumed_at IS NULL`, targetUserID)
	if err != nil {
		return "", fmt.Errorf("expire prior email tokens: %w", err)
	}

	_, err = tx.Exec(ctx, `
INSERT INTO auth_email_tokens (user_id, email, token_hash, expires_at)
VALUES ($1::uuid, $2, $3, $4)`, targetUserID, email, tokenHash, expiresAt)
	if err != nil {
		return "", fmt.Errorf("store email token: %w", err)
	}

	_, err = tx.Exec(ctx, `
UPDATE users
SET
  email_verified_at = CASE WHEN lower(COALESCE(email, '')) = $2 THEN email_verified_at ELSE NULL END,
  email = $2,
  updated_at = now()
WHERE id = $1::uuid`, targetUserID, email)
	if err != nil {
		return "", fmt.Errorf("store pending email: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return "", fmt.Errorf("commit email token transaction: %w", err)
	}
	return targetUserID, nil
}

func (r *Repository) ConfirmEmailToken(ctx context.Context, tokenHash string) (Account, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return Account{}, fmt.Errorf("begin email confirmation: %w", err)
	}
	defer tx.Rollback(ctx)

	var userID, email string
	err = tx.QueryRow(ctx, `
SELECT user_id::text, email
FROM auth_email_tokens
WHERE token_hash = $1
  AND consumed_at IS NULL
  AND expires_at > now()
FOR UPDATE`, tokenHash).Scan(&userID, &email)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Account{}, ErrTokenNotFound
		}
		return Account{}, fmt.Errorf("find email token: %w", err)
	}

	var existingUserID string
	err = tx.QueryRow(ctx, `
SELECT user_id::text
FROM auth_identities
WHERE provider = 'email' AND provider_user_id = $1`, email).Scan(&existingUserID)
	if err == nil && existingUserID != userID {
		return Account{}, ErrIdentityInUse
	}
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return Account{}, fmt.Errorf("check email identity: %w", err)
	}

	_, err = tx.Exec(ctx, `
INSERT INTO auth_identities (user_id, provider, provider_user_id, email)
VALUES ($1::uuid, 'email', $2, $2)
ON CONFLICT (provider, provider_user_id) DO UPDATE
SET updated_at = now()`, userID, email)
	if err != nil {
		return Account{}, fmt.Errorf("attach email identity: %w", err)
	}

	_, err = tx.Exec(ctx, `
UPDATE users
SET email = $2, email_verified_at = now(), updated_at = now()
WHERE id = $1::uuid`, userID, email)
	if err != nil {
		return Account{}, fmt.Errorf("verify account email: %w", err)
	}

	_, err = tx.Exec(ctx, `
UPDATE auth_email_tokens SET consumed_at = now() WHERE token_hash = $1`, tokenHash)
	if err != nil {
		return Account{}, fmt.Errorf("consume email token: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return Account{}, fmt.Errorf("commit email confirmation: %w", err)
	}
	return r.GetAccount(ctx, userID)
}

func (r *Repository) StoreOAuthState(
	ctx context.Context,
	userID string,
	stateHash string,
	codeVerifier string,
	expiresAt time.Time,
) error {
	_, err := r.pool.Exec(ctx, `
INSERT INTO auth_oauth_states (
  user_id, provider, state_hash, code_verifier, expires_at
) VALUES ($1::uuid, 'yandex', $2, $3, $4)`, userID, stateHash, codeVerifier, expiresAt)
	if err != nil {
		return fmt.Errorf("store oauth state: %w", err)
	}
	return nil
}

func (r *Repository) ConsumeOAuthState(ctx context.Context, stateHash string) (OAuthState, error) {
	var state OAuthState
	err := r.pool.QueryRow(ctx, `
UPDATE auth_oauth_states
SET consumed_at = now()
WHERE state_hash = $1
  AND consumed_at IS NULL
  AND expires_at > now()
RETURNING user_id::text, code_verifier`, stateHash).Scan(&state.UserID, &state.CodeVerifier)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return OAuthState{}, ErrTokenNotFound
		}
		return OAuthState{}, fmt.Errorf("consume oauth state: %w", err)
	}
	return state, nil
}

func (r *Repository) AttachYandexIdentity(
	ctx context.Context,
	userID string,
	providerUserID string,
	email string,
	displayName string,
) (string, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return "", fmt.Errorf("begin yandex identity transaction: %w", err)
	}
	defer tx.Rollback(ctx)

	var existingUserID string
	err = tx.QueryRow(ctx, `
SELECT user_id::text FROM auth_identities
WHERE provider = 'yandex' AND provider_user_id = $1`, providerUserID).Scan(&existingUserID)
	if err == nil {
		if existingUserID != userID {
			canSwitch, switchErr := canSwitchAccount(ctx, tx, userID)
			if switchErr != nil {
				return "", switchErr
			}
			if !canSwitch {
				return "", ErrIdentityInUse
			}
		}
		if err := tx.Commit(ctx); err != nil {
			return "", fmt.Errorf("commit existing yandex identity: %w", err)
		}
		return existingUserID, nil
	}
	if !errors.Is(err, pgx.ErrNoRows) {
		return "", fmt.Errorf("check yandex identity: %w", err)
	}

	targetUserID := userID
	if email != "" {
		err = tx.QueryRow(ctx, `
SELECT id::text FROM users WHERE lower(email) = lower($1) LIMIT 1`, email).Scan(&existingUserID)
		if err == nil {
			targetUserID = existingUserID
		} else if !errors.Is(err, pgx.ErrNoRows) {
			return "", fmt.Errorf("find yandex email account: %w", err)
		}
	}
	if targetUserID != userID {
		canSwitch, switchErr := canSwitchAccount(ctx, tx, userID)
		if switchErr != nil {
			return "", switchErr
		}
		if !canSwitch {
			return "", ErrIdentityInUse
		}
	}

	_, err = tx.Exec(ctx, `
INSERT INTO auth_identities (
  user_id, provider, provider_user_id, email, display_name
) VALUES ($1::uuid, 'yandex', $2, NULLIF($3, ''), NULLIF($4, ''))`,
		targetUserID, providerUserID, email, displayName)
	if err != nil {
		return "", fmt.Errorf("attach yandex identity: %w", err)
	}

	_, err = tx.Exec(ctx, `
UPDATE users
SET
  display_name = CASE WHEN $2 = '' THEN display_name ELSE $2 END,
  email = CASE WHEN $3 = '' THEN email ELSE $3 END,
  email_verified_at = CASE WHEN $3 = '' THEN email_verified_at ELSE now() END,
  updated_at = now()
WHERE id = $1::uuid`, targetUserID, displayName, email)
	if err != nil {
		return "", fmt.Errorf("update yandex account: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return "", fmt.Errorf("commit yandex identity: %w", err)
	}
	return targetUserID, nil
}

type accountQueryer interface {
	QueryRow(context.Context, string, ...any) pgx.Row
}

func canSwitchAccount(ctx context.Context, queryer accountQueryer, userID string) (bool, error) {
	var hasAccountData bool
	err := queryer.QueryRow(ctx, `
SELECT
  EXISTS (SELECT 1 FROM auth_identities WHERE user_id = $1::uuid)
  OR EXISTS (SELECT 1 FROM passkey_credentials WHERE user_id = $1::uuid)
  OR EXISTS (SELECT 1 FROM room_members WHERE user_id = $1::uuid)
  OR EXISTS (SELECT 1 FROM submissions WHERE user_id = $1::uuid)
  OR EXISTS (SELECT 1 FROM votes WHERE voter_user_id = $1::uuid)`, userID).Scan(&hasAccountData)
	if err != nil {
		return false, fmt.Errorf("check account activity: %w", err)
	}
	return !hasAccountData, nil
}

func (r *Repository) StoreExchangeCode(
	ctx context.Context,
	userID string,
	codeHash string,
	expiresAt time.Time,
) error {
	_, err := r.pool.Exec(ctx, `
INSERT INTO auth_exchange_codes (user_id, code_hash, expires_at)
VALUES ($1::uuid, $2, $3)`, userID, codeHash, expiresAt)
	if err != nil {
		return fmt.Errorf("store auth exchange code: %w", err)
	}
	return nil
}

func (r *Repository) ConsumeExchangeCode(ctx context.Context, codeHash string) (string, error) {
	var userID string
	err := r.pool.QueryRow(ctx, `
UPDATE auth_exchange_codes
SET consumed_at = now()
WHERE code_hash = $1
  AND consumed_at IS NULL
  AND expires_at > now()
RETURNING user_id::text`, codeHash).Scan(&userID)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return "", ErrTokenNotFound
		}
		return "", fmt.Errorf("consume auth exchange code: %w", err)
	}
	return userID, nil
}

func (r *Repository) SavePasskeyChallenge(
	ctx context.Context,
	challengeID string,
	userID *string,
	purpose string,
	session webauthn.SessionData,
	expiresAt time.Time,
) error {
	data, err := json.Marshal(session)
	if err != nil {
		return fmt.Errorf("encode passkey session: %w", err)
	}
	_, err = r.pool.Exec(ctx, `
INSERT INTO passkey_challenges (
  challenge_id, user_id, purpose, session_data, expires_at
) VALUES ($1, $2::uuid, $3, $4::jsonb, $5)`, challengeID, userID, purpose, data, expiresAt)
	if err != nil {
		return fmt.Errorf("store passkey challenge: %w", err)
	}
	return nil
}

func (r *Repository) ConsumePasskeyChallenge(
	ctx context.Context,
	challengeID string,
	purpose string,
) (*string, webauthn.SessionData, error) {
	var userID *string
	var data []byte
	err := r.pool.QueryRow(ctx, `
UPDATE passkey_challenges
SET consumed_at = now()
WHERE challenge_id = $1
  AND purpose = $2
  AND consumed_at IS NULL
  AND expires_at > now()
RETURNING user_id::text, session_data`, challengeID, purpose).Scan(&userID, &data)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return nil, webauthn.SessionData{}, ErrTokenNotFound
		}
		return nil, webauthn.SessionData{}, fmt.Errorf("consume passkey challenge: %w", err)
	}
	var session webauthn.SessionData
	if err := json.Unmarshal(data, &session); err != nil {
		return nil, webauthn.SessionData{}, fmt.Errorf("decode passkey session: %w", err)
	}
	return userID, session, nil
}

func (r *Repository) StorePasskeyCredential(
	ctx context.Context,
	userID string,
	credential *webauthn.Credential,
) error {
	transports := make([]string, len(credential.Transport))
	for i, transport := range credential.Transport {
		transports[i] = string(transport)
	}
	_, err := r.pool.Exec(ctx, `
INSERT INTO passkey_credentials (
  user_id, credential_id, public_key, attestation_type, transport,
  sign_count, backup_eligible, backup_state
) VALUES ($1::uuid, $2, $3, $4, $5, $6, $7, $8)
ON CONFLICT (credential_id) DO UPDATE SET
  public_key = EXCLUDED.public_key,
  sign_count = EXCLUDED.sign_count,
  backup_eligible = EXCLUDED.backup_eligible,
  backup_state = EXCLUDED.backup_state`,
		userID,
		credential.ID,
		credential.PublicKey,
		credential.AttestationType,
		transports,
		credential.Authenticator.SignCount,
		credential.Flags.BackupEligible,
		credential.Flags.BackupState,
	)
	if err != nil {
		return fmt.Errorf("store passkey credential: %w", err)
	}
	return nil
}

func (r *Repository) PasskeyCredentials(ctx context.Context, userID string) ([]webauthn.Credential, error) {
	rows, err := r.pool.Query(ctx, `
SELECT
  credential_id,
  public_key,
  attestation_type,
  transport,
  sign_count,
  backup_eligible,
  backup_state
FROM passkey_credentials
WHERE user_id = $1::uuid
ORDER BY created_at`, userID)
	if err != nil {
		return nil, fmt.Errorf("query passkey credentials: %w", err)
	}
	defer rows.Close()

	var credentials []webauthn.Credential
	for rows.Next() {
		var credential webauthn.Credential
		var transports []string
		var signCount int64
		if err := rows.Scan(
			&credential.ID,
			&credential.PublicKey,
			&credential.AttestationType,
			&transports,
			&signCount,
			&credential.Flags.BackupEligible,
			&credential.Flags.BackupState,
		); err != nil {
			return nil, fmt.Errorf("scan passkey credential: %w", err)
		}
		if signCount < 0 || signCount > math.MaxUint32 {
			return nil, fmt.Errorf("passkey sign count is out of range")
		}
		credential.Authenticator.SignCount = uint32(signCount)
		credential.Transport = make([]protocol.AuthenticatorTransport, len(transports))
		for i, transport := range transports {
			credential.Transport[i] = protocol.AuthenticatorTransport(transport)
		}
		credentials = append(credentials, credential)
	}
	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("iterate passkey credentials: %w", err)
	}
	return credentials, nil
}

func (r *Repository) AccountByPasskey(
	ctx context.Context,
	credentialID []byte,
	userHandle []byte,
) (Account, error) {
	userID := strings.TrimSpace(string(userHandle))
	if userID == "" {
		return Account{}, ErrAccountNotFound
	}
	var credentialOwner string
	err := r.pool.QueryRow(ctx, `
SELECT user_id::text FROM passkey_credentials WHERE credential_id = $1`, credentialID).Scan(&credentialOwner)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return Account{}, ErrCredentialNotFound
		}
		return Account{}, fmt.Errorf("find passkey owner: %w", err)
	}
	if credentialOwner != userID {
		return Account{}, ErrCredentialNotFound
	}
	return r.GetAccount(ctx, userID)
}

func (r *Repository) UpdatePasskeyCredential(
	ctx context.Context,
	credential *webauthn.Credential,
) error {
	command, err := r.pool.Exec(ctx, `
UPDATE passkey_credentials
SET
  sign_count = $2,
  backup_state = $3,
  last_used_at = now()
WHERE credential_id = $1`, credential.ID, credential.Authenticator.SignCount, credential.Flags.BackupState)
	if err != nil {
		return fmt.Errorf("update passkey credential: %w", err)
	}
	if command.RowsAffected() != 1 {
		return ErrCredentialNotFound
	}
	return nil
}

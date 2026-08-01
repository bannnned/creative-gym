ALTER TABLE users
ADD COLUMN email_verified_at timestamptz;

ALTER TABLE auth_identities
DROP CONSTRAINT auth_identities_provider_check;

ALTER TABLE auth_identities
ADD CONSTRAINT auth_identities_provider_check
CHECK (provider IN ('google', 'yandex', 'github', 'dev', 'email'));

CREATE TABLE auth_email_tokens (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  email text NOT NULL,
  token_hash text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX auth_email_tokens_user_id_idx ON auth_email_tokens(user_id);
CREATE INDEX auth_email_tokens_email_idx ON auth_email_tokens(email);
CREATE INDEX auth_email_tokens_expires_at_idx ON auth_email_tokens(expires_at);

CREATE TABLE auth_oauth_states (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('yandex')),
  state_hash text NOT NULL UNIQUE,
  code_verifier text NOT NULL,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX auth_oauth_states_expires_at_idx ON auth_oauth_states(expires_at);

CREATE TABLE auth_exchange_codes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code_hash text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX auth_exchange_codes_expires_at_idx ON auth_exchange_codes(expires_at);

CREATE TABLE passkey_credentials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  credential_id bytea NOT NULL UNIQUE,
  public_key bytea NOT NULL,
  attestation_type text NOT NULL DEFAULT '',
  transport text[] NOT NULL DEFAULT '{}',
  sign_count bigint NOT NULL DEFAULT 0 CHECK (sign_count >= 0),
  backup_eligible boolean NOT NULL DEFAULT false,
  backup_state boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  last_used_at timestamptz
);

CREATE INDEX passkey_credentials_user_id_idx ON passkey_credentials(user_id);

CREATE TABLE passkey_challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id text NOT NULL UNIQUE,
  user_id uuid REFERENCES users(id) ON DELETE CASCADE,
  purpose text NOT NULL CHECK (purpose IN ('register', 'login')),
  session_data jsonb NOT NULL,
  expires_at timestamptz NOT NULL,
  consumed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX passkey_challenges_expires_at_idx ON passkey_challenges(expires_at);

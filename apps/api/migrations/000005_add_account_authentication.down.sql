DROP TABLE IF EXISTS passkey_challenges;
DROP TABLE IF EXISTS passkey_credentials;
DROP TABLE IF EXISTS auth_exchange_codes;
DROP TABLE IF EXISTS auth_oauth_states;
DROP TABLE IF EXISTS auth_email_tokens;

ALTER TABLE auth_identities
DROP CONSTRAINT auth_identities_provider_check;

ALTER TABLE auth_identities
ADD CONSTRAINT auth_identities_provider_check
CHECK (provider IN ('google', 'yandex', 'github', 'dev'));

ALTER TABLE users
DROP COLUMN IF EXISTS email_verified_at;

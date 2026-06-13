CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE users (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email text UNIQUE,
  display_name text NOT NULL,
  avatar_url text,
  creative_streak integer NOT NULL DEFAULT 0 CHECK (creative_streak >= 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE auth_identities (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider text NOT NULL CHECK (provider IN ('google', 'yandex', 'github', 'dev')),
  provider_user_id text NOT NULL,
  email text,
  display_name text,
  avatar_url text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, provider_user_id)
);

CREATE INDEX auth_identities_user_id_idx ON auth_identities(user_id);

CREATE TABLE sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash text NOT NULL UNIQUE,
  expires_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  revoked_at timestamptz
);

CREATE INDEX sessions_user_id_idx ON sessions(user_id);
CREATE INDEX sessions_expires_at_idx ON sessions(expires_at);

CREATE TABLE challenges (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  kind text NOT NULL DEFAULT 'photo' CHECK (kind IN ('photo', 'music', 'video')),
  title text NOT NULL,
  theme text NOT NULL,
  description text NOT NULL,
  rules jsonb NOT NULL DEFAULT '[]'::jsonb,
  status text NOT NULL CHECK (status IN ('scheduled', 'submitting', 'voting', 'finished', 'cancelled')),
  submission_starts_at timestamptz NOT NULL,
  submission_ends_at timestamptz NOT NULL,
  voting_starts_at timestamptz NOT NULL,
  voting_ends_at timestamptz NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CHECK (submission_starts_at < submission_ends_at),
  CHECK (submission_ends_at <= voting_starts_at),
  CHECK (voting_starts_at < voting_ends_at)
);

CREATE INDEX challenges_status_idx ON challenges(status);
CREATE INDEX challenges_windows_idx ON challenges(submission_starts_at, submission_ends_at, voting_starts_at, voting_ends_at);

CREATE TABLE rooms (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'full', 'closed', 'cancelled')),
  capacity integer NOT NULL DEFAULT 16 CHECK (capacity > 0),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX rooms_challenge_id_idx ON rooms(challenge_id);
CREATE INDEX rooms_challenge_status_idx ON rooms(challenge_id, status);

CREATE TABLE room_members (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (room_id, user_id)
);

CREATE INDEX room_members_user_id_idx ON room_members(user_id);
CREATE INDEX room_members_room_id_idx ON room_members(room_id);

CREATE TABLE submissions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  caption text,
  status text NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'deleted', 'cancelled')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (room_id, user_id)
);

CREATE INDEX submissions_room_id_idx ON submissions(room_id);
CREATE INDEX submissions_user_id_idx ON submissions(user_id);

CREATE TABLE media_objects (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  submission_id uuid NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  kind text NOT NULL CHECK (kind IN ('image', 'audio', 'video')),
  bucket text NOT NULL,
  object_key text NOT NULL,
  content_type text NOT NULL,
  byte_size bigint NOT NULL CHECK (byte_size >= 0),
  width integer CHECK (width IS NULL OR width > 0),
  height integer CHECK (height IS NULL OR height > 0),
  duration_ms integer CHECK (duration_ms IS NULL OR duration_ms >= 0),
  status text NOT NULL DEFAULT 'uploaded' CHECK (status IN ('pending', 'uploaded', 'deleted', 'failed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  deleted_at timestamptz,
  UNIQUE (bucket, object_key)
);

CREATE INDEX media_objects_submission_id_idx ON media_objects(submission_id);

CREATE TABLE votes (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id uuid NOT NULL REFERENCES rooms(id) ON DELETE CASCADE,
  voter_user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  left_submission_id uuid NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  right_submission_id uuid NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  chosen_submission_id uuid NOT NULL REFERENCES submissions(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  CHECK (left_submission_id <> right_submission_id),
  CHECK (chosen_submission_id = left_submission_id OR chosen_submission_id = right_submission_id),
  UNIQUE (voter_user_id, left_submission_id, right_submission_id)
);

CREATE INDEX votes_room_id_idx ON votes(room_id);
CREATE INDEX votes_chosen_submission_id_idx ON votes(chosen_submission_id);

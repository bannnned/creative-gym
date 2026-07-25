ALTER TABLE challenges
ADD COLUMN created_by_user_id uuid REFERENCES users(id) ON DELETE SET NULL;

UPDATE challenges
SET created_by_user_id = '00000000-0000-0000-0000-000000000001'
WHERE created_by_user_id IS NULL
  AND EXISTS (
    SELECT 1
    FROM users
    WHERE id = '00000000-0000-0000-0000-000000000001'
  );

CREATE INDEX challenges_created_by_user_id_idx
ON challenges(created_by_user_id);

CREATE TABLE challenge_covers (
  challenge_id uuid PRIMARY KEY REFERENCES challenges(id) ON DELETE CASCADE,
  bucket text NOT NULL,
  object_key text NOT NULL,
  content_type text NOT NULL CHECK (
    content_type IN ('image/jpeg', 'image/png', 'image/webp')
  ),
  byte_size bigint NOT NULL CHECK (byte_size > 0),
  uploaded_by_user_id uuid NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (bucket, object_key)
);

CREATE INDEX challenge_covers_uploaded_by_user_id_idx
ON challenge_covers(uploaded_by_user_id);

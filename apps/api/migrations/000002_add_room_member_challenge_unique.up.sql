ALTER TABLE room_members ADD COLUMN challenge_id uuid;

UPDATE room_members rm
SET challenge_id = r.challenge_id
FROM rooms r
WHERE rm.room_id = r.id;

ALTER TABLE room_members ALTER COLUMN challenge_id SET NOT NULL;

ALTER TABLE room_members
  ADD CONSTRAINT room_members_challenge_id_fkey
  FOREIGN KEY (challenge_id) REFERENCES challenges(id) ON DELETE CASCADE;

CREATE UNIQUE INDEX room_members_challenge_user_idx ON room_members(challenge_id, user_id);
CREATE INDEX room_members_challenge_id_idx ON room_members(challenge_id);

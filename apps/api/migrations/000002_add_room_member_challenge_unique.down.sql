DROP INDEX IF EXISTS room_members_challenge_id_idx;
DROP INDEX IF EXISTS room_members_challenge_user_idx;

ALTER TABLE room_members DROP CONSTRAINT IF EXISTS room_members_challenge_id_fkey;
ALTER TABLE room_members DROP COLUMN IF EXISTS challenge_id;

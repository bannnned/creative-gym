DROP TABLE IF EXISTS challenge_covers;

DROP INDEX IF EXISTS challenges_created_by_user_id_idx;

ALTER TABLE challenges
DROP COLUMN IF EXISTS created_by_user_id;

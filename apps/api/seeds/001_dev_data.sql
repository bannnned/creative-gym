INSERT INTO users (id, email, display_name, avatar_url, creative_streak)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'dev@creative-gym.local',
  'Dev User',
  NULL,
  0
)
ON CONFLICT (id) DO UPDATE
SET
  email = EXCLUDED.email,
  display_name = EXCLUDED.display_name,
  updated_at = now();

INSERT INTO auth_identities (user_id, provider, provider_user_id, email, display_name)
VALUES (
  '00000000-0000-0000-0000-000000000001',
  'dev',
  'dev-user',
  'dev@creative-gym.local',
  'Dev User'
)
ON CONFLICT (provider, provider_user_id) DO UPDATE
SET
  user_id = EXCLUDED.user_id,
  email = EXCLUDED.email,
  display_name = EXCLUDED.display_name,
  updated_at = now();

INSERT INTO challenges (
  id,
  kind,
  title,
  theme,
  description,
  rules,
  status,
  submission_starts_at,
  submission_ends_at,
  voting_starts_at,
  voting_ends_at
)
VALUES
  (
    '10000000-0000-0000-0000-000000000001',
    'photo',
    'Morning Light',
    'Light and Shadow',
    'Find soft morning light and make one unstaged frame.',
    '["Submit one photo.", "No collage or heavy compositing.", "You can replace the photo before submissions close."]'::jsonb,
    'submitting',
    now() - interval '1 day',
    now() + interval '4 days',
    now() + interval '4 days',
    now() + interval '6 days'
  ),
  (
    '10000000-0000-0000-0000-000000000002',
    'photo',
    'Quiet Motion',
    'City Rhythm',
    'Show movement without rush: a gesture, step, reflection, or pause.',
    '["Show motion through one urban detail.", "Avoid obvious sports scenes.", "Author names stay hidden until voting ends."]'::jsonb,
    'voting',
    now() - interval '6 days',
    now() - interval '1 day',
    now() - interval '1 day',
    now() + interval '1 day'
  ),
  (
    '10000000-0000-0000-0000-000000000003',
    'photo',
    'Small Rituals',
    'Everyday Practice',
    'Photograph a repeated everyday action so it becomes attentive.',
    '["Choose one repeated everyday ritual.", "The frame should work without captions.", "Do not publish other people faces without consent."]'::jsonb,
    'scheduled',
    now() + interval '1 day',
    now() + interval '6 days',
    now() + interval '6 days',
    now() + interval '8 days'
  )
ON CONFLICT (id) DO UPDATE
SET
  title = EXCLUDED.title,
  theme = EXCLUDED.theme,
  description = EXCLUDED.description,
  rules = EXCLUDED.rules,
  status = EXCLUDED.status,
  submission_starts_at = EXCLUDED.submission_starts_at,
  submission_ends_at = EXCLUDED.submission_ends_at,
  voting_starts_at = EXCLUDED.voting_starts_at,
  voting_ends_at = EXCLUDED.voting_ends_at,
  updated_at = now();

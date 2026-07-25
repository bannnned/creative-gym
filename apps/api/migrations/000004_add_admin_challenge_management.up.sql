ALTER TABLE users
ADD COLUMN is_admin boolean NOT NULL DEFAULT false;

INSERT INTO challenges (
  id,
  created_by_user_id,
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
VALUES (
  '10000000-0000-0000-0000-000000000004',
  NULL,
  'photo',
  'Живой тест',
  'Один заметный момент',
  'Тестовый челлендж для проверки загрузки работ и голосования.',
  '["Загрузите одну фотографию.", "Не используйте коллаж.", "Работу можно заменить до конца приема."]'::jsonb,
  'submitting',
  now() - interval '1 hour',
  now() + interval '7 days',
  now() + interval '7 days',
  now() + interval '9 days'
)
ON CONFLICT (id) DO NOTHING;

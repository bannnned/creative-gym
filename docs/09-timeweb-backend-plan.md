# Timeweb Backend And Database Plan

Date: 2026-06-06

This document describes the recommended backend and database setup for Creative
Gym MVP on Timeweb Cloud.

## Recommendation

Start simple:

```text
Flutter mobile app
  -> Go REST API
  -> Managed PostgreSQL
  -> Timeweb S3-compatible Object Storage
```

Do not start with Kubernetes. For the MVP, one API service is enough. Add a
worker later only when background image processing, scheduled phase transitions,
or email jobs become real needs.

## Timeweb Services

Use these Timeweb Cloud services:

- App Platform or a small cloud server for the Go API.
- Managed PostgreSQL for relational data.
- S3-compatible Object Storage for uploaded photos.

Official docs:

- App Platform: https://timeweb.cloud/docs/apps
- PostgreSQL DBaaS: https://timeweb.cloud/docs/dbaas/postgresql/
- S3 Storage: https://timeweb.cloud/docs/s3-storage
- S3 bucket access: https://timeweb.cloud/docs/s3-storage/manage-storage/manage-buckets

## Deployment Shape

### MVP Option A: App Platform

Use this first if it supports the Go service shape cleanly enough.

Why:

- repository-based deploys;
- automatic app restarts;
- technical domain with SSL;
- less server administration.

Expected app:

```text
apps/api
  Dockerfile
  cmd/api/main.go
```

### MVP Option B: Small Cloud Server

Use this if App Platform is limiting for Go, migrations, private networking, or
custom runtime needs.

Run:

- one Go API binary or Docker container;
- Caddy or nginx for TLS/proxy if needed;
- systemd or Docker Compose for restart policy.

Still use Managed PostgreSQL and S3. Do not put production PostgreSQL inside the
same VM unless cost forces it during a private prototype.

## Backend Structure

Target structure:

```text
apps/api/
  cmd/
    api/
      main.go
  internal/
    config/
    http/
    auth/
    users/
    challenges/
    rooms/
    submissions/
    voting/
    results/
    storage/
  migrations/
  Dockerfile
  .env.example
```

Rules:

- one Go API service for MVP;
- REST API first;
- no microservices;
- no GraphQL at the start;
- config through environment variables;
- migrations live in `apps/api/migrations`;
- database access through `pgx` or `sqlc` once queries stabilize.

## Environment Variables

Minimum production config:

```text
APP_ENV=production
HTTP_ADDR=:8080
DATABASE_URL=postgres://...

S3_ENDPOINT=https://s3.twcstorage.ru
S3_REGION=ru-1
S3_BUCKET=creative-gym-media-prod
S3_ACCESS_KEY=...
S3_SECRET_KEY=...

OAUTH_GOOGLE_CLIENT_ID=...
OAUTH_GOOGLE_CLIENT_SECRET=...
OAUTH_YANDEX_CLIENT_ID=...
OAUTH_YANDEX_CLIENT_SECRET=...
OAUTH_GITHUB_CLIENT_ID=...
OAUTH_GITHUB_CLIENT_SECRET=...

SESSION_SECRET=...
PUBLIC_API_BASE_URL=https://api.example.com
```

Keep secrets out of Git. Use Timeweb environment/secret settings or server-side
environment files with restricted permissions.

## Database Design

Use PostgreSQL as the source of truth. Use UUID primary keys.

Initial tables:

```text
users
oauth_identities
challenges
rooms
room_members
submissions
media_objects
votes
```

### `users`

Stores one app user.

Fields:

```text
id uuid primary key
display_name text not null
avatar_url text null
creative_streak int not null default 0
created_at timestamptz not null
updated_at timestamptz not null
```

### `oauth_identities`

Links OAuth providers to users.

Fields:

```text
id uuid primary key
user_id uuid references users(id)
provider text not null
provider_user_id text not null
email text null
created_at timestamptz not null
unique(provider, provider_user_id)
```

### `challenges`

Stores Weekly Workouts.

Fields:

```text
id uuid primary key
title text not null
theme text not null
description text not null
rules text not null
status text not null
submission_starts_at timestamptz not null
submission_ends_at timestamptz not null
voting_starts_at timestamptz not null
voting_ends_at timestamptz not null
created_at timestamptz not null
updated_at timestamptz not null
```

Status values:

```text
scheduled
submitting
voting
finished
cancelled
```

### `rooms`

Stores Gym Rooms for each challenge.

Fields:

```text
id uuid primary key
challenge_id uuid references challenges(id)
status text not null
capacity int not null
created_at timestamptz not null
updated_at timestamptz not null
```

### `room_members`

Stores user membership in a room.

Fields:

```text
id uuid primary key
room_id uuid references rooms(id)
user_id uuid references users(id)
joined_at timestamptz not null
unique(room_id, user_id)
```

Also enforce one room per challenge per user in application logic first. Add a
database-level helper constraint later if needed.

### `submissions`

Stores one submission per user per room.

Fields:

```text
id uuid primary key
room_id uuid references rooms(id)
user_id uuid references users(id)
caption text null
created_at timestamptz not null
updated_at timestamptz not null
deleted_at timestamptz null
unique(room_id, user_id)
```

### `media_objects`

Stores metadata for uploaded photos.

Fields:

```text
id uuid primary key
submission_id uuid references submissions(id)
kind text not null
bucket text not null
object_key text not null
content_type text not null
byte_size bigint not null
width int null
height int null
created_at timestamptz not null
deleted_at timestamptz null
```

Keep object keys private. The API should return short-lived signed URLs or
backend-controlled access URLs.

### `votes`

Stores anonymous pairwise choices.

Fields:

```text
id uuid primary key
room_id uuid references rooms(id)
voter_user_id uuid references users(id)
left_submission_id uuid references submissions(id)
right_submission_id uuid references submissions(id)
chosen_submission_id uuid references submissions(id)
created_at timestamptz not null
unique(voter_user_id, left_submission_id, right_submission_id)
```

The API must reject votes where the voter owns either submission.

## API Endpoints

First useful API slice:

```text
GET    /healthz
GET    /v1/challenges/active
GET    /v1/challenges/{challengeId}
POST   /v1/challenges/{challengeId}/join
GET    /v1/rooms/{roomId}
POST   /v1/rooms/{roomId}/submissions
DELETE /v1/submissions/{submissionId}
POST   /v1/rooms/{roomId}/votes/next-pair
POST   /v1/rooms/{roomId}/votes
GET    /v1/rooms/{roomId}/results
```

Auth endpoints can start with one provider and keep the model ready for all
three:

```text
GET /v1/auth/{provider}/start
GET /v1/auth/{provider}/callback
GET /v1/me
```

## File Upload Flow

Preferred MVP flow:

1. Mobile asks API to create an upload target.
2. API validates room/challenge phase.
3. API creates a private S3 object key.
4. Mobile uploads directly to S3 with a signed URL, or uploads through API for
   the very first implementation.
5. API stores `submission` and `media_objects` rows.
6. Mobile reads previews through API-issued signed read URLs.

Direct signed upload scales better. API-proxy upload is simpler for the first
vertical slice. Pick API-proxy first if speed matters more than upload
efficiency.

## Local Development

Use Docker Compose locally:

```text
postgres
minio
api
```

The mobile app should point to:

```text
http://10.0.2.2:8080
```

when running on the Android emulator.

## First Backend Milestone

Build this before real OAuth/upload:

1. `apps/api` skeleton.
2. `/healthz`.
3. PostgreSQL connection.
4. migrations for `challenges`.
5. seed 2-3 active Weekly Workouts.
6. `GET /v1/challenges/active`.
7. Flutter replaces mock workouts with API data.

That gives the app its first real backend-backed screen while keeping scope
small.

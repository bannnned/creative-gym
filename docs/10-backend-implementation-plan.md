# Backend Implementation Plan

Date: 2026-06-11

This document is the working backend roadmap for Creative Gym MVP. It turns the
product plan into concrete implementation steps for the Go API, PostgreSQL
schema, local infrastructure, and future client integration.

Read this after:

1. `00-project-context.md`
2. `03-technical-rules.md`
3. `04-domain-model.md`
4. `05-mvp-boundaries.md`
5. `07-mvp-plan.md`
6. `09-timeweb-backend-plan.md`

## Current Backend Status

The first backend slice exists in `apps/api`.

The repository currently contains:

- Go API with health/readiness endpoints.
- PostgreSQL migrations and seed data.
- Active challenge endpoints.
- Join challenge and room detail endpoints.
- Flutter prototype scaffold with mock data.
- Product and architecture documentation.

The next backend goal is not the full MVP. The next goal is to keep the API
client-agnostic while the React PWA consumes the active Weekly Workouts, join,
and Gym Room endpoints.

## Backend Goals

### First Vertical Slice

Deliver:

- `apps/api` Go service.
- Local PostgreSQL through Docker Compose.
- Environment-based config.
- Database migrations.
- Seed data for active photo challenges.
- `GET /healthz`.
- `GET /api/v1/challenges/active`.
- `GET /api/v1/challenges/{challengeId}`.
- `POST /api/v1/challenges/{challengeId}/join`.
- `GET /api/v1/rooms/{roomId}`.
- Temporary dev-user mechanism for authenticated actions.

Done when:

- PostgreSQL starts locally.
- API starts locally.
- API connects to PostgreSQL.
- Active challenges are returned from the database.
- A dev user can join a challenge.
- Joining returns a real room id.
- Room details are returned from the database.

### Full MVP Backend

Add after the first slice:

- OAuth identity linking and sessions.
- S3-compatible photo upload flow.
- Submission create/delete/replace.
- Anonymous pairwise voting.
- Basic room results.
- Deployment-ready configuration for Timeweb Cloud.

## Non-Goals For The First Slice

Do not implement yet:

- real OAuth provider flow;
- object storage uploads;
- image processing;
- voting;
- results ranking;
- admin panel;
- background worker;
- Kubernetes;
- GraphQL;
- public social feed.

## Target Structure

```text
apps/api/
  cmd/
    api/
      main.go
  internal/
    config/
    db/
    httpapi/
    auth/
    users/
    challenges/
    rooms/
    submissions/
    voting/
    results/
    storage/
  migrations/
  seeds/
  Dockerfile
  .env.example
```

### Package Responsibilities

`cmd/api`

- starts the HTTP server;
- loads config;
- opens database connection;
- wires handlers, services, and repositories.

`internal/config`

- reads environment variables;
- validates required config;
- exposes typed config values.

`internal/db`

- creates the PostgreSQL connection pool;
- owns shared transaction helpers if they become useful.

`internal/httpapi`

- owns router setup;
- common middleware;
- error response helpers;
- JSON request/response helpers.

`internal/auth`

- first slice: dev-user middleware;
- later: OAuth callbacks, session issuing, token validation.

`internal/challenges`

- challenge repositories;
- active challenge queries;
- challenge detail handler/service.

`internal/rooms`

- room repository;
- join challenge transaction;
- room detail handler/service.

`internal/submissions`, `internal/voting`, `internal/results`, `internal/storage`

- keep empty until their milestone starts, or add minimal stubs only when they
  unblock a real endpoint.

## Local Infrastructure

Use Docker Compose at the repository root:

```text
docker-compose.yml
```

Initial services:

- `postgres`

Add later:

- `minio`
- optional `api` service once Dockerfile exists and local binary flow is stable.

Local API should listen on:

```text
localhost:8080
```

Android emulator should call:

```text
http://10.0.2.2:8080
```

## Environment Variables

Initial `.env.example` for `apps/api`:

```text
APP_ENV=local
HTTP_ADDR=:8080
DATABASE_URL=postgres://creative_gym:creative_gym@localhost:5432/creative_gym?sslmode=disable
DEV_USER_ID=00000000-0000-0000-0000-000000000001
```

Later variables:

```text
S3_ENDPOINT=
S3_REGION=
S3_BUCKET=
S3_ACCESS_KEY=
S3_SECRET_KEY=

OAUTH_GOOGLE_CLIENT_ID=
OAUTH_GOOGLE_CLIENT_SECRET=
OAUTH_YANDEX_CLIENT_ID=
OAUTH_YANDEX_CLIENT_SECRET=
OAUTH_GITHUB_CLIENT_ID=
OAUTH_GITHUB_CLIENT_SECRET=

SESSION_SECRET=
PUBLIC_API_BASE_URL=
```

## Database Strategy

Use PostgreSQL as the source of truth. Use UUID primary keys.

Migrations should live in:

```text
apps/api/migrations/
```

Seed data should live in:

```text
apps/api/seeds/
```

The first schema should include all MVP tables if that stays readable:

- `users`
- `auth_identities`
- `sessions`
- `challenges`
- `rooms`
- `room_members`
- `submissions`
- `media_objects`
- `votes`

It is acceptable to implement endpoints only for users, challenges, rooms, and
room members during the first slice.

### Phase Strategy

Store challenge date fields in the database:

- `submission_starts_at`
- `submission_ends_at`
- `voting_starts_at`
- `voting_ends_at`

Compute the current phase from timestamps in the API response. Keep a stored
`status` for admin/product state:

- `scheduled`
- `submitting`
- `voting`
- `finished`
- `cancelled`

For MVP, status can be seeded and maintained manually. Automated phase jobs are
not needed yet.

## API Rules

### URL Versioning

Use:

```text
/api/v1
```

Keep `/healthz` outside versioning.

### Response Shape

Return stable machine-readable data. Avoid returning final UI copy such as
`"Ostalos 3 dnya"` from the backend.

The client can format:

- deadline labels;
- phase labels;
- participants labels;
- button copy.

### Errors

Use a consistent JSON shape:

```json
{
  "error": {
    "code": "challenge_not_found",
    "message": "Challenge not found."
  }
}
```

The first implementation can keep messages simple. Error `code` is the stable
field clients should rely on.

## First Slice API Contract

### `GET /healthz`

Response:

```json
{
  "status": "ok"
}
```

### `GET /api/v1/challenges/active`

Returns challenges visible in the app.

Response:

```json
{
  "challenges": [
    {
      "id": "uuid",
      "kind": "photo",
      "title": "Morning Light",
      "theme": "Light and Shadow",
      "description": "Find soft morning light without staging the scene.",
      "rules": [
        "Submit one photo.",
        "No collage.",
        "You can replace the photo before submissions close."
      ],
      "status": "submitting",
      "phase": "submission",
      "submission_starts_at": "2026-06-10T00:00:00Z",
      "submission_ends_at": "2026-06-15T00:00:00Z",
      "voting_starts_at": "2026-06-15T00:00:00Z",
      "voting_ends_at": "2026-06-17T00:00:00Z",
      "participant_count": 12,
      "room_capacity": 16,
      "viewer_room_id": null,
      "viewer_has_joined": false
    }
  ]
}
```

### `GET /api/v1/challenges/{challengeId}`

Returns one challenge with the same fields as the list item.

Response:

```json
{
  "challenge": {
    "id": "uuid",
    "kind": "photo",
    "title": "Morning Light",
    "theme": "Light and Shadow",
    "description": "Find soft morning light without staging the scene.",
    "rules": [
      "Submit one photo."
    ],
    "status": "submitting",
    "phase": "submission",
    "submission_starts_at": "2026-06-10T00:00:00Z",
    "submission_ends_at": "2026-06-15T00:00:00Z",
    "voting_starts_at": "2026-06-15T00:00:00Z",
    "voting_ends_at": "2026-06-17T00:00:00Z",
    "participant_count": 12,
    "room_capacity": 16,
    "viewer_room_id": null,
    "viewer_has_joined": false
  }
}
```

### `POST /api/v1/challenges/{challengeId}/join`

First slice auth:

- read `X-Dev-User-Id` if present;
- otherwise use `DEV_USER_ID`.

Behavior:

- if the user already joined this challenge, return the existing room;
- otherwise find an open room with space;
- otherwise create a new room;
- add the user as a room member;
- return the assigned room.

Response:

```json
{
  "room": {
    "id": "uuid",
    "challenge_id": "uuid",
    "challenge_title": "Morning Light",
    "challenge_theme": "Light and Shadow",
    "phase": "submission",
    "participant_count": 1,
    "capacity": 16,
    "viewer_has_submission": false,
    "submission_ends_at": "2026-06-15T00:00:00Z",
    "voting_ends_at": "2026-06-17T00:00:00Z"
  }
}
```

### `GET /api/v1/rooms/{roomId}`

Response:

```json
{
  "room": {
    "id": "uuid",
    "challenge_id": "uuid",
    "challenge_title": "Morning Light",
    "challenge_theme": "Light and Shadow",
    "phase": "submission",
    "participant_count": 12,
    "capacity": 16,
    "viewer_has_submission": false,
    "submission_ends_at": "2026-06-15T00:00:00Z",
    "voting_ends_at": "2026-06-17T00:00:00Z"
  }
}
```

## Join Transaction Rules

Joining a challenge must be transaction-safe.

Algorithm:

1. Start transaction.
2. Lock or check whether the user already has a room in this challenge.
3. If yes, return that room.
4. Find a room for the challenge where members are below capacity.
5. If no room exists, create one.
6. Insert `room_members` row.
7. Commit.

Important:

- one user must not join two rooms for the same challenge;
- room capacity must not be exceeded under concurrent requests;
- repeated join calls should be idempotent from the client perspective.

## Implementation Milestones

### Milestone B1: Git And Documentation Baseline

Deliver:

- initialize Git;
- add backend roadmap;
- update README documentation index.

Done when:

- `git status` works;
- project docs explain the backend order of work.

### Milestone B2: Local API Skeleton

Deliver:

- `apps/api/go.mod`;
- `cmd/api/main.go`;
- config loader;
- HTTP router;
- `/healthz`;
- `apps/api/.env.example`;
- README local backend commands.

Done when:

- `go test ./...` passes;
- `go run ./cmd/api` starts;
- `curl http://localhost:8080/healthz` returns `{"status":"ok"}`.

### Milestone B3: PostgreSQL And Migrations

Deliver:

- root `docker-compose.yml` with PostgreSQL;
- migration runner decision;
- first migration for MVP tables;
- seed data for one dev user and 2-3 challenges.

Done when:

- `docker compose up -d postgres` starts;
- migrations apply to an empty database;
- seed data is queryable.

### Milestone B4: Active Challenges Endpoint

Deliver:

- challenge repository;
- challenge service;
- `GET /api/v1/challenges/active`;
- `GET /api/v1/challenges/{challengeId}`;
- tests for phase calculation and basic handler behavior.

Done when:

- API returns active seed challenges from PostgreSQL;
- response contract matches this document.

### Milestone B5: Join And Room Endpoint

Deliver:

- dev-user auth middleware;
- room repository;
- join challenge transaction;
- `POST /api/v1/challenges/{challengeId}/join`;
- `GET /api/v1/rooms/{roomId}`;
- tests for repeated join and capacity behavior.

Done when:

- a dev user can join a challenge;
- repeated join returns the same room;
- room details show participant count.

### Milestone B6: React PWA API Integration

Deliver:

- web config for API base URL;
- typed API client;
- challenge queries using the Go API;
- room queries and join mutations using the Go API;
- loading/error states.

Done when:

- React PWA renders active challenges from Go API;
- user can join and open a real backend room.

### Milestone B7: OAuth Foundation

Deliver:

- auth identity tables used by code;
- one provider working locally first;
- session/token issuing;
- authenticated `/api/v1/me`;
- replace dev user where possible.

Done when:

- the PWA can call protected endpoints as a real signed-in user.

### Milestone B8: Photo Submission

Deliver:

- storage abstraction;
- local MinIO;
- upload target endpoint;
- submission create/delete/replace;
- own submission endpoint.

Done when:

- user can upload exactly one photo during submission phase and replace/delete
  it before the deadline.

### Milestone B9: Voting And Results

Deliver:

- vote pair endpoint;
- vote creation endpoint;
- self-vote protection;
- repeated-pair avoidance;
- simple room results endpoint.

Done when:

- user can vote on anonymous pairs during voting phase;
- user can see basic results after voting ends.

## Testing Strategy

Use focused tests first:

- pure unit tests for phase calculation;
- repository tests if database helpers are added;
- handler tests for request/response shape;
- transaction tests for join behavior once feasible.

Baseline command:

```powershell
cd apps/api
go test ./...
```

Later, add integration tests against local PostgreSQL when join/submission/vote
logic becomes risky enough to justify them.

## Documentation Rules During Backend Work

Update docs when:

- API contract changes;
- database table names or fields change;
- milestone order changes;
- local startup commands change;
- auth/upload/voting behavior becomes real.

Do not update docs for internal refactors that do not change behavior or setup.

## Immediate Next Step

Start Milestone B2:

1. Create `apps/api`.
2. Add Go module.
3. Add config loader.
4. Add HTTP server.
5. Add `/healthz`.
6. Verify with `go test ./...` and a local run.

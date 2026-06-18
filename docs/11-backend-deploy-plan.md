# Backend Deploy Plan

Date: 2026-06-18

This document describes the first practical deployment shape for Creative Gym.

## Current Backend Surface

The API is ready to deploy as a dev/staging backend with:

```text
GET  /healthz
GET  /readyz
GET  /api/v1/challenges/active
GET  /api/v1/challenges/{challengeId}
POST /api/v1/challenges/{challengeId}/join
GET  /api/v1/rooms/{roomId}
```

This is enough for a client to connect to a real remote backend for the first
loop:

```text
active challenges -> challenge details -> join -> room details
```

It is not yet a full production MVP because OAuth, upload, voting, and results
are still missing.

## Recommendation

Use Timeweb App Platform first:

```text
Timeweb App Platform
  -> one Dockerfile app
  -> React PWA static files
  -> Go API process
  -> Timeweb Managed PostgreSQL
  -> Timeweb private S3-compatible bucket
```

Why:

- less server administration than a VPS;
- repository-based deploys and auto-deploy;
- managed PostgreSQL physical backups are available;
- object storage is separate from app/container lifecycle;
- the cost difference versus the selected VPS option is small enough to prefer
  the simpler operational model.

Tradeoffs:

- Managed PostgreSQL requires public IPv4 for App Platform access in the
  current setup;
- the deployment needs a production Dockerfile that builds both `apps/web` and
  `apps/api`;
- migrations still need an explicit runbook.

## Selected Timeweb Configuration

Use:

- App Platform Dockerfile app, Moscow, 1 CPU, 2 GB RAM, 30 GB NVMe.
- Managed PostgreSQL, Moscow, 1 CPU, 2 GB RAM, 20 GB NVMe.
- PostgreSQL public IPv4 enabled.
- PostgreSQL physical backups enabled.
- S3-compatible Object Storage, standard class, 10 GB to start.
- S3 bucket type: private.

Approximate selected cost:

```text
App Platform:       810 RUB/month
Managed PostgreSQL: 1090 RUB/month
S3 10 GB:             79 RUB/month
Total:              1979 RUB/month
```

## Alternative VPS Option

Use a VPS only if monthly cost becomes more important than operational
simplicity.

VPS shape:

- Timeweb cloud server;
- Docker Compose on the VPS;
- Caddy for HTTPS;
- PostgreSQL in Docker or Managed PostgreSQL;
- S3 for uploads.

This is not the preferred MVP path now because database backups, server
maintenance, and restore checks become our responsibility.

## Deploy Files

Deploy prep includes:

```text
apps/web/
apps/api/
Dockerfile
deploy/timeweb/app-platform/env.example
```

The production Dockerfile should:

1. Build `apps/web`.
2. Build `apps/api`.
3. Copy the PWA build output into the API runtime image.
4. Start the Go API.
5. Serve React routes with an `index.html` fallback.

This keeps App Platform deployment simple: one app, one domain, one container.

## Local Production Image Check

Build from the repository root:

```bash
docker build -t creative-gym-app .
```

Run against the local Docker Compose PostgreSQL:

```bash
docker run --rm -p 8080:8080 \
  -e APP_ENV=local \
  -e DATABASE_URL="postgres://creative_gym:creative_gym@host.docker.internal:5432/creative_gym?sslmode=disable" \
  -e DEV_USER_ID=00000000-0000-0000-0000-000000000001 \
  creative-gym-app
```

Check:

```bash
curl http://localhost:8080/
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
curl http://localhost:8080/api/v1/challenges/active
```

## App Platform Deploy Steps

1. Create a Timeweb App Platform app from the Git repository.
2. Select Dockerfile environment.
3. Point the app to the production Dockerfile.
4. Configure environment variables.
5. Configure the custom domain when ready.
6. Run migrations and seed data before opening the app to testers.
7. Check health endpoints and first API responses.

Minimum production environment:

```text
APP_ENV=production
HTTP_ADDR=:8080
DATABASE_URL=postgres://...
DEV_USER_ID=00000000-0000-0000-0000-000000000001
CORS_ALLOWED_ORIGINS=
PUBLIC_APP_BASE_URL=https://your-domain.example
PUBLIC_API_BASE_URL=https://your-domain.example
S3_ENDPOINT=...
S3_REGION=...
S3_BUCKET=...
S3_ACCESS_KEY=...
S3_SECRET_KEY=...
```

If PWA and API are served from the same domain, keep `CORS_ALLOWED_ORIGINS`
empty or restrictive. Do not use a wildcard in production.

Use `deploy/timeweb/app-platform/env.example` as the source checklist for App
Platform variables.

Check:

```bash
curl https://your-domain.example/healthz
curl https://your-domain.example/readyz
curl https://your-domain.example/api/v1/challenges/active
```

## Database Migration Rule

Run migrations explicitly before opening a new deployment to users.

First acceptable runbook:

```bash
/app/db migrate
/app/db seed
```

The root production Dockerfile copies `/app/db`, `/app/migrations`, and
`/app/seeds` into the runtime image, so the commands above are available inside
the App Platform container.

## Backup Rule

Keep Managed PostgreSQL physical backups enabled.

Before inviting testers outside the team, add an application-level export path:

- periodic logical `pg_dump`;
- archive dumps outside the database service, preferably S3;
- verify restore manually at least once.

S3 media should use a private bucket. Public buckets are not acceptable for user
photo submissions because room voting depends on controlled, anonymous access.

# Backend Deploy Plan

Date: 2026-06-13

This document describes the first practical deployment shape for the Creative
Gym backend.

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

This is enough for the mobile app to connect to a real remote backend for the
first loop:

```text
active challenges -> challenge details -> join -> room details
```

It is not yet a full production MVP because OAuth, upload, voting, and results
are still missing.

## Recommendation

Use one Timeweb VPS first:

```text
VPS
  -> Caddy HTTPS reverse proxy
  -> Go API container
  -> PostgreSQL container with persistent volume
```

Why:

- cheapest useful setup for a small prototype;
- no public PostgreSQL endpoint;
- one billable compute service;
- easy to replace later with Managed PostgreSQL and S3;
- enough for early mobile integration and internal testing.

Tradeoff:

- PostgreSQL maintenance and backups are on us;
- not the final production architecture;
- if the server dies, API and DB go down together.

Move to App Platform + Managed PostgreSQL when real users or external testers
make reliability more important than monthly cost.

## Timeweb Options

### Cheapest MVP/Staging

Use:

- Timeweb VPS `Cloud MSK 40` or similar;
- Docker Compose on the VPS;
- Caddy for HTTPS;
- PostgreSQL in Docker on the same VPS.

Expected cost baseline from current Timeweb pricing:

- VPS Cloud MSK 40: about `882 ₽/мес` for 2 CPU, 2 GB RAM, 40 GB NVMe.

### More Managed, More Expensive

Use:

- Timeweb App Platform for the Go API via Dockerfile;
- Timeweb Managed PostgreSQL;
- Timeweb S3 later for uploads.

Expected cost baseline from current Timeweb pricing:

- Managed PostgreSQL starts around `790 ₽/мес` for 1 CPU, 2 GB RAM, 20 GB NVMe;
- PostgreSQL public IP is listed as an extra paid option;
- S3 is useful later for photo uploads, with free outbound traffic limit listed
  by Timeweb.

This is cleaner operationally, but likely costs more at the current stage.

## Deploy Files

Backend deploy prep includes:

```text
apps/api/Dockerfile
apps/api/.dockerignore
apps/api/.env.production.example
docker-compose.timeweb-vps.example.yml
deploy/timeweb/vps/.env.example
deploy/timeweb/vps/Caddyfile
```

## VPS Deploy Steps

On the Timeweb VPS:

1. Install Docker and Docker Compose plugin.
2. Clone the repository.
3. Copy env example:

```bash
cp deploy/timeweb/vps/.env.example .env
```

4. Edit `.env`:

```text
API_DOMAIN=api.your-domain.example
POSTGRES_PASSWORD=strong-password
DEV_USER_ID=00000000-0000-0000-0000-000000000001
CORS_ALLOWED_ORIGINS=
```

5. Point DNS `A` record for `API_DOMAIN` to the VPS public IP.
6. Start services:

```bash
docker compose --env-file .env -f docker-compose.timeweb-vps.example.yml up -d --build
```

7. Apply migrations and seed:

```bash
docker compose --env-file .env -f docker-compose.timeweb-vps.example.yml exec api /app/db migrate
docker compose --env-file .env -f docker-compose.timeweb-vps.example.yml exec api /app/db seed
```

8. Check:

```bash
curl https://api.your-domain.example/healthz
curl https://api.your-domain.example/readyz
curl https://api.your-domain.example/api/v1/challenges/active
```

## App Platform Deploy Notes

Use `apps/api/Dockerfile` as the Dockerfile target.

Important constraints:

- App Platform supports Dockerfile-based apps.
- App Platform does not currently read `docker-compose`.
- If using Managed PostgreSQL from App Platform, check networking: if private
  networking is not available for the app, the DB may need a public endpoint.

Set environment variables:

```text
APP_ENV=production
HTTP_ADDR=:8080
DATABASE_URL=postgres://...
DEV_USER_ID=...
CORS_ALLOWED_ORIGINS=
```

Run migrations before opening the app to the mobile client.

## Health Checks

Use:

```text
GET /healthz
```

for process liveness.

Use:

```text
GET /readyz
```

for database readiness.

## Backup Rule

If PostgreSQL runs inside the VPS, add backups before inviting testers outside
the team.

Minimum acceptable backup plan:

- nightly `pg_dump`;
- archive dumps outside the VPS, preferably S3;
- verify restore manually at least once.

Managed PostgreSQL can replace this when reliability matters more than the
extra monthly cost.

# Backend Operations

Last verified: 2026-07-26

This document is the operational source of truth for the currently deployed
Creative Gym backend. It records only non-secret infrastructure facts. Keep
passwords, database URLs, S3 credentials, and other secrets in the VPS `.env`
file, never in Git.

## Current Production-Like Environment

The first remote backend is deployed to a Timeweb Cloud VPS in Moscow.

```text
Public API:       https://creative.gde-kofe.ru
Public IPv4:      147.45.99.61
VPS hostname:     msk-1-vm-11ml
VPS project dir:  /opt/creative-gym
Compose project:  creative-gym
Compose file:     /opt/creative-gym/docker-compose.vps.yml
```

The VPS Compose filename is currently different from the repository template
`docker-compose.timeweb-vps.example.yml`. Treat the VPS file as deployed
configuration and the repository file as a non-secret template until they are
explicitly reconciled.

## Runtime Topology

```text
Flutter app
  -> HTTPS https://creative.gde-kofe.ru
  -> Caddy container, public ports 80 and 443
  -> Go API container, private port 8080
  -> PostgreSQL 16 container, private port 5432
```

Verified containers:

```text
creative-gym-caddy-1      caddy:2-alpine
creative-gym-api-1        creative-gym-api
creative-gym-postgres-1   postgres:16-alpine
```

Caddy terminates TLS and proxies requests to `api:8080`. TLS is managed by
Caddy with Let's Encrypt. PostgreSQL persists its data in a Docker volume.
Only Caddy publishes host ports; API and PostgreSQL stay inside the Compose
network.

## Verified State

- All three containers had been running for four days with zero restarts.
- PostgreSQL reported `healthy`.
- Caddy and API had no Docker healthcheck configured.
- Host load average was `0.02, 0.05, 0.00`.
- Memory: 3.8 GiB total, about 3.2 GiB available.
- Swap: not configured.
- Disk: 48 GiB total, 44 GiB available, 9% used.
- Ports 80 and 443 were listening through `docker-proxy` on IPv4 and IPv6.
- `/healthz`, `/readyz`, and the active-challenges endpoint returned HTTP 200
  from the VPS.
- The certificate for `creative.gde-kofe.ru` was valid and trusted.
- The API container received all five S3 variables and reported
  `s3_enabled=true` and `s3_complete=true`.

There was no evidence of CPU, memory, disk, container restart, database, or TLS
pressure in this snapshot.

The S3 flags confirm that the application created an S3 client with a complete
configuration. A real upload/read/delete smoke test is still required to
confirm bucket permissions and the full object lifecycle.

The upload/read/delete lifecycle was subsequently verified from the Flutter
application on a physical Android device.

On 2026-07-26, both the API container and the public domain reported the exact
production commit through `GET /versionz`.

## Automatic Deployment

The VPS runs `creative-gym-deploy.timer` once per minute. The timer starts
`creative-gym-deploy.service`, which executes
`deploy/timeweb/vps/auto-deploy.sh` directly in the production host
environment.

The deployment script:

1. fetches `origin/main`;
2. refuses to overwrite tracked VPS edits;
3. fast-forwards `/opt/creative-gym`;
4. skips the build when there are no backend changes;
5. rebuilds the `api` image with the exact Git commit;
6. applies pending database migrations;
7. recreates the API and Caddy containers;
8. verifies `/readyz` and the exact `/versionz` commit internally and through
   the public domain.

`.github/workflows/deploy-backend.yml` runs the Go tests and waits for the VPS
timer to publish the exact pushed commit. Docker deployment no longer runs
through the GitHub Actions SSH environment.

Production application secrets remain only in `/opt/creative-gym/.env`.
The one-time timer setup is documented in
`deploy/timeweb/vps/GITHUB_ACTIONS_SETUP.md`.

Only these paths trigger automatic deployment:

```text
apps/api/**
deploy/timeweb/vps/**
docker-compose.timeweb-vps.example.yml
.github/workflows/deploy-backend.yml
```

Flutter changes do not deploy to the VPS.

## Health And API Checks

Run from any machine:

```bash
curl -4 --connect-timeout 5 https://creative.gde-kofe.ru/healthz
curl -4 --connect-timeout 5 https://creative.gde-kofe.ru/readyz
curl -4 --connect-timeout 5 https://creative.gde-kofe.ru/versionz
```

Expected health response:

```json
{"status":"ok"}
```

Current API routes are:

```text
GET    /healthz
GET    /readyz
GET    /versionz
GET    /api/v1/auth/me
GET    /api/v1/admin/status
POST   /api/v1/admin/unlock
POST   /api/v1/admin/challenges
PATCH  /api/v1/admin/challenges/{challengeId}
DELETE /api/v1/admin/challenges/{challengeId}
GET    /api/v1/challenges/active
GET    /api/v1/challenges/{challengeId}
GET    /api/v1/challenges/{challengeId}/cover
PUT    /api/v1/challenges/{challengeId}/cover
DELETE /api/v1/challenges/{challengeId}/cover
POST   /api/v1/challenges/{challengeId}/join
GET    /api/v1/rooms/{roomId}
GET    /api/v1/rooms/{roomId}/submissions/me
POST   /api/v1/rooms/{roomId}/submissions
GET    /api/v1/rooms/{roomId}/votes/next-pair
POST   /api/v1/rooms/{roomId}/votes
GET    /api/v1/rooms/{roomId}/results
DELETE /api/v1/submissions/{submissionId}
GET    /api/v1/submissions/{submissionId}/media
GET    /api/v1/profile/me
```

Challenge covers are stored as private S3 objects under
`challenge-covers/{challengeId}/...`. Migration `000003` adds challenge
ownership and cover metadata. The seeded development user owns the seeded
challenges, so the physical-device API build can exercise cover
create/replace immediately after deployment.

Migration `000004` adds `users.is_admin` and one time-relative test challenge.
Admin access is unlocked from the profile with a private code. Production
stores only its lowercase SHA-256 hash in `ADMIN_ACCESS_CODE_HASH`; the raw
code is never committed or placed in the mobile build. Archiving a challenge
sets `status=cancelled` and preserves its rooms, media, votes, and results.

## Flutter Connection

The mobile app uses the deployed backend by default:

```powershell
flutter run
```

`DATA_SOURCE_MODE=api` exposes backend failures in the UI.
`DATA_SOURCE_MODE=apiWithMockFallback` is useful during development but can
hide remote failures by returning mock data. The "Continue in demo" button is
navigation only and does not select the data source.

Use `--dart-define=DATA_SOURCE_MODE=mock` only for isolated UI development.

## VPS Inspection Runbook

Connect and locate the deployment:

```bash
ssh root@147.45.99.61
cd /opt/creative-gym
docker compose -f docker-compose.vps.yml ps
```

Inspect resource use and listeners:

```bash
uptime
free -h
df -h
docker stats --no-stream
sudo ss -lntp | grep -E ':(80|443|8080)\b' || true
```

Inspect recent logs:

```bash
docker compose -f docker-compose.vps.yml logs \
  --since 30m --tail 300 caddy api postgres
```

Check S3 configuration without printing secret values:

```bash
docker inspect creative-gym-api-1 \
  --format '{{range .Config.Env}}{{println .}}{{end}}' |
awk -F= '/^S3_/ {print $1 "=SET"}'

docker logs creative-gym-api-1 2>&1 |
grep -E 'config loaded|s3_enabled|s3_complete|s3 client'
```

Inspect restart and health state without printing container environment
variables:

```bash
docker inspect --format \
  '{{.Name}} restarts={{.RestartCount}} status={{.State.Status}} health={{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
  $(docker compose -f docker-compose.vps.yml ps -aq)
```

Apply committed database migrations after deploying a version that contains
new migrations:

```bash
docker compose -f docker-compose.vps.yml run --rm api /app/db migrate
```

Do not run `/app/db seed` as a routine deployment step. Use it only when
intentionally creating or refreshing development seed data.

The automated source update/build/restart sequence is defined in
`deploy/timeweb/vps/auto-deploy.sh`. It uses a fast-forward-only Git update and
refuses to overwrite tracked edits made directly on the VPS.

Inspect the automatic deployment:

```bash
systemctl status creative-gym-deploy.timer --no-pager
systemctl status creative-gym-deploy.service --no-pager
journalctl -u creative-gym-deploy.service -n 150 --no-pager
```

## Known Issues And Follow-Ups

### Intermittent External TCP Connection

On 2026-07-24, 4 of 15 requests from the development workstation failed before
TLS with a TCP connect timeout to port 443. Successful requests completed in
about 0.15-0.32 seconds. Requests made on the VPS during inspection succeeded.

This does not look like an overloaded API or database. If it repeats:

1. Run 20 health checks from the workstation and from a second network, such as
   a phone hotspot.
2. Run the same checks locally on the VPS.
3. If VPS-local checks stay reliable but multiple external networks fail,
   inspect the Timeweb firewall/anti-DDoS layer and contact Timeweb support with
   timestamps.
4. If only one external network fails, inspect that network, VPN, proxy, and
   ISP route.

Do not treat a larger Flutter connect timeout as the primary fix.

### Operational Hardening

- Install and verify the VPS systemd deployment timer.
- Add a Docker healthcheck for the API container.
- Decide whether to configure a small swap file on the 4 GiB VPS.
- Configure and verify PostgreSQL backups outside the live Docker volume.
- Verify the restore procedure before inviting external testers.
- Replace dev-user header authentication with OAuth-backed sessions.

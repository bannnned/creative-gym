# Creative Gym API

Go REST API for the Creative Gym MVP.

Current milestone: PostgreSQL-backed active challenges API.

## Local PostgreSQL

From the repository root:

```powershell
docker compose up -d postgres
```

The local database URL is:

```txt
postgres://creative_gym:creative_gym@localhost:5432/creative_gym?sslmode=disable
```

## Migrations And Seeds

Migration strategy for the MVP: use the checked-in Go DB command so local setup
does not depend on a separate `psql` or migration binary.

From `apps/api`:

```powershell
go run ./cmd/db migrate
go run ./cmd/db seed
```

The `migrate` command applies `migrations/*.up.sql` once and records applied
versions in `schema_migrations`.

The `seed` command applies idempotent SQL files from `seeds/`.

## Run Locally

Start PostgreSQL and apply migrations first.

```powershell
cd apps/api
go run ./cmd/api
```

Health check:

```powershell
curl http://localhost:8080/healthz
curl http://localhost:8080/readyz
```

Expected response:

```json
{"status":"ok"}
```

Available challenge endpoints:

```txt
GET /api/v1/challenges/active
GET /api/v1/challenges/{challengeId}
POST /api/v1/challenges/{challengeId}/join
GET /api/v1/rooms/{roomId}
GET /api/v1/rooms/{roomId}/submissions/me
POST /api/v1/rooms/{roomId}/submissions
DELETE /api/v1/submissions/{submissionId}
GET /api/v1/submissions/{submissionId}/media
```

Before OAuth is implemented, API requests use a dev user. The server reads
`X-Dev-User-Id` when present and falls back to `DEV_USER_ID`.

## Test

```powershell
cd apps/api
go test ./...
```

## Environment

Copy `.env.example` values into your local environment when needed.

Initial variables:

- `APP_ENV` - local, test, staging, or production.
- `HTTP_ADDR` - address for the HTTP server, defaults to `:8080`.
- `DATABASE_URL` - PostgreSQL connection string.
- `DEV_USER_ID` - temporary user id for pre-OAuth development.
- `CORS_ALLOWED_ORIGINS` - comma-separated browser origins allowed by CORS.
- `WEB_STATIC_DIR` - optional directory with the built React PWA.
- `S3_ENDPOINT` - S3-compatible endpoint, for example `https://s3.twcstorage.ru`.
- `S3_REGION` - storage region, for example `ru-1`.
- `S3_BUCKET` - private bucket for uploaded media.
- `S3_ACCESS_KEY` - S3 access key.
- `S3_SECRET_KEY` - S3 secret key.
- `S3_ACCESS_KEY_HEX` - optional hex-encoded access key, used when
  `S3_ACCESS_KEY` is empty.
- `S3_SECRET_KEY_HEX` - optional hex-encoded secret key, used when
  `S3_SECRET_KEY` is empty.

S3 is optional at startup. If it is not configured, the API still serves read
routes and returns `object_storage_not_configured` for upload/media routes.
When any S3 variable is set, the full S3 variable set is required.

Photo submissions use a private bucket:

```txt
PWA -> Go API -> S3
PWA <- Go API media proxy <- S3
```

The MVP upload limit is 10 MB. Accepted formats are JPEG, PNG, and WebP.

If the deployment platform has trouble with special characters in secret values,
leave the raw S3 key variable empty and use the matching `_HEX` variable. In
PowerShell:

```powershell
[BitConverter]::ToString([Text.Encoding]::UTF8.GetBytes('secret-value')).Replace('-', '').ToLower()
```

## Docker

Build the backend-only image locally:

```powershell
docker build -t creative-gym-api .
```

Run with environment variables:

```powershell
docker run --rm -p 8080:8080 --env-file .env creative-gym-api
```

The image also contains the DB helper:

```powershell
docker run --rm --env-file .env creative-gym-api /app/db migrate
docker run --rm --env-file .env creative-gym-api /app/db seed
```

For the production app image that includes both React PWA and Go API, use the
root repository `Dockerfile` instead:

```powershell
cd ..\..
docker build -t creative-gym-app .
```

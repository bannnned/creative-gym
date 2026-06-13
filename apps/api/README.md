# Creative Gym API

Go REST API for the Creative Gym MVP.

Current milestone: local API skeleton with PostgreSQL migrations and dev seed
data.

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

```powershell
cd apps/api
go run ./cmd/api
```

Health check:

```powershell
curl http://localhost:8080/healthz
```

Expected response:

```json
{"status":"ok"}
```

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

# Creative Gym API

Go REST API for the Creative Gym MVP.

Current milestone: local API skeleton with `/healthz`.

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
- `DEV_USER_ID` - temporary user id for pre-OAuth development.

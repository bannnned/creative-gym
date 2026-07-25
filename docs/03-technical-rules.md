# Technical Rules

## Stack

Primary client (native mobile app):

- Flutter
- Dart
- `go_router`
- Riverpod
- `dio`

Archived web experiment (kept in `apps/web` as historical reference, not the
product client):

- React
- TypeScript
- Vite
- React Router
- TanStack Query
- PWA manifest and service worker

Backend:

- Go
- REST API
- PostgreSQL
- `pgx` or `sqlc` when appropriate
- S3-compatible storage client
- Docker Compose for local services
- MinIO for local S3-compatible storage if useful

## Repository Direction

Use a full-stack monorepo.

Expected structure:

```txt
apps/
  api/
  web/
  mobile/
docs/
```

The Flutter app structure in `apps/mobile` follows
`08-mobile-architecture-plan.md` (feature-first folders, `core/`, `app/`,
`features/`, `shared/`).

The archived React PWA structure in `apps/web` is documented in
`12-react-pwa-plan.md` for historical reference.

Suggested Go structure:

```txt
apps/api/
  cmd/
    api/
      main.go
    worker/
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
    storage/
    media/
  migrations/
```

## Engineering Rules

1. Keep the first implementation small and reviewable.
2. Do not create microservices.
3. Use one Go API service.
4. Leave room for a worker, but do not build worker logic before it is needed.
5. Prefer readable code over clever abstractions.
6. Avoid heavy code generation at the beginning.
7. Keep product terms consistent across UI, API, database, and docs.
8. Use UUIDs for primary identifiers.
9. Model media generically even though MVP supports only photos.
10. Use environment variables for config.
11. Keep Timeweb Cloud compatibility in mind for App Platform, PostgreSQL, S3-compatible object storage, and Go deployment.
12. Keep the Go API client-agnostic so the Flutter app, the archived web client, or future clients can use the same contract.

## Auth Rule

Full auth can be deferred for the first vertical slice.

If needed, use a temporary dev-user mechanism, but keep the code structured so real auth can be added later.

## Naming Rule

User-facing text can be Russian during early development.

Code identifiers, API fields, database columns, and file names should be English.

# Technical Rules

## Stack

Mobile:

- Flutter
- Dart
- `go_router`
- Riverpod
- `dio`

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
  mobile/
  api/
docs/
```

Suggested Flutter structure:

```txt
apps/mobile/
  lib/
    main.dart
    app/
      app.dart
      router.dart
      theme.dart
    core/
      config/
      network/
      errors/
      utils/
    features/
      challenges/
        data/
        domain/
        presentation/
      rooms/
        data/
        domain/
        presentation/
      submissions/
        data/
        domain/
        presentation/
      voting/
        data/
        domain/
        presentation/
      profile/
        data/
        domain/
        presentation/
```

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
11. Keep Timeweb Cloud compatibility in mind for PostgreSQL, S3-compatible object storage, and Go deployment.

## Auth Rule

Full auth can be deferred for the first vertical slice.

If needed, use a temporary dev-user mechanism, but keep the code structured so real auth can be added later.

## Naming Rule

User-facing text can be Russian during early development.

Code identifiers, API fields, database columns, and file names should be English.

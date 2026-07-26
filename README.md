# Creative Gym

Creative Gym is a native mobile app (Flutter, Android/iOS) for creative workouts, backed by a Go REST API.

The first product direction is photography: users join weekly photo challenges, enter small gym rooms, submit one photo, vote after the deadline, and see results. The product should feel like a calm training habit for creativity, not a popularity contest.

## Current Stage

This repository is a monorepo for the first Creative Gym photography slice.

The Flutter app in `apps/mobile` is the primary and only MVP client
(Android/iOS). Its minimal primary journey is sign in, current assignment,
photo, comparison, and outcome. Challenge, room, and submission state are
combined into one action-focused home screen. OAuth and backend voting/results
rules are not connected yet. Photo submission upload is connected through the
Go API and S3-compatible object storage.

The React PWA in `apps/web` is an archived web experiment: the code stays in
the repository untouched, but it is no longer the product client.

The Go API lives in `apps/api` and is the client-agnostic backend serving the
mobile app: active challenges, joining Gym Rooms, room details, and photo
submissions.

## Documentation

- [Project Context](docs/00-project-context.md) - what the product is and why it exists.
- [Product Rules](docs/01-product-rules.md) - product principles, scope, and anti-goals.
- [Domain Glossary](docs/02-domain-glossary.md) - shared language for product and code.
- [Technical Rules](docs/03-technical-rules.md) - stack, structure, and engineering constraints.
- [Domain Model](docs/04-domain-model.md) - core entities and API direction.
- [MVP Boundaries](docs/05-mvp-boundaries.md) - what the first implementation should and should not include.
- [Collaboration Rules](docs/06-collaboration-rules.md) - how to work on this repo with AI or humans.
- [MVP Plan](docs/07-mvp-plan.md) - planned product scope, milestones, and implementation order.
- [Mobile Architecture Plan](docs/08-mobile-architecture-plan.md) - active plan for the Flutter app, the primary MVP client.
- [Timeweb Backend And Database Plan](docs/09-timeweb-backend-plan.md) - recommended production backend shape.
- [Backend Implementation Plan](docs/10-backend-implementation-plan.md) - working backend roadmap, API contracts, and implementation milestones.
- [Backend Deploy Plan](docs/11-backend-deploy-plan.md) - first Timeweb deployment shape and cost tradeoffs.
- [React PWA Plan](docs/12-react-pwa-plan.md) - archived web frontend direction, kept as historical reference.
- [Backend Operations](docs/13-backend-operations.md) - current Timeweb VPS topology, verified state, health checks, and runbooks.
- [PostgreSQL Backup Setup](deploy/timeweb/vps/BACKUP_SETUP.md) - daily local/S3 backups and restore verification.
- [Simple UX Plan](docs/14-simple-ux-plan.md) - active minimal-interface direction for the Flutter app.

## North Star

Build the smallest clean full-stack vertical slice:

1. Flutter app scaffold.
2. Go API scaffold.
3. PostgreSQL schema and migrations.
4. OAuth account flow.
5. S3-compatible photo upload.
6. Active weekly photo challenges.
7. Join challenge flow that opens a gym room.
8. Submission, anonymous pairwise voting, and room results flow.

Done so far: the Go API through photo submission and the first Timeweb
deployment. Next: mobile API integration polish, OAuth (milestone B7), and
voting/results (milestone B9).

## Current Implementation Order

1. Flutter app scaffold with local mock screens.
2. Go API skeleton with `/healthz`.
3. Local PostgreSQL and migrations.
4. Seed active Weekly Workouts.
5. Active challenges API.
6. Join challenge and Gym Room API.
7. Flutter app integration with the Go API (active challenges, join, room, submission).
8. OAuth, voting, and results milestones.

The detailed backend checklist lives in
[docs/10-backend-implementation-plan.md](docs/10-backend-implementation-plan.md).

## Repository Layout

```text
apps/
  api/     Go REST API (backend for the mobile app)
  mobile/  Flutter app (primary MVP client, Android/iOS)
  web/     React PWA (archived web experiment, code kept untouched)
docs/      product, architecture, and deployment notes
```

## Common Commands

Run Flutter app checks:

```powershell
cd apps/mobile
flutter pub get
flutter analyze
flutter test
```

Run API checks:

```powershell
cd apps/api
go test ./...
```

Web checks (archived client, only if touching `apps/web`):

```powershell
cd apps/web
npm install
npm test
npm run build
```

## Run The Flutter App In Android Studio

Open this folder in Android Studio:

```txt
C:\Users\BANNED\Desktop\prog\creative-gym\apps\mobile
```

Then:

1. Wait for Android Studio to load Flutter and Gradle.
2. Select an Android emulator or connected Android device.
3. Run `lib/main.dart`.

CLI alternative:

```powershell
cd C:\Users\BANNED\Desktop\prog\creative-gym\apps\mobile
flutter pub get
flutter run
```

When the backend is available, point Flutter at the API with dart defines. For
an Android emulator talking to a local API:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=apiWithMockFallback --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

For the currently deployed Timeweb API:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=api --dart-define=API_BASE_URL=https://creative.gde-kofe.ru --dart-define=DEV_USER_ID=00000000-0000-0000-0000-000000000001
```

Useful checks:

```powershell
flutter analyze
flutter test
```

## Run Local Mobile + API Loop

From the repository root, start PostgreSQL:

```powershell
docker compose up -d postgres
```

Apply migrations and seed data:

```powershell
cd apps/api
go run ./cmd/db migrate
go run ./cmd/db seed
```

Start the API:

```powershell
go run ./cmd/api
```

Then run the Flutter app against the local API (see the Flutter section above
for full run options). For an Android emulator:

```powershell
cd apps/mobile
flutter run --dart-define=DATA_SOURCE_MODE=apiWithMockFallback --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

The first local loop is:

```text
/login -> /challenges -> /challenges/:challengeId -> join -> /rooms/:roomId
```

(The archived React PWA previously ran this loop via `npm run dev` in
`apps/web`; that dev-server loop is no longer part of the product setup.)

## Run Production Image Locally

The root `Dockerfile` builds the Go API into one image and also bundles the
archived React PWA, a leftover of the archived web direction. The mobile app
consumes the API directly.

Build:

```powershell
docker build -t creative-gym-app .
```

Run against the local PostgreSQL container:

```powershell
docker run --rm -p 8080:8080 `
  -e APP_ENV=local `
  -e DATABASE_URL="postgres://creative_gym:creative_gym@host.docker.internal:5432/creative_gym?sslmode=disable" `
  -e DEV_USER_ID=00000000-0000-0000-0000-000000000001 `
  -e S3_ENDPOINT=https://s3.twcstorage.ru `
  -e S3_REGION=ru-1 `
  -e S3_BUCKET=creative-gym-media-prod `
  -e S3_ACCESS_KEY=change-me `
  -e S3_SECRET_KEY=change-me `
  creative-gym-app
```

Open:

```text
http://localhost:8080
```

The same container serves the Go API used by the mobile app; the bundled
React PWA is a leftover of the archived web direction:

```text
/                 archived React PWA (legacy)
/api/v1/*         Go API
/healthz          liveness
/readyz           database readiness
```

## Deploy To Timeweb

The current backend is deployed to a Timeweb Cloud VPS with Docker Compose:
Caddy on public ports 80/443, the Go API on private port 8080, and PostgreSQL
16 on private port 5432. The public API is:

```text
https://creative.gde-kofe.ru
```

The deployed project directory is `/opt/creative-gym`, and the VPS uses
`docker-compose.vps.yml`. See
[Backend Operations](docs/13-backend-operations.md) for the current topology,
health checks, diagnostics, and known issues. App Platform remains a historical
alternative documented in the deployment plan, not the active environment.

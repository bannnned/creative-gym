# Creative Gym

Creative Gym is a web-first app for creative workouts.

The first product direction is photography: users join weekly photo challenges, enter small gym rooms, submit one photo, vote after the deadline, and see results. The product should feel like a calm training habit for creativity, not a popularity contest.

## Current Stage

This repository is a monorepo for the first Creative Gym photography slice.

The existing Flutter app has local mock screens for login, Weekly Workouts,
challenge details, Gym Room, upload, voting, and results. It is now treated as a
prototype/reference while the MVP client moves to a React PWA in `apps/web`.
OAuth, upload storage, backend voting rules, and full API-backed data are not
connected yet.

The Go API lives in `apps/api` and is being built as the backend slice for
active challenges, joining Gym Rooms, and room details.

## Documentation

- [Project Context](docs/00-project-context.md) - what the product is and why it exists.
- [Product Rules](docs/01-product-rules.md) - product principles, scope, and anti-goals.
- [Domain Glossary](docs/02-domain-glossary.md) - shared language for product and code.
- [Technical Rules](docs/03-technical-rules.md) - stack, structure, and engineering constraints.
- [Domain Model](docs/04-domain-model.md) - core entities and API direction.
- [MVP Boundaries](docs/05-mvp-boundaries.md) - what the first implementation should and should not include.
- [Collaboration Rules](docs/06-collaboration-rules.md) - how to work on this repo with AI or humans.
- [MVP Plan](docs/07-mvp-plan.md) - planned product scope, milestones, and implementation order.
- [Mobile Architecture Plan](docs/08-mobile-architecture-plan.md) - archived Flutter prototype direction.
- [Timeweb Backend And Database Plan](docs/09-timeweb-backend-plan.md) - recommended production backend shape.
- [Backend Implementation Plan](docs/10-backend-implementation-plan.md) - working backend roadmap, API contracts, and implementation milestones.
- [Backend Deploy Plan](docs/11-backend-deploy-plan.md) - first Timeweb deployment shape and cost tradeoffs.
- [React PWA Plan](docs/12-react-pwa-plan.md) - web-first frontend plan and Timeweb deployment direction.

## North Star

Build the smallest clean full-stack vertical slice:

1. React PWA scaffold.
2. Go API scaffold.
3. PostgreSQL schema and migrations.
4. OAuth account flow.
5. S3-compatible photo upload.
6. Active weekly photo challenges.
7. Join challenge flow that opens a gym room.
8. Submission, anonymous pairwise voting, and room results flow.

The next step is to implement the MVP plan in small reviewable milestones.

## Current Implementation Order

1. React PWA scaffold.
2. Go API skeleton with `/healthz`.
3. Local PostgreSQL and migrations.
4. Seed active Weekly Workouts.
5. Active challenges API.
6. Join challenge and Gym Room API.
7. React PWA integration with the Go API.
8. OAuth, upload, voting, and results milestones.

The detailed backend checklist lives in
[docs/10-backend-implementation-plan.md](docs/10-backend-implementation-plan.md).

## Repository Layout

```text
apps/
  api/     Go REST API
  web/     React PWA
  mobile/  Flutter prototype/reference
docs/      product, architecture, and deployment notes
```

## Common Commands

Install web dependencies:

```powershell
cd apps/web
npm install
```

Run Flutter prototype checks:

```powershell
cd apps/mobile
flutter test
```

Run API checks:

```powershell
cd apps/api
go test ./...
```

Run web checks after `apps/web` is scaffolded:

```powershell
cd apps/web
npm test
npm run build
```

Short shell form:

```sh
cd apps/api && go test ./...
cd apps/web && npm run build
```

## Run Flutter Prototype In Android Studio

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

Later, for a hosted Timeweb API:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=api --dart-define=API_BASE_URL=https://api-domain
```

Useful checks:

```powershell
flutter analyze
flutter test
```

## Run Local React PWA Loop

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

In another terminal, start the PWA:

```powershell
cd apps/web
npm install
npm run dev
```

Open:

```text
http://127.0.0.1:5173
```

The first local loop is:

```text
/login -> /challenges -> /challenges/:challengeId -> join -> /rooms/:roomId
```

Vite proxies `/api`, `/healthz`, and `/readyz` to `http://localhost:8080`.

## Run Production Image Locally

The root `Dockerfile` builds both the React PWA and Go API into one image.

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
  creative-gym-app
```

Open:

```text
http://localhost:8080
```

The same container serves the React PWA and the Go API:

```text
/                 React PWA
/api/v1/*         Go API
/healthz          liveness
/readyz           database readiness
```

## Deploy To Timeweb

Keep GitHub as one monorepo. The preferred MVP deployment is one Timeweb App
Platform Dockerfile app that builds the React PWA, builds the Go API, serves
the PWA for non-API routes, and exposes `/api/*` from the API.

Use Timeweb Managed PostgreSQL with physical backups enabled and Timeweb
S3-compatible Object Storage with a private bucket for uploaded photos.

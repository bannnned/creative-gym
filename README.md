# Creative Gym

Creative Gym is a mobile app for creative workouts.

The first product direction is photography: users join weekly photo challenges, enter small gym rooms, submit one photo, vote after the deadline, and see results. The product should feel like a calm training habit for creativity, not a popularity contest.

## Current Stage

This repository now contains the first minimal Flutter mobile scaffold.

The current app screen is a Creative Gym login page with Google, Yandex, and GitHub buttons. OAuth is not connected yet; the buttons show a temporary message.

The repository has been initialized as a Git project. Backend implementation is
planned next; backend code has not been created yet.

## Documentation

- [Project Context](docs/00-project-context.md) - what the product is and why it exists.
- [Product Rules](docs/01-product-rules.md) - product principles, scope, and anti-goals.
- [Domain Glossary](docs/02-domain-glossary.md) - shared language for product and code.
- [Technical Rules](docs/03-technical-rules.md) - stack, structure, and engineering constraints.
- [Domain Model](docs/04-domain-model.md) - core entities and API direction.
- [MVP Boundaries](docs/05-mvp-boundaries.md) - what the first implementation should and should not include.
- [Collaboration Rules](docs/06-collaboration-rules.md) - how to work on this repo with AI or humans.
- [MVP Plan](docs/07-mvp-plan.md) - planned product scope, milestones, and implementation order.
- [Mobile Architecture Plan](docs/08-mobile-architecture-plan.md) - how the Flutter app should grow.
- [Timeweb Backend And Database Plan](docs/09-timeweb-backend-plan.md) - recommended production backend shape.
- [Backend Implementation Plan](docs/10-backend-implementation-plan.md) - working backend roadmap, API contracts, and implementation milestones.

## North Star

Build the smallest clean full-stack vertical slice:

1. Flutter mobile app scaffold.
2. Go API scaffold.
3. PostgreSQL schema and migrations.
4. OAuth account flow.
5. S3-compatible photo upload.
6. Active weekly photo challenges.
7. Join challenge flow that opens a gym room.
8. Submission and anonymous pairwise voting flow.

The next step is to implement the MVP plan in small reviewable milestones.

## Current Implementation Order

1. Backend documentation baseline.
2. Go API skeleton with `/healthz`.
3. Local PostgreSQL and migrations.
4. Seed active Weekly Workouts.
5. Active challenges API.
6. Join challenge and Gym Room API.
7. Mobile integration with the Go API.
8. OAuth, upload, voting, and results milestones.

The detailed backend checklist lives in
[docs/10-backend-implementation-plan.md](docs/10-backend-implementation-plan.md).

## Run Mobile App In Android Studio

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

Useful checks:

```powershell
flutter analyze
flutter test
```

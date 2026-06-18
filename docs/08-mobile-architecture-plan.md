# Mobile Architecture Plan

Date: 2026-06-06

Status: archived prototype direction. The MVP client is now planned as a React
PWA in `apps/web`; see `12-react-pwa-plan.md`. Keep this document as reference
for the existing Flutter prototype and for possible future native apps.

This document defines how the Flutter app should grow from the current login
screen into the MVP described in `07-mvp-plan.md`.

## Architecture Goals

1. Keep the first implementation small and easy to change.
2. Use feature-first folders so product areas stay understandable.
3. Separate UI, state, domain rules, and data access.
4. Avoid broad abstractions before the app has real workflows.
5. Make backend integration replaceable: local stubs first, API repositories
   later, without changing screens.
6. Keep user-facing copy readable and intentionally encoded as UTF-8.

## Target Structure

The app should move toward this structure:

```text
lib/
  main.dart
  app/
    creative_gym_app.dart
    app_router.dart
    app_theme.dart
  core/
    config/
    errors/
    network/
    utils/
  shared/
    widgets/
    presentation/
  features/
    auth/
      data/
      domain/
      presentation/
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
    results/
      data/
      domain/
      presentation/
```

Tests should mirror the feature structure when the feature becomes non-trivial:

```text
test/
  features/
    auth/
    challenges/
```

## Layer Rules

### `app/`

Owns app-wide wiring:

- `MaterialApp` or `MaterialApp.router`;
- global theme;
- router configuration;
- top-level provider scope once Riverpod is added.

`app/` should not contain feature-specific UI.

### `core/`

Owns reusable technical infrastructure:

- API client setup;
- environment/config parsing;
- shared error/failure types;
- small pure utilities.

`core/` must not import feature presentation code.

### `shared/`

Owns reusable UI building blocks that are not specific to one feature:

- buttons;
- empty states;
- loading states;
- layout helpers;
- common text or surface styles.

Do not put business logic in `shared/`.

### `features/*/presentation`

Owns screens, widgets, and UI state adapters for one feature.

Rules:

- no direct HTTP calls;
- no parsing API JSON in widgets;
- no cross-feature imports unless the dependency is explicitly app-level;
- keep screen widgets small enough to test.

### `features/*/domain`

Owns feature concepts and rules:

- entities;
- value objects;
- repository interfaces when useful;
- pure business decisions.

Domain code should be plain Dart and easy to unit test.

### `features/*/data`

Owns external data access:

- API DTOs;
- repository implementations;
- mapping API responses to domain objects;
- local stubs while backend endpoints are not ready.

Data code may depend on `core/network`, but presentation should not.

## Dependency Rules

Planned dependencies from `03-technical-rules.md`:

- `go_router` for navigation;
- Riverpod for state management;
- `dio` for HTTP.

Add them only when the refactor creates a real place for them:

1. `go_router` when the second screen is introduced or when auth needs a route.
2. Riverpod when async state or shared feature state appears.
3. `dio` when the first backend endpoint is consumed.

Avoid code generation at the start unless it removes clear, repeated work.

## State Rules

Use Riverpod for application and feature state once state leaves a single
widget.

Preferred pattern:

- providers live near the feature they support;
- async UI uses `AsyncValue`;
- repositories are exposed as providers;
- screens consume state, but do not own API orchestration.

Avoid global mutable singletons.

## Routing Rules

Use named routes once `go_router` is added.

Initial route plan:

```text
/login
/challenges
/challenges/:challengeId
/rooms/:roomId
/rooms/:roomId/upload
/rooms/:roomId/vote
/rooms/:roomId/results
```

The first refactor can keep `home: LoginScreen()` until there is a second
screen. Do not add routing complexity before it is useful.

## Copy And Naming Rules

User-facing text may be Russian during early development.

Code identifiers, file names, route names, API fields, and database fields must
stay English.

Product terms should follow `01-product-rules.md`. Prefer these terms in UI
when relevant:

- Creative Gym;
- Weekly Workout;
- Gym Room;
- Creative Streak.

All source files with Russian text must be UTF-8. Tests should assert readable
copy, not mojibake.

## UI Rules

Keep the app calm, work-focused, and mobile-first.

Rules:

- centralize colors and text styles in `app_theme.dart`;
- keep repeated controls in `shared/widgets`;
- use feature widgets only for feature-specific UI;
- avoid oversized marketing sections inside app flows;
- keep cards at 8px radius unless a design system later says otherwise;
- ensure buttons and text remain readable on narrow mobile widths.

## Testing Rules

Baseline checks before finishing a change:

```powershell
flutter analyze
flutter test
```

Test focus:

- widget tests for important screens and user-visible states;
- unit tests for domain rules;
- repository tests with fakes once API integration starts.

Do not write brittle tests that only verify implementation details.

## Refactor Plan

### Step 1: Structure Without Behavior Changes

Move the current login screen into the target architecture without changing the
visible UI:

```text
lib/main.dart
lib/app/creative_gym_app.dart
lib/app/app_theme.dart
lib/features/auth/presentation/login_screen.dart
lib/features/auth/presentation/widgets/login_button.dart
```

Keep `home: LoginScreen()` for now.

### Step 2: Add App Routing

Introduce `go_router` when the app has at least one post-login screen.

Start with:

```text
/login
/challenges
```

### Step 3: Add Feature State

Introduce Riverpod when auth/challenges need loading, error, and success
states.

Do not add app-wide state before a feature needs it.

### Step 4: Add API Boundary

Introduce `dio` and repository interfaces when the Go API skeleton exists.

Screens should depend on providers/repositories, not raw HTTP.

### Step 5: Grow Feature By Feature

Build in this order:

1. Auth shell and dev-user fallback if OAuth is not ready.
2. Active Weekly Workouts.
3. Challenge details.
4. Gym Room.
5. Submission upload placeholder, then real upload.
6. Voting.
7. Results.

Each feature should land with its basic tests and a runnable app state.

# React PWA Plan

Date: 2026-06-18

This document defines the new frontend direction for Creative Gym MVP.

## Decision

Build the first public client as a React PWA in `apps/web`.

Keep the existing Flutter app in `apps/mobile` as a prototype/reference for the
current screens and flows. Do not delete it yet, but do not continue the MVP
implementation there unless the product later needs native apps.

The backend remains one client-agnostic Go REST API. It should not contain
PWA-specific, iOS-specific, or Android-specific behavior.

## Why React PWA First

React PWA is the lower-friction path for the first public release:

- users can open the product by link without installing from app stores;
- deployment is simple static assets plus the Go API;
- browser photo upload is enough for the early photo challenge loop;
- web UI iteration is faster while the product shape is still changing;
- native iOS/Android apps can be added later against the same API.

Flutter Web remains a possible path, but React is a better fit now because the
frontend is still small and the product is becoming web-first for MVP.

## Target Structure

```text
apps/
  api/      Go REST API
  web/      React PWA
  mobile/   Frozen Flutter prototype/reference
docs/
```

Suggested web structure:

```text
apps/web/
  src/
    app/
      router.tsx
      providers.tsx
      layout/
    shared/
      api/
      config/
      ui/
      utils/
    features/
      auth/
      challenges/
      rooms/
      submissions/
      voting/
      results/
    main.tsx
  public/
    manifest.webmanifest
    icons/
  index.html
  package.json
  vite.config.ts
```

## Stack

Use:

- Vite;
- React;
- TypeScript;
- React Router;
- TanStack Query;
- a small API client based on `fetch`;
- `vite-plugin-pwa`;
- CSS Modules or plain CSS first.

Avoid Next.js for the MVP unless server-side rendering becomes a real need.
Creative Gym is an app-like workflow, not an SEO-heavy content site.

Avoid adding a heavy design system package before the core loop exists.

## UX Direction

The PWA should feel like a focused app, not a marketing landing page.

Primary screens:

1. Auth screen.
2. Active Weekly Workouts.
3. Challenge details.
4. Gym Room.
5. Photo upload.
6. Pairwise voting.
7. Results.

Design rules:

- mobile-first responsive layout;
- desktop should use constrained app-width content, not stretched cards;
- no public feed;
- no likes/comments;
- no social network mechanics;
- calm workout language;
- clear loading, empty, and error states.

## API Rules

The React app should call the same API intended for future native clients:

```text
GET    /api/v1/challenges/active
GET    /api/v1/challenges/{challengeId}
POST   /api/v1/challenges/{challengeId}/join
GET    /api/v1/rooms/{roomId}
POST   /api/v1/rooms/{roomId}/submissions
DELETE /api/v1/submissions/{submissionId}
GET    /api/v1/rooms/{roomId}/vote-pair
POST   /api/v1/votes
GET    /api/v1/rooms/{roomId}/results
```

The backend returns machine-readable fields. The PWA formats dates, labels,
phase text, and button copy.

## Auth Direction

For the first local vertical slice, the PWA may continue using the temporary
dev-user mechanism already supported by the API.

For the real MVP, use browser-based OAuth:

```text
GET /api/v1/auth/{provider}/start
GET /api/v1/auth/{provider}/callback
GET /api/v1/me
POST /api/v1/auth/logout
```

Prefer an HTTP-only secure session cookie for the PWA. This is simpler and safer
than storing long-lived tokens in browser storage.

## Upload Direction

Use Timeweb S3-compatible Object Storage with a private bucket.

Initial implementation can upload through the Go API if that is faster:

```text
PWA -> Go API -> private S3
```

Later, move to signed upload URLs:

```text
PWA -> Go API asks for upload target
PWA -> S3 uploads object with signed URL
PWA -> Go API confirms submission
```

Client-side image handling:

- restrict accepted file types to JPEG, PNG, and WebP;
- resize/compress before upload when possible;
- enforce a server-side max upload size;
- create preview states before and after upload.

## Deployment Direction

Use Timeweb App Platform as the first managed deployment target.

Recommended production shape:

```text
Timeweb App Platform
  one Dockerfile app
  Go API serves /api/*
  Go API or embedded static server serves React PWA for /*

Timeweb Managed PostgreSQL
  public IPv4 enabled because App Platform requires it in this setup
  physical backups enabled

Timeweb S3-compatible Object Storage
  private bucket
  10 GB standard storage to start
```

Approximate current monthly cost from the selected configuration:

```text
App Platform:       810 RUB
Managed PostgreSQL: 1090 RUB
S3 10 GB:             79 RUB
Total:              1979 RUB/month
```

Keep all services in the same region when possible. The selected setup uses
Moscow for App Platform and PostgreSQL. S3 can start in Saint Petersburg if that
is the available/cheapest option; for 10 users this latency is acceptable.

## Docker Direction

Use one production Dockerfile at the repo root or a dedicated deploy Dockerfile
that can build both parts:

1. Build `apps/web`.
2. Build `apps/api`.
3. Copy the web `dist` into the API runtime image.
4. Run the Go API.
5. Serve static PWA files for non-API routes.

This keeps App Platform deployment simple: one app, one domain, one container.

## Milestones

### W1: Web Scaffold

Deliver:

- `apps/web` Vite React TypeScript app;
- routing skeleton;
- app shell;
- PWA manifest and icons placeholders;
- local env config for API base URL;
- basic test/lint scripts.

Done when the PWA starts locally and renders the auth/challenges route shell.

### W2: API Client And Challenge List

Deliver:

- typed API client;
- TanStack Query setup;
- active challenges screen;
- loading/error/empty states;
- mock fallback only if explicitly useful for local UI work.

Done when the PWA reads active challenges from the Go API.

### W3: Challenge Details And Join

Deliver:

- challenge details route;
- join mutation;
- room navigation after join;
- idempotent repeated join handling in UI.

Done when a user can join a challenge and land in their Gym Room.

### W4: Room And Submission Flow

Deliver:

- room screen;
- photo picker;
- upload progress;
- submitted photo preview;
- delete/replace flow while allowed.

Done when one photo can be uploaded, displayed, deleted, and replaced.

### W5: Voting And Results

Deliver:

- anonymous pairwise voting screen;
- vote submission;
- empty states for low participation;
- room results screen.

Done when the full challenge loop works in the PWA.

### W6: Deployment

Deliver:

- production Dockerfile;
- App Platform environment variable list;
- static fallback for React routes;
- health/readiness checks;
- migration/seed runbook;
- deployment README update.

Done when the PWA and API are available on the Timeweb domain.

## Open Decisions

1. Domain name and final public URL.
2. First OAuth provider to implement.
3. Whether API-proxy upload is enough for MVP or signed URLs should be built
   immediately.
4. Exact max image size and compression settings.
5. Whether CSS Modules or plain CSS should be used for the first scaffold.

# MVP Boundaries

## MVP Objective

Create the first working vertical slice for Creative Gym:

- run the Go API locally;
- run PostgreSQL locally;
- run the React PWA;
- sign in with a supported OAuth provider;
- fetch active photo challenges from the backend;
- open challenge details;
- join a gym room;
- upload exactly one photo during the submission phase;
- delete and replace the photo while submission is open;
- vote through anonymous pairwise comparisons during the voting phase;
- show basic room results after voting ends.

## MVP Must Include

Infrastructure:

- full-stack monorepo structure;
- Docker Compose for PostgreSQL;
- Docker Compose MinIO setup if S3-compatible storage is included in the first pass;
- `.env.example` files;
- README with local startup commands.

Backend:

- Go API skeleton;
- config loading from environment variables;
- PostgreSQL connection;
- migrations directory;
- initial schema for MVP entities;
- seed data for 2-3 active photo challenges;
- OAuth account model for Google, Yandex, and GitHub identities;
- session or token flow for client API requests;
- active challenges endpoint;
- join challenge endpoint;
- room details endpoint;
- S3-compatible upload flow for photo submissions;
- delete/replace submission media during the submission phase;
- pairwise voting endpoint;
- basic results endpoint.

Web:

- React PWA skeleton;
- routing with React Router;
- server state with TanStack Query;
- typed API client;
- PWA manifest and installable app basics;
- auth screens for Google, Yandex, and GitHub sign-in;
- active challenges screen;
- challenge details screen;
- room screen;
- join flow from challenge to room.
- photo picker/upload flow;
- submitted photo state with delete/replace action while the challenge accepts submissions;
- anonymous pairwise voting screen;
- basic results screen.

## MVP May Stub

- rich profile editing;
- advanced vote ranking formula;
- image moderation;
- push notifications;
- production admin tooling.

Stubs should be explicit and easy to replace.

## MVP Must Not Build

- comments;
- subscriptions;
- payments;
- public likes feed;
- complex ranking;
- push notifications;
- music challenges;
- video challenges;
- admin panel;
- AI features;
- social follows;
- chat.

## Definition of Done

The first implementation is done when:

1. Local PostgreSQL starts.
2. Go API starts.
3. React PWA starts.
4. User can sign in through at least one configured OAuth provider locally, with code structured for Google, Yandex, and GitHub.
5. React PWA fetches active challenges from the Go API.
6. User can tap a challenge and join a room.
7. Room screen opens and displays backend room data.
8. User can upload exactly one photo during the 5-day submission phase.
9. User can delete or replace their photo before submissions close.
10. During the 2-day voting phase, user can compare two anonymous submissions and pick the better one.
11. After voting ends, user can see basic room results.
12. README explains how to run everything locally.
13. The codebase is ready for the next step: product polish, moderation, and better scoring.

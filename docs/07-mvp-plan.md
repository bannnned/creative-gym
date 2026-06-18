# MVP Plan

## MVP Goal

Build the first usable Creative Gym product loop for weekly photo workouts:

1. User creates an account or signs in.
2. User sees active weekly photo challenges.
3. User joins a gym room for a challenge.
4. User uploads exactly one photo during the 5-day submission phase.
5. User can delete or replace the photo before submissions close.
6. After submissions close, a 2-day anonymous pairwise voting phase starts.
7. User compares two photos at a time and chooses the stronger one.
8. After voting ends, user sees basic room results.

## Product Scope

### Account

MVP includes account creation through OAuth.

Supported providers:

- Google
- Yandex
- GitHub

The app should not require a password-based login in the MVP.

The backend should support multiple OAuth identities per user in the data model, even if the first implementation only fully verifies one provider locally.

User profile data in MVP:

- display name;
- avatar URL if provided by OAuth;
- creative streak counter prepared in the model;
- account creation date.

### Weekly Photo Challenges

MVP challenge rules:

- each challenge is a photo challenge;
- each challenge has a theme;
- each challenge has a title, description, rules, and dates;
- submission phase lasts 5 days;
- voting phase lasts 2 days;
- results are visible after voting ends.

Challenge statuses:

- `scheduled`
- `submitting`
- `voting`
- `finished`
- `cancelled`

### Gym Rooms

When a user joins a challenge, the backend assigns them to a gym room.

Room rules:

- one challenge can have many rooms;
- one user can join only one room per challenge;
- target room size is small, for example 8-16 participants;
- if an open room has space, join it;
- otherwise create a new room.

### Photo Submission

Submission rules:

- one user can have exactly one submission per room;
- one submission can have one image in the MVP;
- upload is allowed only during the submission phase;
- user can delete their own uploaded photo while submission is still open;
- user can replace the photo by deleting/uploading again or through a replace action;
- after submission closes, photo deletion/replacement is disabled.

Storage direction:

- use S3-compatible object storage;
- use MinIO locally;
- keep object keys private by default;
- serve previews through signed URLs or backend-controlled access;
- model media generically for future audio/video support.

### Voting

Voting starts after the 5-day submission phase and lasts 2 days.

Voting rules:

- no likes;
- no comments;
- no public author names during voting;
- user receives two anonymous submissions;
- user must choose which one is better for the challenge;
- user must not vote on their own submission;
- user should not receive the same pair repeatedly when avoidable;
- voting happens inside the user's room.

MVP can use a simple pair generator:

- select two eligible submissions from the room;
- exclude current user's submission;
- avoid already voted pairs for the same voter;
- if not enough submissions exist, show an empty state.

### Results

MVP results should be simple.

Minimum result data:

- room participants count;
- submissions count;
- user's own submission;
- basic ranking based on pairwise wins;
- challenge completion state.

Avoid public popularity mechanics. Results should feel like workout completion, not a social media leaderboard.

## Screens

### Auth Screen

Purpose:

- let the user sign in with Google, Yandex, or GitHub.

Content:

- Creative Gym name;
- short calm product line;
- provider buttons;
- loading/error states.

### Active Challenges

Purpose:

- show current weekly photo workouts.

Card content:

- title;
- theme;
- short description;
- submission deadline;
- current phase;
- room/join state if known;
- CTA: Join Workout or Open Gym Room.

### Challenge Details

Purpose:

- explain the challenge and let the user join.

Content:

- title;
- theme;
- description;
- rules;
- submission dates;
- voting dates;
- CTA: Join Gym Room.

### Room Screen

Purpose:

- show the user's state inside a challenge room.

Content:

- room status;
- current phase;
- participants count;
- submission deadline or voting deadline;
- upload area during submission phase;
- submitted photo preview if uploaded;
- delete/replace action while allowed;
- CTA to voting when voting is active;
- CTA to results when finished.

### Upload Flow

Purpose:

- allow one photo submission.

Content:

- image picker;
- preview before upload;
- upload progress;
- success state;
- delete/replace option before deadline.

### Voting Screen

Purpose:

- anonymous pairwise comparison.

Content:

- two photo cards;
- no author names;
- choose left/right action;
- progress indicator;
- empty state if no pairs are available.

### Results Screen

Purpose:

- close the weekly workout loop.

Content:

- room completion state;
- user's photo result;
- basic ranked list or grouped outcome;
- encouragement to return for the next weekly workout.

## Backend API Scope

### Health

```txt
GET /health
```

### Auth

```txt
GET  /api/v1/auth/{provider}/start
GET  /api/v1/auth/{provider}/callback
POST /api/v1/auth/logout
GET  /api/v1/me
```

Supported provider path values:

- `google`
- `yandex`
- `github`

Exact browser OAuth mechanics can be adjusted during implementation, but the backend must own provider verification and user identity linking.

### Challenges

```txt
GET  /api/v1/challenges/active
GET  /api/v1/challenges/{challengeId}
POST /api/v1/challenges/{challengeId}/join
```

### Rooms

```txt
GET /api/v1/rooms/{roomId}
```

### Submissions

```txt
POST   /api/v1/submissions/upload-url
POST   /api/v1/submissions
DELETE /api/v1/submissions/{submissionId}
GET    /api/v1/rooms/{roomId}/submissions/me
```

### Voting

```txt
GET  /api/v1/rooms/{roomId}/vote-pair
POST /api/v1/votes
```

### Results

```txt
GET /api/v1/rooms/{roomId}/results
```

## Data Model Additions

Add OAuth identities:

```txt
auth_identities
- id
- user_id
- provider
- provider_user_id
- email
- display_name
- avatar_url
- created_at
- updated_at
```

Add sessions or refresh tokens:

```txt
sessions
- id
- user_id
- token_hash
- expires_at
- created_at
- revoked_at
```

Submission deletion should not require hard-deleting all records immediately.

Preferred direction:

- mark submission/media as `deleted` or `cancelled`;
- remove or invalidate object storage keys if possible;
- keep audit-safe records for consistency.

## Milestones

### Milestone 1: Monorepo And Local Infrastructure

Deliver:

- `apps/web`;
- `apps/api`;
- `docker-compose.yml`;
- PostgreSQL;
- MinIO;
- `.env.example` files;
- local README commands.

Done when:

- local services start;
- API can connect to PostgreSQL;
- `/health` works.

### Milestone 2: Backend Domain Foundation

Deliver:

- migrations for users, profiles, auth identities, sessions, challenges, rooms, participants, submissions, media, votes;
- seed data for 2-3 active photo challenges;
- repository/service structure in Go;
- challenge status calculation or stored status strategy.

Done when:

- database can migrate from empty state;
- active challenges can be queried from seed data.

### Milestone 3: Account And OAuth

Deliver:

- OAuth provider config;
- provider callback handling;
- user creation/linking;
- session/token issuing;
- authenticated `/api/v1/me`;
- React PWA auth state.

Done when:

- user can sign in and the app can call authenticated API routes.

### Milestone 4: Challenge List And Join Flow

Deliver:

- active challenge endpoint;
- challenge details endpoint;
- join endpoint;
- room assignment logic;
- React PWA active challenges screen;
- challenge details screen;
- room screen.

Done when:

- signed-in user can join a weekly workout and see their gym room.

### Milestone 5: Photo Submission

Deliver:

- S3-compatible storage abstraction;
- upload URL endpoint;
- submission creation endpoint;
- user's submission endpoint;
- delete submission endpoint;
- browser image picker;
- upload progress;
- submitted photo preview;
- delete/replace while submission phase is open.

Done when:

- user can upload exactly one photo to a room and delete or replace it before the deadline.

### Milestone 6: Pairwise Voting

Deliver:

- voting phase guard;
- anonymous pair endpoint;
- vote creation endpoint;
- self-vote protection;
- repeated-pair avoidance;
- React PWA voting screen.

Done when:

- during voting phase, user can compare two anonymous room photos and choose one.

### Milestone 7: Basic Results

Deliver:

- simple pairwise win count;
- room results endpoint;
- React PWA results screen;
- empty states for low participation.

Done when:

- after voting ends, user can see room results.

### Milestone 8: MVP Polish

Deliver:

- Russian user-facing copy pass;
- loading/error/empty states;
- basic validation;
- README updates;
- manual QA checklist.

Done when:

- the full MVP loop can be completed locally from sign-in to results.

## Implementation Order

Recommended order:

1. Local infrastructure.
2. Database schema.
3. Go API skeleton.
4. Auth/session foundation.
5. React PWA shell and auth state.
6. Challenge list/details/join.
7. Room screen.
8. S3 upload and submission lifecycle.
9. Pairwise voting.
10. Results.
11. Polish and documentation.

## Open Decisions

These should be decided before or during implementation:

1. Which OAuth provider must work first locally: Google, Yandex, or GitHub.
2. Whether auth starts with HTTP-only browser sessions or a temporary dev-user flow.
3. Exact room size for MVP.
4. Whether challenge phase status is stored in DB or computed from dates.
5. Whether replacing a photo creates a new submission version or updates the existing submission media.
6. Minimal ranking formula for pairwise results.

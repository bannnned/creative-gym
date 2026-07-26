# Creative Gym Mobile

Minimal Flutter app for Creative Gym.

Current state:

- Android project scaffold is generated.
- The primary journey is intentionally small: sign in, choose a challenge,
  current challenge, photo, comparison, and outcome.
- Sign in opens a minimalist challenge list. Each card contains only an author
  cover, title, and remaining time.
- Selecting a card opens the focused challenge screen, which combines the
  relevant room and submission state and exposes only the next useful action.
- `dio` repositories connect challenges, rooms, join, and photo submissions to
  the Go API.
- The upload screen selects a real gallery image, uploads it as multipart data,
  reads its private preview through the API, and supports replace/delete.
- Default data source mode is the production API. Mock mode is enabled
  explicitly for tests and isolated UI work.
- Login has one primary action. In API mode it creates a real guest session,
  stores the token in platform secure storage, and restores it on later runs.
- Challenge covers are read from private S3 through the API and cached in
  memory. Authors can preview the `16:10` crop and replace their own cover.
- Liquid Glass is isolated behind app-owned scaffold and button adapters and
  is used for navigation and actions, not photo content.
- The profile route includes real derived points, prize-place crowns, a
  winners-only work filter, an authenticated three-column gallery, and a
  full-screen swipe viewer in API mode.
- Finished result rows open the author's public profile. Public galleries show
  only completed works, preserving anonymous submission and voting phases.
- The sign-in screen uses a lightweight animated frame deck and respects
  Reduce Motion.
- Comparison loads anonymous S3-backed pairs, records a real vote by tapping
  one of two photos, and avoids the viewer's own work.
- Outcome loads the real room ranking after voting ends, leads with the user's
  own work, and keeps the wider result collapsed.
- Raw API and network exception details are converted into human messages.
- Phone verification will upgrade the current guest instead of replacing the
  account; provider access for a physical person is being confirmed.
- Phone identity is not connected yet; guest progress is ready to be upgraded
  in place later.
- A small profile action unlocks server-verified admin access. Admins can
  create, edit, phase-switch, archive, and change covers for challenges.
- Debug builds expose a secure switcher for the administrator and up to eight
  local QA participants.
  Only the currently authenticated administrator can create another
  participant; saved accounts can be switched without losing their sessions,
  and inactive test entries can be forgotten from the device.

The active interface rules are documented in
`../../docs/14-simple-ux-plan.md`.

## Data Source Modes

Default mode connects to the hosted Timeweb API:

```powershell
flutter run
```

Use mock data explicitly for isolated UI work:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=mock
```

Point API mode at a locally running Go backend:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=api --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=DEV_USER_ID=00000000-0000-0000-0000-000000000001
```

Use API with mock fallback while backend integration is in progress:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=apiWithMockFallback --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

The explicit hosted command is equivalent to the default:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=api --dart-define=API_BASE_URL=https://creative.gde-kofe.ru
```

Submission writes never fall back to mock data, including in
`apiWithMockFallback` mode. This prevents the UI from reporting a successful
upload when the API or S3 is unavailable.

## Open In Android Studio

Open this folder:

```txt
C:\Users\BANNED\Desktop\prog\creative-gym\apps\mobile
```

Then run:

```txt
lib/main.dart
```

Use an Android emulator or connected Android device.

## CLI

```powershell
flutter pub get
flutter run
```

## Checks

```powershell
flutter analyze
flutter test
```

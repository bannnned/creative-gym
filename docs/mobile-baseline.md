# Creative Gym Mobile Baseline

Date: 2026-06-11

This document records the current baseline for the Flutter mobile app before
larger feature work starts. It is a reference point for what exists, what has
been verified, and what should be treated as known technical debt.

## Project Location

Mobile app:

```text
C:\Users\BANNED\Desktop\prog\creative-gym\apps\mobile
```

Flutter SDK:

```text
C:\Users\BANNED\develop\flutter
```

Android SDK:

```text
C:\Users\BANNED\AppData\Local\Android\Sdk
```

The workspace root `creative-gym` is currently not a Git repository, so this
baseline is documented here rather than committed as a Git snapshot.

## Toolchain

Verified Flutter toolchain:

```text
Flutter 3.44.1 stable
Dart 3.12.1
DevTools 2.57.0
```

`flutter doctor -v` result:

```text
No issues found
```

Available Android emulator:

```text
emulator-5554
sdk gphone16k x86 64
Android 17 / API 37
```

## App State

The app is a minimal Flutter Android application named:

```text
creative_gym_mobile
```

Current entry point:

```text
lib/main.dart
```

Current UI:

- `CreativeGymApp` in `lib/app/creative_gym_app.dart` creates a `MaterialApp`.
- `AppTheme` in `lib/app/app_theme.dart` owns the current light theme.
- `LoginScreen` in `lib/features/auth/presentation/login_screen.dart` is the home screen.
- `go_router` is configured in `lib/app/app_router.dart`.
- `/login` opens the login screen.
- `/challenges` opens the local demo Weekly Workouts screen.
- `/challenges/:challengeId` opens the local demo Challenge Details screen.
- `/rooms/:roomId` opens the local demo Gym Room screen.
- `/rooms/:roomId/upload` opens the local demo Upload Photo screen.
- `/rooms/:roomId/vote` opens the local demo Voting screen.
- `/rooms/:roomId/results` opens the local demo Results screen.
- `?demo=1` can be used on Voting and Results routes to bypass phase guards
  for local UI testing.
- The screen contains a brand header, a login panel, and a footer note.
- Login provider buttons exist for Google, Yandex, and GitHub.
- Provider buttons are placeholders and show a `SnackBar`; OAuth is not wired.
- The demo flow uses local mock Weekly Workout data until the Go API exists.
- Weekly Workouts are grouped by phase: submission, voting, results, and
  upcoming.
- The demo Gym Room uses phase-aware actions for upload, voting, and results,
  plus explicit demo shortcuts for local testing.
- The demo Upload Photo flow supports local placeholder states for no photo,
  selected photo, saved photo, replace, and delete. It is not connected to S3
  yet. Direct route access is guarded outside the submission phase.
- The demo Voting flow supports local anonymous pairwise comparison, progress,
- vote count, selected-card feedback, skip pair, and a completion state. Direct
  route access is guarded outside the voting phase. It is not connected to
  backend voting rules yet.
- The demo Results flow supports local completion copy, the user's own
  submission result, and a small mock ranking. Direct route access is guarded
  until the results phase.
- `core/config`, `core/network`, and repository implementations now prepare
  the app for `GET /api/v1/challenges/active`, challenge details, join, and
  room details. Default mode still uses local mocks.
- The current visual direction uses a soft glass aesthetic: shared gradient
  background, subtle film grain overlay, translucent panels, compact chips, and
  restrained green/copper accents. Primary actions use custom gradient glass
  buttons, and Weekly Workout cards use photo-led headers with overlaid title,
  status, and a soft fade into the content area instead of plain Material list
  cards.

Current Android package/application id:

```text
com.creativegym.mobile
```

Current Android label:

```text
Creative Gym
```

## Dependencies

Runtime dependencies are minimal:

```text
flutter sdk
cupertino_icons
dio
go_router
```

Dev dependencies:

```text
flutter_test
flutter_lints
```

There is no state management package, networking client, auth SDK, local
database, or asset pipeline configured yet.

## Verification

The following commands were run from `apps/mobile`:

```powershell
flutter analyze
flutter test
flutter run -d emulator-5554 --no-resident
```

Results:

```text
flutter analyze: No issues found
flutter test: All tests passed
flutter run: debug APK built, installed, and launched on emulator-5554
```

## Known Technical Debt

Resolved on 2026-06-06: Russian UI strings in `lib/main.dart` and
`test/widget_test.dart` were converted from mojibake text to readable UTF-8
Russian copy. Tests now assert readable labels.

`AndroidManifest.xml` contains:

```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="false" />
```

Flutter 3.44.1 reports this as a deprecated Impeller opt-out. This is not an
environment issue, but it should be removed or intentionally revisited before
the rendering path becomes important.

The release build still uses the debug signing config. This is acceptable for
local development, but it is not production-ready.

The app currently has no real authentication, backend integration, persistence,
or navigation structure beyond the initial login screen.

## Current Mobile Structure

The first architecture split from `08-mobile-architecture-plan.md` is in place:

```text
lib/main.dart
lib/core/app_dependencies.dart
lib/core/config/app_config.dart
lib/core/errors/api_exception.dart
lib/core/network/api_client.dart
lib/core/utils/challenge_labels.dart
lib/app/app_router.dart
lib/app/creative_gym_app.dart
lib/app/app_theme.dart
lib/features/auth/presentation/login_screen.dart
lib/features/auth/presentation/widgets/login_button.dart
lib/features/challenges/data/mock_weekly_workouts.dart
lib/features/challenges/data/mock_challenges_repository.dart
lib/features/challenges/data/api_challenges_repository.dart
lib/features/challenges/data/fallback_challenges_repository.dart
lib/features/challenges/data/dto/challenge_dto.dart
lib/features/challenges/data/mappers/challenge_mapper.dart
lib/features/challenges/domain/challenges_repository.dart
lib/features/challenges/domain/weekly_workout.dart
lib/features/challenges/presentation/challenge_details_screen.dart
lib/features/challenges/presentation/weekly_workouts_screen.dart
lib/features/results/data/mock_room_results.dart
lib/features/results/domain/room_result.dart
lib/features/results/presentation/results_screen.dart
lib/features/rooms/data/mock_gym_rooms.dart
lib/features/rooms/data/mock_rooms_repository.dart
lib/features/rooms/data/api_rooms_repository.dart
lib/features/rooms/data/fallback_rooms_repository.dart
lib/features/rooms/data/dto/room_dto.dart
lib/features/rooms/data/mappers/room_mapper.dart
lib/features/rooms/domain/rooms_repository.dart
lib/features/rooms/domain/gym_room.dart
lib/features/rooms/presentation/gym_room_screen.dart
lib/features/submissions/presentation/upload_submission_screen.dart
lib/features/voting/data/mock_vote_pairs.dart
lib/features/voting/domain/vote_pair.dart
lib/features/voting/presentation/voting_screen.dart
lib/shared/widgets/app_background.dart
lib/shared/widgets/app_scaffold.dart
lib/shared/widgets/glass_button.dart
lib/shared/widgets/glass_panel.dart
```

## Next Recommended Step

Build the first Go API slice described in `09-timeweb-backend-plan.md`, then
replace `mockWeeklyWorkouts` with data from `GET /v1/challenges/active`.
Keep the current phase-aware frontend flow as the local demo baseline while API
integration is being added.

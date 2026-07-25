# Creative Gym Mobile

Minimal Flutter app for Creative Gym.

Current state:

- Android project scaffold is generated.
- Login, Weekly Workouts, Challenge Details, Gym Room, Upload, Voting, and
  Results screens are implemented.
- `dio` repositories connect challenges, rooms, join, and photo submissions to
  the Go API.
- The upload screen selects a real gallery image, uploads it as multipart data,
  reads its private preview through the API, and supports replace/delete.
- Default data source mode is `mock`; API mode is enabled via `--dart-define`.
- Google, Yandex, and GitHub buttons are UI placeholders.
- Weekly Workouts are grouped by phase: submission, voting, results, and
  upcoming.
- Gym Room actions are phase-aware and include demo shortcuts for local testing.
- Voting supports card tap selection, selected-state feedback, skip pair, local
  progress, and a completion state.
- Results use local mock rankings and completion copy.
- Real OAuth will be connected in a later milestone.
- OAuth and real voting/results rules are not connected yet.

## Data Source Modes

Default mode is local mock data:

```powershell
flutter run
```

Try API mode when the Go backend is running locally:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=api --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=DEV_USER_ID=00000000-0000-0000-0000-000000000001
```

Use API with mock fallback while backend integration is in progress:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=apiWithMockFallback --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Point the app at the hosted Timeweb API:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=api --dart-define=API_BASE_URL=https://creative.gde-kofe.ru --dart-define=DEV_USER_ID=00000000-0000-0000-0000-000000000001
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

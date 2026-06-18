# Creative Gym Mobile

Minimal Flutter app for Creative Gym.

Current state:

- Android project scaffold is generated.
- Login, Weekly Workouts, Challenge Details, Gym Room, Upload, Voting, and
  Results demo screens are implemented.
- `dio` client and repository layer are prepared for backend integration.
- Default data source mode is `mock`; API mode can be enabled later via
  `--dart-define`.
- Google, Yandex, and GitHub buttons are UI placeholders.
- Weekly Workouts are grouped by phase: submission, voting, results, and
  upcoming.
- Gym Room actions are phase-aware and include demo shortcuts for local testing.
- Voting supports card tap selection, selected-state feedback, skip pair, local
  progress, and a completion state.
- Results use local mock rankings and completion copy.
- Real OAuth will be connected in a later milestone.
- Backend data, S3 upload, and real voting rules are not connected yet.

## Data Source Modes

Default mode is local mock data:

```powershell
flutter run
```

Try API mode when the Go backend is running locally:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=api --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Use API with mock fallback while backend integration is in progress:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=apiWithMockFallback --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

Later, point the app at the hosted Timeweb API:

```powershell
flutter run --dart-define=DATA_SOURCE_MODE=api --dart-define=API_BASE_URL=https://api-domain
```

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

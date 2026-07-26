# Android Release Signing

`com.creativegym.mobile` is the permanent Android package ID.

Release builds use a dedicated RSA release key. They must never fall back to
Flutter's debug key.

## Local setup

From PowerShell:

```powershell
cd apps/mobile
.\tools\setup-release-signing.ps1
```

The script:

- creates `android/app/creative-gym-release.jks`;
- creates the ignored local `android/key.properties`;
- generates a strong random password without printing it;
- creates a DPAPI-protected local backup in
  `Documents\CreativeGymReleaseSigningBackup`;
- records certificate fingerprints next to the backup.

Both signing files are ignored by Git. The DPAPI password backup can only be
opened by the Windows user that created it.

The Documents copy is protection against an accidental repository cleanup, not
against disk or account loss. Before distributing the application:

1. copy the keystore into an encrypted vault on a different device or cloud
   provider;
2. save `storePassword`, `keyPassword`, and `keyAlias` from
   `android/key.properties` in a password manager;
3. record who can access the signing material;
4. never send `key.properties` through chat or commit it to Git.

## Build

The canonical app version lives in `pubspec.yaml`:

```yaml
version: 1.0.0+1
```

The number after `+` becomes Android's `versionCode` and must increase for
every distributed update.

Build an APK:

```powershell
flutter build apk --release
```

Build an Android App Bundle for a store:

```powershell
flutter build appbundle --release
```

Gradle stops a release build with a clear error when `key.properties` is
missing. Debug builds remain independent.

## Update smoke test

Never uninstall between these steps:

1. build and install release `1.0.0+1`;
2. change the version to `1.0.0+2`;
3. build the second release;
4. run `adb install -r path\to\app-release.apk`;
5. open the app and confirm that the local session is still present.

If a debug-signed build with the same package ID is already installed, Android
will reject the first release install. Removing that debug build clears its
local app data, so do this only on a test device after confirming the session
can be recreated.

## Distribution

For a small closed test, a directly shared signed APK is sufficient. For a
larger group, prefer a closed testing track in the chosen store. If Google Play
App Signing is enabled later, preserve this keystore as the upload key and
follow the store's key-management procedure.

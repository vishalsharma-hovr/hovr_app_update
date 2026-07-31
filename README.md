# hovr_app_update

Native **Update Required** dialog for HOVR Flutter apps — store force-update **and** Shorebird OTA restart — with a once-per-process session policy.

## API

```dart
await HovrAppUpdate.configure(
  AppUpdateConfig(
    iosAppStoreId: '1585783552',
    // Optional: enables Shorebird OTA (same popup; Update restarts the app)
    isSafeToPromptOtaRestart: () => !hasActiveTrip,
    onOtaError: (error, stack) { /* log */ },
  ),
);

// Full package info (replaces package_info_plus)
final info = await HovrAppUpdate.getAppInfo();

// Store force-update (opens Play / App Store on Update)
await HovrAppUpdate.promptIfUpdateRequired(serverVersion: remoteVersion);

// Shorebird OTA (check/download; same dialog; Update restarts process)
await HovrAppUpdate.checkForOtaAndPromptIfReady();
```

Hosts must set `auto_update: false` in their own `shorebird.yaml`. OTA is a no-op on non-Shorebird / debug builds.

## Session behavior

- Dialog shows at most **once per app process** (store **or** OTA).
- Skipping dismisses the dialog; it does not reappear until the app is force-quit and reopened.
- A store check that does **not** show a dialog does not block a later OTA prompt.

## Local development

```yaml
hovr_app_update:
  path: ../../Documents/hovr-packages/hovr_app_update
```

## Validation

```bash
cd ~/Documents/hovr-packages/hovr_app_update
dart analyze --fatal-warnings lib test
flutter test
cd android && ./gradlew testDebugUnitTest
```

## Publishing

Bump `version`, tag (e.g. `v0.2.0`), publish to GitHub, pin consumer apps to the new git `ref`.

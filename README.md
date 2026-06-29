# hovr_app_update

Native update-required dialog for HOVR Flutter apps with a once-per-process session policy.

## API

```dart
await HovrAppUpdate.configure(
  const AppUpdateConfig(iosAppStoreId: '1585783552'),
);

await HovrAppUpdate.promptIfUpdateRequired(
  serverVersion: remoteVersion,
);
```

Call `configure` once during app startup. Call `promptIfUpdateRequired` after fetching the server version from your IAM/API layer.

## Session behavior

- Dialog shows at most **once per app process**.
- Skipping or updating dismisses the dialog; it does not reappear until the app is force-quit and reopened.
- Background/resume does not reset the session guard.

## Local development (rider app)

```yaml
dependency_overrides:
  hovr_app_update:
    path: packages/hovr_app_update
```

## Validation

```bash
cd packages/hovr_app_update
dart analyze --fatal-warnings lib test
flutter test
cd android && ./gradlew testDebugUnitTest
```

## Manual QA sign-off (before GitHub publish)

| # | Scenario | Expected |
|---|----------|----------|
| 1 | Cold start, outdated version | Dialog once |
| 2 | Tap Skip, navigate tabs | No dialog |
| 3 | Kill app from recents, reopen | Dialog once again |
| 4 | Background 5 min, resume | No dialog |
| 5 | Home remount / hot restart | No duplicate dialog same session |
| 6 | Current version matches server | No dialog |
| 7 | Channel failure (no activity) | No crash; may retry on next bootstrap |

## Publishing

Keep the package local until QA sign-off. Publish to GitHub and switch consumer apps from `path` override to a pinned `git` ref.

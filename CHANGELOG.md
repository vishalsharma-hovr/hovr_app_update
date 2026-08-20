## 0.2.4

- `checkForOtaAndPromptIfReady` returns [OtaUpdateStatus] so hosts can show the
  real Shorebird result (up to date / restart required / unavailable).

## 0.2.3

- `downloadUpdateIfAvailable` logs status and cold-start apply note (silent OTA).

## 0.2.2

- Add `HovrAppUpdate.isOtaAvailable` so hosts can tell a Shorebird release build
  from a plain `flutter build` (where patches can never apply).
- Log OTA diagnostics: updater availability, booted patch, check status, track,
  download completion, deferred restart, and prompt result.

## 0.2.1

- Separate once-per-session guards for store vs OTA prompts (store no longer blocks OTA).
- Optional `AppUpdateConfig.promptOtaRestart` host callback (Flutter dialog) instead of native-only OTA UI.
- iOS: walk presented VC chain / foreground window when showing native dialogs.

## 0.2.0

- Combine Shorebird OTA into this package (replaces standalone `hovr_shorebird`).
- Same native "Update Required" dialog for store force-update and OTA restart.
- New APIs: `checkForOtaAndPromptIfReady`, `downloadOtaUpdateIfAvailable`, `currentOtaPatchNumber`.
- `AppUpdateConfig` optional OTA fields: `isSafeToPromptOtaRestart`, `onOtaError`, `otaTrack`.
- Session guard only locks after a dialog is actually shown (store or OTA).

## 0.1.2

- Add `HovrAppUpdate.getAppInfo()` returning `AppInfo` (appName, packageName, version, buildNumber).
- Replaces the need for `package_info_plus` in consumer apps.

## 0.1.1

- Add `HovrAppUpdate.getInstalledVersion()` (Android `versionName` / iOS `CFBundleShortVersionString`).

## 0.1.0

- Initial release: native update dialog, once-per-session guard, Android Compose + iOS alert.

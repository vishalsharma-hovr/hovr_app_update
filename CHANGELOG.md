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

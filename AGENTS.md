# hovr_app_update agent notes

- Plugin scope: installed version read, version compare, native dialog (store open **or** process restart for OTA), session guard, optional Shorebird OTA check/download.
- Apps own IAM `getAppVersion`, bootstrap timing, and OTA safety (`isSafeToPromptOtaRestart`).
- Channel name: `hovr_app_update`.
- Methods: `configure`, `promptIfUpdateRequired`, `promptRestartToApplyUpdate`, `getInstalledVersion`, `getAppInfo`.
- Do **not** add app-specific trip/wakelock logic here — inject via `AppUpdateConfig`.
- HOVR safety rules: simple control flow, no unbounded loops in plugin, ~60-line functions, validate channel args, zero analyzer warnings.
- Session flags are process-lifetime only; no SharedPreferences.
- Do not add module-level mutable state to consumer app `global.dart`.

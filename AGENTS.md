# hovr_app_update agent notes

- Plugin scope: version compare, native dialog, store deep link, session guard only.
- Apps own IAM `getAppVersion` and bootstrap timing.
- Channel name: `hovr_app_update`.
- HOVR safety rules: simple control flow, no unbounded loops in plugin, ~60-line functions, validate channel args, zero analyzer warnings.
- Session flags are process-lifetime only; no SharedPreferences.
- Do not add module-level mutable state to consumer app `global.dart`.

/// App-specific configuration for [HovrAppUpdate].
class AppUpdateConfig {
  const AppUpdateConfig({
    required this.iosAppStoreId,
    this.isSafeToPromptOtaRestart,
    this.onOtaError,
    this.otaTrack,
  });

  /// Apple App Store numeric ID used to open the update page on iOS.
  final String iosAppStoreId;

  /// When non-null, enables Shorebird OTA checks.
  /// Return `false` while a critical session is active (e.g. active trip).
  final bool Function()? isSafeToPromptOtaRestart;

  /// Optional OTA error sink. Prefer logging over silent failure.
  final void Function(Object error, StackTrace stackTrace)? onOtaError;

  /// Optional Shorebird track name (e.g. `stable`, `beta`). Null uses stable.
  final String? otaTrack;
}

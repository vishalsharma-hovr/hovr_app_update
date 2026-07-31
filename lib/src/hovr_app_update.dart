import 'dart:io';

import 'app_info.dart';
import 'app_update_config.dart';
import 'hovr_app_update_platform.dart';
import 'ota/ota_controller.dart';
import 'ota/ota_updater.dart';

final HovrAppUpdatePlatform _platform = HovrAppUpdatePlatform();
final OtaController _ota = OtaController(platform: _platform);

/// Native store-update dialog + optional Shorebird OTA (same popup UI).
class HovrAppUpdate {
  static Future<void> configure(
    AppUpdateConfig config, {
    OtaUpdater? otaUpdater,
  }) async {
    if (Platform.isIOS && config.iosAppStoreId.trim().isEmpty) {
      throw ArgumentError.value(
        config.iosAppStoreId,
        'iosAppStoreId',
        'must not be empty on iOS',
      );
    }
    await _platform.configure(iosAppStoreId: config.iosAppStoreId);

    final isSafe = config.isSafeToPromptOtaRestart;
    if (isSafe != null) {
      _ota.configure(
        isSafeToPromptRestart: isSafe,
        promptRestart: config.promptOtaRestart,
        onError: config.onOtaError,
        track: config.otaTrack,
        updater: otaUpdater,
      );
    }
  }

  /// Installed marketing version for the current platform
  /// (Android `versionName` / iOS `CFBundleShortVersionString`).
  static Future<String> getInstalledVersion() {
    return _platform.getInstalledVersion();
  }

  /// Full package information: [AppInfo.appName], [AppInfo.packageName],
  /// [AppInfo.version], and [AppInfo.buildNumber].
  static Future<AppInfo> getAppInfo() {
    return _platform.getAppInfo();
  }

  /// Store force-update: compare [serverVersion] and show native dialog if needed.
  /// Primary action opens the Play Store / App Store.
  static Future<void> promptIfUpdateRequired({
    required String serverVersion,
  }) async {
    await _platform.promptIfUpdateRequired(serverVersion: serverVersion);
  }

  /// Shorebird OTA: check/download patch; prompt restart when ready.
  ///
  /// Uses [AppUpdateConfig.promptOtaRestart] when set; otherwise the native
  /// Update Required dialog (Update restarts the process).
  ///
  /// No-op unless [AppUpdateConfig.isSafeToPromptOtaRestart] was set in [configure].
  /// Safe no-op on non-Shorebird / debug builds.
  static Future<void> checkForOtaAndPromptIfReady() {
    return _ota.checkForUpdateAndPromptIfReady();
  }

  /// Download an OTA patch without prompting (e.g. while a trip is active).
  static Future<void> downloadOtaUpdateIfAvailable() {
    return _ota.downloadUpdateIfAvailable();
  }

  /// Current booted Shorebird patch number, or null if base release / unavailable.
  static Future<int?> currentOtaPatchNumber() {
    return _ota.currentPatchNumber();
  }

  /// Test-only reset between cases.
  static void debugResetOta() {
    _ota.resetForTests();
    HovrAppUpdatePlatform.resetSessionForTests();
  }
}

import 'dart:io';

import 'app_info.dart';
import 'app_update_config.dart';
import 'hovr_app_update_platform.dart';

final HovrAppUpdatePlatform _platform = HovrAppUpdatePlatform();

/// Native app-update dialog and package-info queries.
class HovrAppUpdate {
  static Future<void> configure(AppUpdateConfig config) async {
    if (Platform.isIOS && config.iosAppStoreId.trim().isEmpty) {
      throw ArgumentError.value(
        config.iosAppStoreId,
        'iosAppStoreId',
        'must not be empty on iOS',
      );
    }
    await _platform.configure(iosAppStoreId: config.iosAppStoreId);
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

  static Future<void> promptIfUpdateRequired({
    required String serverVersion,
  }) async {
    await _platform.promptIfUpdateRequired(serverVersion: serverVersion);
  }
}

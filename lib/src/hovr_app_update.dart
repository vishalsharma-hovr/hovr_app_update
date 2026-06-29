import 'dart:io';

import 'app_update_config.dart';
import 'hovr_app_update_platform.dart';

final HovrAppUpdatePlatform _platform = HovrAppUpdatePlatform();

/// Shows a native update-required dialog at most once per app process.
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

  static Future<void> promptIfUpdateRequired({
    required String serverVersion,
  }) async {
    await _platform.promptIfUpdateRequired(serverVersion: serverVersion);
  }
}

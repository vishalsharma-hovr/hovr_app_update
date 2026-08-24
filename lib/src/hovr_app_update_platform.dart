import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_info.dart';
import 'app_update_result.dart';

const _channelName = 'hovr_app_update';

bool _storeHandledThisSession = false;
bool _otaHandledThisSession = false;

/// Platform channel wrapper with separate store / OTA once-per-session guards.
class HovrAppUpdatePlatform {
  HovrAppUpdatePlatform({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(_channelName);

  final MethodChannel _channel;

  Future<void> configure({required String iosAppStoreId}) async {
    await _channel.invokeMethod<void>('configure', <String, String>{
      'iosAppStoreId': iosAppStoreId,
    });
  }

  /// Returns the installed app version name for the current platform
  /// (Android `versionName` / iOS `CFBundleShortVersionString`).
  Future<String> getInstalledVersion() async {
    final version = await _channel.invokeMethod<String>('getInstalledVersion');
    return version?.trim() ?? '';
  }

  /// Returns full package information from the native platform.
  Future<AppInfo> getAppInfo() async {
    final result = await _channel.invokeMethod<Object?>('getAppInfo');
    if (result is Map<Object?, Object?>) {
      return AppInfo.fromMap(result);
    }
    return const AppInfo(
      appName: '',
      packageName: '',
      version: '',
      buildNumber: '',
    );
  }

  Future<AppUpdateResult?> promptIfUpdateRequired({
    required String serverVersion,
  }) async {
    if (_storeHandledThisSession) {
      return null;
    }

    try {
      final response = await _channel.invokeMethod<Object?>(
        'promptIfUpdateRequired',
        <String, String>{'serverVersion': serverVersion},
      );
      return _parseAndMarkStore(response);
    } on PlatformException catch (error, stackTrace) {
      developer.log(
        'HovrAppUpdate prompt failed',
        name: 'hovr_app_update',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Shows the same native update dialog; primary action restarts the process.
  Future<AppUpdateResult?> promptRestartToApplyUpdate() async {
    if (_otaHandledThisSession) {
      return null;
    }

    try {
      final response = await _channel.invokeMethod<Object?>(
        'promptRestartToApplyUpdate',
      );
      return _parseAndMarkOta(response);
    } on PlatformException catch (error, stackTrace) {
      developer.log(
        'HovrAppUpdate OTA restart prompt failed',
        name: 'hovr_app_update',
        error: error,
        stackTrace: stackTrace,
      );
      return null;
    }
  }

  /// Cold-restarts the process so a downloaded OTA patch can boot.
  ///
  /// Android relaunches the launcher activity then kills this process.
  /// iOS terminates only — the OS does not allow auto-relaunch.
  Future<void> restartToApplyUpdate() async {
    await _channel.invokeMethod<void>('restartToApplyUpdate');
  }

  AppUpdateResult _parseAndMarkStore(Object? response) {
    if (response is Map<Object?, Object?>) {
      final result = AppUpdateResult.fromMap(response);
      if (result.dialogShown) {
        _storeHandledThisSession = true;
      }
      return result;
    }
    return const AppUpdateResult(updateRequired: false, dialogShown: false);
  }

  AppUpdateResult _parseAndMarkOta(Object? response) {
    if (response is Map<Object?, Object?>) {
      final result = AppUpdateResult.fromMap(response);
      if (result.dialogShown) {
        _otaHandledThisSession = true;
      }
      return result;
    }
    return const AppUpdateResult(updateRequired: false, dialogShown: false);
  }

  @visibleForTesting
  static void resetSessionForTests() {
    _storeHandledThisSession = false;
    _otaHandledThisSession = false;
  }
}

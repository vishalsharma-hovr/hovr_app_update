import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_info.dart';
import 'app_update_result.dart';

const _channelName = 'hovr_app_update';

bool _handledThisSession = false;

/// Platform channel wrapper with a Dart-side once-per-session guard.
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
    if (_handledThisSession) {
      return null;
    }

    try {
      final response = await _channel.invokeMethod<Object?>(
        'promptIfUpdateRequired',
        <String, String>{'serverVersion': serverVersion},
      );
      return _parseAndMarkSession(response);
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
    if (_handledThisSession) {
      return null;
    }

    try {
      final response = await _channel.invokeMethod<Object?>(
        'promptRestartToApplyUpdate',
      );
      return _parseAndMarkSession(response);
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

  AppUpdateResult _parseAndMarkSession(Object? response) {
    if (response is Map<Object?, Object?>) {
      final result = AppUpdateResult.fromMap(response);
      if (result.dialogShown) {
        _handledThisSession = true;
      }
      return result;
    }
    return const AppUpdateResult(updateRequired: false, dialogShown: false);
  }

  @visibleForTesting
  static void resetSessionForTests() {
    _handledThisSession = false;
  }
}

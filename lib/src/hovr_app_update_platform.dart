import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
      _handledThisSession = true;
      if (response is Map<Object?, Object?>) {
        return AppUpdateResult.fromMap(response);
      }
      return const AppUpdateResult(updateRequired: false, dialogShown: false);
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

  @visibleForTesting
  static void resetSessionForTests() {
    _handledThisSession = false;
  }
}

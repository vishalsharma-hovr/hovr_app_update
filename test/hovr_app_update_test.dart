import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hovr_app_update/src/hovr_app_update_platform.dart';
import 'package:hovr_app_update/src/version_compare.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('isUpdateRequired', () {
    test('returns false when server version is empty', () {
      expect(
        isUpdateRequired(serverVersion: '', installedVersion: '1.0.0'),
        isFalse,
      );
    });

    test('returns false when versions match after trim', () {
      expect(
        isUpdateRequired(serverVersion: ' 6.2.4 ', installedVersion: '6.2.4'),
        isFalse,
      );
    });

    test('returns true when versions differ', () {
      expect(
        isUpdateRequired(serverVersion: '6.3.0', installedVersion: '6.2.4'),
        isTrue,
      );
    });
  });

  group('HovrAppUpdatePlatform session guard', () {
    late List<MethodCall> calls;

    setUp(() {
      calls = <MethodCall>[];
      HovrAppUpdatePlatform.resetSessionForTests();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('hovr_app_update'),
        (MethodCall methodCall) async {
          calls.add(methodCall);
          return <String, bool>{
            'updateRequired': true,
            'dialogShown': true,
          };
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('hovr_app_update'), null);
      HovrAppUpdatePlatform.resetSessionForTests();
    });

    test('skips second prompt in the same session', () async {
      final platform = HovrAppUpdatePlatform();
      await platform.promptIfUpdateRequired(serverVersion: '9.0.0');
      await platform.promptIfUpdateRequired(serverVersion: '9.0.0');

      expect(calls, hasLength(1));
      expect(calls.single.method, 'promptIfUpdateRequired');
    });

    test('does not lock session when dialog was not shown', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('hovr_app_update'),
        (MethodCall methodCall) async {
          calls.add(methodCall);
          return <String, bool>{
            'updateRequired': false,
            'dialogShown': false,
          };
        },
      );

      final platform = HovrAppUpdatePlatform();
      await platform.promptIfUpdateRequired(serverVersion: '9.0.0');
      await platform.promptRestartToApplyUpdate();

      expect(calls, hasLength(2));
      expect(calls[0].method, 'promptIfUpdateRequired');
      expect(calls[1].method, 'promptRestartToApplyUpdate');
    });

    test('store dialog does not block later OTA restart prompt', () async {
      final platform = HovrAppUpdatePlatform();
      await platform.promptIfUpdateRequired(serverVersion: '9.0.0');
      await platform.promptRestartToApplyUpdate();

      expect(calls, hasLength(2));
      expect(calls[0].method, 'promptIfUpdateRequired');
      expect(calls[1].method, 'promptRestartToApplyUpdate');
    });

    test('does not mark session handled when platform throws', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('hovr_app_update'),
        (MethodCall methodCall) async {
          calls.add(methodCall);
          throw PlatformException(code: 'NO_ACTIVITY');
        },
      );

      final platform = HovrAppUpdatePlatform();
      final first = await platform.promptIfUpdateRequired(serverVersion: '9.0.0');
      final second = await platform.promptIfUpdateRequired(serverVersion: '9.0.0');

      expect(first, isNull);
      expect(second, isNull);
      expect(calls, hasLength(2));
    });
  });

  group('getInstalledVersion', () {
    test('returns trimmed platform version string', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('hovr_app_update'),
        (MethodCall methodCall) async {
          expect(methodCall.method, 'getInstalledVersion');
          return ' 6.2.4 ';
        },
      );

      final platform = HovrAppUpdatePlatform();
      final version = await platform.getInstalledVersion();
      expect(version, '6.2.4');
    });

    test('returns empty string when channel returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('hovr_app_update'),
        (MethodCall methodCall) async => null,
      );

      final platform = HovrAppUpdatePlatform();
      final version = await platform.getInstalledVersion();
      expect(version, isEmpty);
    });
  });

  group('getAppInfo', () {
    test('parses full platform response', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('hovr_app_update'),
        (MethodCall methodCall) async {
          expect(methodCall.method, 'getAppInfo');
          return <String, String>{
            'appName': 'HOVR Rider',
            'packageName': 'com.ridehovr.rider',
            'version': '6.2.4',
            'buildNumber': '579',
          };
        },
      );

      final platform = HovrAppUpdatePlatform();
      final info = await platform.getAppInfo();
      expect(info.appName, 'HOVR Rider');
      expect(info.packageName, 'com.ridehovr.rider');
      expect(info.version, '6.2.4');
      expect(info.buildNumber, '579');
    });

    test('returns empty AppInfo when channel returns null', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('hovr_app_update'),
        (MethodCall methodCall) async => null,
      );

      final platform = HovrAppUpdatePlatform();
      final info = await platform.getAppInfo();
      expect(info.appName, isEmpty);
      expect(info.version, isEmpty);
      expect(info.buildNumber, isEmpty);
    });
  });
}

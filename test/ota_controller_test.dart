import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hovr_app_update/hovr_app_update.dart';
import 'package:hovr_app_update/src/hovr_app_update_platform.dart';
import 'package:hovr_app_update/src/ota/ota_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('skips work when updater is unavailable', () async {
    final platform = HovrAppUpdatePlatform();
    final controller = OtaController(platform: platform);
    final updater = _FakeUpdater(
      available: false,
      status: OtaUpdateStatus.outdated,
    );

    controller.configure(
      isSafeToPromptRestart: () => true,
      updater: updater,
    );

    final status = await controller.checkForUpdateAndPromptIfReady();
    expect(status, OtaUpdateStatus.unavailable);
    expect(updater.checkCount, 0);
    expect(updater.downloadCount, 0);
    expect(calls, isEmpty);
  });

  test('downloads outdated patch then shows restart dialog when safe', () async {
    final platform = HovrAppUpdatePlatform();
    final controller = OtaController(platform: platform);
    final updater = _FakeUpdater(
      available: true,
      status: OtaUpdateStatus.outdated,
      currentPatch: 1,
    );

    controller.configure(
      isSafeToPromptRestart: () => true,
      updater: updater,
    );

    final status = await controller.checkForUpdateAndPromptIfReady();
    expect(status, OtaUpdateStatus.restartRequired);
    expect(updater.checkCount, 1);
    expect(updater.downloadCount, 1);
    expect(calls.single.method, 'promptRestartToApplyUpdate');
    expect(await controller.currentPatchNumber(), 1);
  });

  test('returns upToDate when Shorebird reports no newer patch', () async {
    final platform = HovrAppUpdatePlatform();
    final controller = OtaController(platform: platform);
    final updater = _FakeUpdater(
      available: true,
      status: OtaUpdateStatus.upToDate,
      currentPatch: 3,
    );

    controller.configure(
      isSafeToPromptRestart: () => true,
      updater: updater,
    );

    final status = await controller.checkForUpdateAndPromptIfReady();
    expect(status, OtaUpdateStatus.upToDate);
    expect(updater.downloadCount, 0);
    expect(calls, isEmpty);
  });

  test('defers prompt when not safe to restart', () async {
    final platform = HovrAppUpdatePlatform();
    final controller = OtaController(platform: platform);
    final updater = _FakeUpdater(
      available: true,
      status: OtaUpdateStatus.outdated,
    );

    controller.configure(
      isSafeToPromptRestart: () => false,
      updater: updater,
    );

    final status = await controller.checkForUpdateAndPromptIfReady();
    expect(status, OtaUpdateStatus.restartRequired);
    expect(updater.downloadCount, 1);
    expect(calls, isEmpty);
  });

  test('downloadUpdateIfAvailable does not prompt', () async {
    final platform = HovrAppUpdatePlatform();
    final controller = OtaController(platform: platform);
    final updater = _FakeUpdater(
      available: true,
      status: OtaUpdateStatus.outdated,
    );

    controller.configure(
      isSafeToPromptRestart: () => true,
      updater: updater,
    );

    await controller.downloadUpdateIfAvailable();
    expect(updater.downloadCount, 1);
    expect(calls, isEmpty);
  });

  test('reports errors via onError', () async {
    Object? seenError;
    final platform = HovrAppUpdatePlatform();
    final controller = OtaController(platform: platform);
    final updater = _FakeUpdater(
      available: true,
      status: OtaUpdateStatus.outdated,
      throwOnCheck: true,
    );

    controller.configure(
      isSafeToPromptRestart: () => true,
      onError: (error, _) => seenError = error,
      updater: updater,
    );

    final status = await controller.checkForUpdateAndPromptIfReady();
    expect(status, OtaUpdateStatus.unavailable);
    expect(seenError, isA<StateError>());
  });
}

final class _FakeUpdater implements OtaUpdater {
  _FakeUpdater({
    required this.available,
    required this.status,
    this.currentPatch,
    this.throwOnCheck = false,
  });

  final bool available;
  final OtaUpdateStatus status;
  final int? currentPatch;
  final bool throwOnCheck;

  var checkCount = 0;
  var downloadCount = 0;

  @override
  bool get isAvailable => available;

  @override
  Future<OtaUpdateStatus> checkForUpdate({String? track}) async {
    checkCount += 1;
    if (throwOnCheck) {
      throw StateError('check failed');
    }
    return status;
  }

  @override
  Future<void> downloadUpdate({String? track}) async {
    downloadCount += 1;
  }

  @override
  Future<int?> readCurrentPatchNumber() async => currentPatch;
}

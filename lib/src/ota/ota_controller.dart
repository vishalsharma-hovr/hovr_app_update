import 'dart:developer' as developer;

import '../hovr_app_update_platform.dart';
import 'ota_update_status.dart';
import 'ota_updater.dart';
import 'shorebird_code_push_updater.dart';

/// Shorebird OTA check/download + restart prompt (native or host-injected).
class OtaController {
  OtaController({
    required HovrAppUpdatePlatform platform,
    OtaUpdater? updater,
  })  : _platform = platform,
        _updater = updater;

  final HovrAppUpdatePlatform _platform;
  OtaUpdater? _updater;
  bool Function()? isSafeToPromptRestart;
  Future<bool> Function()? promptRestart;
  void Function(Object error, StackTrace stackTrace)? onError;
  String? track;
  var _inFlight = false;

  OtaUpdater get _resolvedUpdater => _updater ??= ShorebirdCodePushUpdater();

  void configure({
    required bool Function() isSafeToPromptRestart,
    Future<bool> Function()? promptRestart,
    void Function(Object error, StackTrace stackTrace)? onError,
    String? track,
    OtaUpdater? updater,
  }) {
    this.isSafeToPromptRestart = isSafeToPromptRestart;
    this.promptRestart = promptRestart;
    this.onError = onError;
    this.track = track;
    if (updater != null) {
      _updater = updater;
    }
  }

  Future<int?> currentPatchNumber() async {
    final updater = _resolvedUpdater;
    if (!updater.isAvailable) return null;
    try {
      return await updater.readCurrentPatchNumber();
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      return null;
    }
  }

  /// Whether the running binary was produced by `shorebird release`.
  /// False for `flutter build` / debug binaries — OTA can never apply there.
  bool get isOtaAvailable => _resolvedUpdater.isAvailable;

  /// Checks Shorebird for a patch, downloads when outdated, and prompts restart
  /// when safe. Returns the final [OtaUpdateStatus] so hosts can surface it in UI.
  Future<OtaUpdateStatus> checkForUpdateAndPromptIfReady() async {
    final isSafe = isSafeToPromptRestart;
    if (isSafe == null || _inFlight) return OtaUpdateStatus.unavailable;
    final updater = _resolvedUpdater;
    if (!updater.isAvailable) {
      developer.log(
        'OTA skipped: updater unavailable — this build was not produced by '
        '`shorebird release`, so patches can never apply',
        name: 'hovr_app_update',
      );
      return OtaUpdateStatus.unavailable;
    }

    _inFlight = true;
    try {
      return await _checkAndPrompt(isSafe, updater);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
      return OtaUpdateStatus.unavailable;
    } finally {
      _inFlight = false;
    }
  }

  Future<void> downloadUpdateIfAvailable() async {
    if (isSafeToPromptRestart == null || _inFlight) return;
    final updater = _resolvedUpdater;
    if (!updater.isAvailable) {
      developer.log(
        'OTA download skipped: updater unavailable',
        name: 'hovr_app_update',
      );
      return;
    }

    _inFlight = true;
    try {
      final bootedPatch = await updater.readCurrentPatchNumber();
      final status = await updater.checkForUpdate(track: track);
      developer.log(
        'OTA download check bootedPatch=$bootedPatch status=$status '
        'track=${track ?? 'stable'}',
        name: 'hovr_app_update',
      );
      if (status != OtaUpdateStatus.outdated) return;
      await updater.downloadUpdate(track: track);
      developer.log(
        'OTA patch downloaded; applies on next cold start',
        name: 'hovr_app_update',
      );
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
    } finally {
      _inFlight = false;
    }
  }

  void resetForTests() {
    isSafeToPromptRestart = null;
    promptRestart = null;
    onError = null;
    track = null;
    _updater = null;
    _inFlight = false;
  }

  Future<OtaUpdateStatus> _checkAndPrompt(
    bool Function() isSafe,
    OtaUpdater updater,
  ) async {
    final bootedPatch = await updater.readCurrentPatchNumber();
    var status = await updater.checkForUpdate(track: track);
    developer.log(
      'OTA check available=${updater.isAvailable} '
      'bootedPatch=$bootedPatch status=$status track=${track ?? 'stable'}',
      name: 'hovr_app_update',
    );

    if (status == OtaUpdateStatus.outdated) {
      await updater.downloadUpdate(track: track);
      status = OtaUpdateStatus.restartRequired;
      developer.log(
        'OTA patch downloaded; restart required to apply',
        name: 'hovr_app_update',
      );
    }

    if (status != OtaUpdateStatus.restartRequired) return status;
    if (!isSafe()) {
      developer.log(
        'OTA restart deferred (host reported not safe)',
        name: 'hovr_app_update',
      );
      return status;
    }

    final hostPrompt = promptRestart;
    if (hostPrompt != null) {
      final accepted = await hostPrompt();
      developer.log(
        'OTA restart prompt accepted=$accepted',
        name: 'hovr_app_update',
      );
      return status;
    }

    await _platform.promptRestartToApplyUpdate();
    return status;
  }

  void _reportError(Object error, StackTrace stackTrace) {
    onError?.call(error, stackTrace);
  }
}

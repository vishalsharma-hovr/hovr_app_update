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

  Future<void> checkForUpdateAndPromptIfReady() async {
    final isSafe = isSafeToPromptRestart;
    if (isSafe == null || _inFlight) return;
    final updater = _resolvedUpdater;
    if (!updater.isAvailable) return;

    _inFlight = true;
    try {
      await _checkAndPrompt(isSafe, updater);
    } catch (error, stackTrace) {
      _reportError(error, stackTrace);
    } finally {
      _inFlight = false;
    }
  }

  Future<void> downloadUpdateIfAvailable() async {
    if (isSafeToPromptRestart == null || _inFlight) return;
    final updater = _resolvedUpdater;
    if (!updater.isAvailable) return;

    _inFlight = true;
    try {
      final status = await updater.checkForUpdate(track: track);
      if (status != OtaUpdateStatus.outdated) return;
      await updater.downloadUpdate(track: track);
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

  Future<void> _checkAndPrompt(
    bool Function() isSafe,
    OtaUpdater updater,
  ) async {
    var status = await updater.checkForUpdate(track: track);

    if (status == OtaUpdateStatus.outdated) {
      await updater.downloadUpdate(track: track);
      status = OtaUpdateStatus.restartRequired;
    }

    if (status != OtaUpdateStatus.restartRequired) return;
    if (!isSafe()) return;

    final hostPrompt = promptRestart;
    if (hostPrompt != null) {
      await hostPrompt();
      return;
    }

    await _platform.promptRestartToApplyUpdate();
  }

  void _reportError(Object error, StackTrace stackTrace) {
    onError?.call(error, stackTrace);
  }
}

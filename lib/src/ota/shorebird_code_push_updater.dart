import 'package:shorebird_code_push/shorebird_code_push.dart';

import 'ota_update_status.dart';
import 'ota_updater.dart';

/// Production adapter around [ShorebirdUpdater].
final class ShorebirdCodePushUpdater implements OtaUpdater {
  ShorebirdCodePushUpdater({ShorebirdUpdater? updater})
      : _updater = updater ?? ShorebirdUpdater();

  final ShorebirdUpdater _updater;

  @override
  bool get isAvailable => _updater.isAvailable;

  @override
  Future<OtaUpdateStatus> checkForUpdate({String? track}) async {
    final status = await _updater.checkForUpdate(track: _resolveTrack(track));
    return switch (status) {
      UpdateStatus.upToDate => OtaUpdateStatus.upToDate,
      UpdateStatus.outdated => OtaUpdateStatus.outdated,
      UpdateStatus.restartRequired => OtaUpdateStatus.restartRequired,
      UpdateStatus.unavailable => OtaUpdateStatus.unavailable,
    };
  }

  @override
  Future<void> downloadUpdate({String? track}) {
    return _updater.update(track: _resolveTrack(track));
  }

  @override
  Future<int?> readCurrentPatchNumber() async {
    final patch = await _updater.readCurrentPatch();
    return patch?.number;
  }

  UpdateTrack? _resolveTrack(String? track) {
    if (track == null || track.isEmpty) return null;
    return UpdateTrack(track);
  }
}

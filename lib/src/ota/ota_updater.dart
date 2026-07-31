import 'ota_update_status.dart';

/// Abstraction over Shorebird's updater for tests and the real adapter.
abstract class OtaUpdater {
  bool get isAvailable;

  Future<OtaUpdateStatus> checkForUpdate({String? track});

  Future<void> downloadUpdate({String? track});

  Future<int?> readCurrentPatchNumber();
}

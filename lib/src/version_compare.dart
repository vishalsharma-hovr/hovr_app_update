/// Returns `true` when [serverVersion] differs from [installedVersion].
///
/// Uses trimmed string equality to match legacy native behavior.
bool isUpdateRequired({
  required String serverVersion,
  required String installedVersion,
}) {
  final server = serverVersion.trim();
  if (server.isEmpty) {
    return false;
  }
  return server != installedVersion.trim();
}

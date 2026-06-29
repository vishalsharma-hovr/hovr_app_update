/// Result of a native update prompt check.
class AppUpdateResult {
  const AppUpdateResult({
    required this.updateRequired,
    required this.dialogShown,
  });

  factory AppUpdateResult.fromMap(Map<Object?, Object?> map) {
    return AppUpdateResult(
      updateRequired: map['updateRequired'] == true,
      dialogShown: map['dialogShown'] == true,
    );
  }

  final bool updateRequired;
  final bool dialogShown;
}

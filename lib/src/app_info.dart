/// Application package information queried from the native platform.
///
/// Mirrors the fields available in `package_info_plus`:
/// [appName], [packageName], [version], [buildNumber].
class AppInfo {
  const AppInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
  });

  factory AppInfo.fromMap(Map<Object?, Object?> map) {
    return AppInfo(
      appName: (map['appName'] as String?) ?? '',
      packageName: (map['packageName'] as String?) ?? '',
      version: (map['version'] as String?) ?? '',
      buildNumber: (map['buildNumber'] as String?) ?? '',
    );
  }

  /// Display name of the application (e.g. "HOVR Rider").
  final String appName;

  /// Package identifier (Android: application ID, iOS: bundle identifier).
  final String packageName;

  /// Marketing version string (Android `versionName` / iOS `CFBundleShortVersionString`).
  final String version;

  /// Build number (Android `versionCode` / iOS `CFBundleVersion`).
  final String buildNumber;

  @override
  String toString() =>
      'AppInfo(appName: $appName, packageName: $packageName, version: $version, buildNumber: $buildNumber)';
}

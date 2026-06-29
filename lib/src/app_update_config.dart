/// App-specific configuration for [HovrAppUpdate].
class AppUpdateConfig {
  const AppUpdateConfig({required this.iosAppStoreId});

  /// Apple App Store numeric ID used to open the update page on iOS.
  final String iosAppStoreId;
}

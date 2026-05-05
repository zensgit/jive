/// AdMob configuration.
///
/// Test IDs are used by default for local/dev builds.
/// Release builds should inject real IDs through dart-defines/Gradle env.
/// See: https://developers.google.com/admob/android/test-ads
class AdConfig {
  AdConfig._();

  /// AdMob test app ID (Android).
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// AdMob test banner unit ID (Android).
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';

  static const String _configuredBannerId = String.fromEnvironment(
    'ADMOB_BANNER_ID',
    defaultValue: '',
  );

  /// Current banner unit ID.
  static String get bannerUnitId =>
      _configuredBannerId.isEmpty ? testBannerId : _configuredBannerId;
}

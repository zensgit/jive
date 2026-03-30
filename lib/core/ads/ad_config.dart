/// AdMob configuration.
///
/// Test IDs are used by default. Replace with real IDs before release.
/// See: https://developers.google.com/admob/android/test-ads
class AdConfig {
  AdConfig._();

  /// AdMob test app ID (Android).
  static const String testAppId = 'ca-app-pub-3940256099942544~3347511713';

  /// AdMob test banner unit ID (Android).
  static const String testBannerId = 'ca-app-pub-3940256099942544/6300978111';

  /// Current banner unit ID.
  /// TODO: replace with real ID from AdMob console before release.
  static const String bannerUnitId = testBannerId;
}

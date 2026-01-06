import 'package:shared_preferences/shared_preferences.dart';

class AutoSettings {
  final bool enabled;
  final bool directCommit;

  const AutoSettings({
    required this.enabled,
    required this.directCommit,
  });

  AutoSettings copyWith({
    bool? enabled,
    bool? directCommit,
  }) {
    return AutoSettings(
      enabled: enabled ?? this.enabled,
      directCommit: directCommit ?? this.directCommit,
    );
  }
}

class AutoSettingsStore {
  static const _keyEnabled = 'auto_enabled';
  static const _keyDirectCommit = 'auto_direct_commit';

  static const AutoSettings defaults = AutoSettings(
    enabled: true,
    directCommit: false,
  );

  static Future<AutoSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    return AutoSettings(
      enabled: prefs.getBool(_keyEnabled) ?? defaults.enabled,
      directCommit: prefs.getBool(_keyDirectCommit) ?? defaults.directCommit,
    );
  }

  static Future<void> save(AutoSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, settings.enabled);
    await prefs.setBool(_keyDirectCommit, settings.directCommit);
  }
}

import 'package:shared_preferences/shared_preferences.dart';

class AutoSettings {
  final bool enabled;
  final bool directCommit;
  final bool keywordFilterEnabled;
  final List<String> keywordFilters;
  final bool autoTransferRecognition;
  final int autoTransferWindowSeconds;
  final bool debugShowDraftMetadata;

  const AutoSettings({
    required this.enabled,
    required this.directCommit,
    required this.keywordFilterEnabled,
    required this.keywordFilters,
    required this.autoTransferRecognition,
    required this.autoTransferWindowSeconds,
    required this.debugShowDraftMetadata,
  });

  AutoSettings copyWith({
    bool? enabled,
    bool? directCommit,
    bool? keywordFilterEnabled,
    List<String>? keywordFilters,
    bool? autoTransferRecognition,
    int? autoTransferWindowSeconds,
    bool? debugShowDraftMetadata,
  }) {
    return AutoSettings(
      enabled: enabled ?? this.enabled,
      directCommit: directCommit ?? this.directCommit,
      keywordFilterEnabled: keywordFilterEnabled ?? this.keywordFilterEnabled,
      keywordFilters: keywordFilters ?? this.keywordFilters,
      autoTransferRecognition: autoTransferRecognition ?? this.autoTransferRecognition,
      autoTransferWindowSeconds: autoTransferWindowSeconds ?? this.autoTransferWindowSeconds,
      debugShowDraftMetadata: debugShowDraftMetadata ?? this.debugShowDraftMetadata,
    );
  }
}

class AutoSettingsStore {
  static const _keyEnabled = 'auto_enabled';
  static const _keyDirectCommit = 'auto_direct_commit';
  static const _keyKeywordFilterEnabled = 'auto_keyword_filter_enabled';
  static const _keyKeywordFilters = 'auto_keyword_filters';
  static const _keyAutoTransferRecognition = 'auto_transfer_recognition';
  static const _keyAutoTransferWindowSeconds = 'auto_transfer_window_seconds';
  static const _keyDebugShowDraftMetadata = 'auto_debug_show_draft_metadata';

  static const defaultKeywordFilters = [
    '支付成功',
    '交易成功',
    '付款成功',
    '已支付',
    '转账',
    '转入',
    '转出',
    '到账',
    '收款',
    '退款',
    '红包',
    '账单详情',
    '交易详情',
    '转账详情',
    '账单明细',
  ];

  static const AutoSettings defaults = AutoSettings(
    enabled: true,
    directCommit: false,
    keywordFilterEnabled: true,
    keywordFilters: defaultKeywordFilters,
    autoTransferRecognition: true,
    autoTransferWindowSeconds: 60,
    debugShowDraftMetadata: false,
  );

  static Future<AutoSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final keywords = prefs.getStringList(_keyKeywordFilters);
    return AutoSettings(
      enabled: prefs.getBool(_keyEnabled) ?? defaults.enabled,
      directCommit: prefs.getBool(_keyDirectCommit) ?? defaults.directCommit,
      keywordFilterEnabled: prefs.getBool(_keyKeywordFilterEnabled) ?? defaults.keywordFilterEnabled,
      keywordFilters: (keywords == null || keywords.isEmpty) ? defaults.keywordFilters : keywords,
      autoTransferRecognition: prefs.getBool(_keyAutoTransferRecognition) ?? defaults.autoTransferRecognition,
      autoTransferWindowSeconds:
          prefs.getInt(_keyAutoTransferWindowSeconds) ?? defaults.autoTransferWindowSeconds,
      debugShowDraftMetadata:
          prefs.getBool(_keyDebugShowDraftMetadata) ?? defaults.debugShowDraftMetadata,
    );
  }

  static Future<void> save(AutoSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyEnabled, settings.enabled);
    await prefs.setBool(_keyDirectCommit, settings.directCommit);
    await prefs.setBool(_keyKeywordFilterEnabled, settings.keywordFilterEnabled);
    await prefs.setStringList(_keyKeywordFilters, settings.keywordFilters);
    await prefs.setBool(_keyAutoTransferRecognition, settings.autoTransferRecognition);
    await prefs.setInt(_keyAutoTransferWindowSeconds, settings.autoTransferWindowSeconds);
    await prefs.setBool(_keyDebugShowDraftMetadata, settings.debugShowDraftMetadata);
  }
}

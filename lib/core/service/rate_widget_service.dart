import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/currency_model.dart';
import 'currency_service.dart';

/// 汇率小组件数据服务
/// 为桌面/锁屏小组件提供数据支持
class RateWidgetService {
  static const String _widgetDataKey = 'rate_widget_data';
  static const String _widgetConfigKey = 'rate_widget_config';

  final CurrencyService _currencyService;

  RateWidgetService(this._currencyService);

  /// 小组件配置
  static Future<RateWidgetConfig> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_widgetConfigKey);
    if (json != null) {
      return RateWidgetConfig.fromJson(jsonDecode(json));
    }
    return RateWidgetConfig.defaultConfig();
  }

  /// 保存小组件配置
  static Future<void> saveConfig(RateWidgetConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_widgetConfigKey, jsonEncode(config.toJson()));
  }

  /// 更新小组件数据
  Future<void> updateWidgetData() async {
    final config = await getConfig();
    final data = <RateWidgetItem>[];

    for (final pair in config.currencyPairs) {
      final parts = pair.split('/');
      if (parts.length != 2) continue;

      final from = parts[0];
      final to = parts[1];
      final rate = await _currencyService.getRate(from, to);
      final trendStats = await _currencyService.getRateTrendStats(from, to, days: 7);

      if (rate != null) {
        data.add(RateWidgetItem(
          fromCurrency: from,
          toCurrency: to,
          rate: rate,
          changePercent: trendStats?.changePercent ?? 0,
          updatedAt: DateTime.now(),
        ));
      }
    }

    // 保存数据供小组件读取
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _widgetDataKey,
      jsonEncode(data.map((e) => e.toJson()).toList()),
    );

    // TODO: 调用原生方法更新小组件
    // HomeWidget.updateWidget(name: 'RateWidget');
  }

  /// 获取小组件数据
  static Future<List<RateWidgetItem>> getWidgetData() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_widgetDataKey);
    if (json != null) {
      final list = jsonDecode(json) as List;
      return list.map((e) => RateWidgetItem.fromJson(e)).toList();
    }
    return [];
  }
}

/// 小组件配置
class RateWidgetConfig {
  final List<String> currencyPairs; // 要显示的货币对，如 ['CNY/USD', 'EUR/USD']
  final bool showTrend; // 是否显示趋势
  final bool showFlag; // 是否显示国旗
  final int refreshInterval; // 刷新间隔（分钟）
  final String theme; // 主题: light, dark, auto

  RateWidgetConfig({
    required this.currencyPairs,
    this.showTrend = true,
    this.showFlag = true,
    this.refreshInterval = 60,
    this.theme = 'auto',
  });

  factory RateWidgetConfig.defaultConfig() {
    return RateWidgetConfig(
      currencyPairs: ['CNY/USD', 'CNY/EUR', 'CNY/JPY'],
    );
  }

  factory RateWidgetConfig.fromJson(Map<String, dynamic> json) {
    return RateWidgetConfig(
      currencyPairs: List<String>.from(json['currencyPairs'] ?? []),
      showTrend: json['showTrend'] ?? true,
      showFlag: json['showFlag'] ?? true,
      refreshInterval: json['refreshInterval'] ?? 60,
      theme: json['theme'] ?? 'auto',
    );
  }

  Map<String, dynamic> toJson() => {
        'currencyPairs': currencyPairs,
        'showTrend': showTrend,
        'showFlag': showFlag,
        'refreshInterval': refreshInterval,
        'theme': theme,
      };

  RateWidgetConfig copyWith({
    List<String>? currencyPairs,
    bool? showTrend,
    bool? showFlag,
    int? refreshInterval,
    String? theme,
  }) {
    return RateWidgetConfig(
      currencyPairs: currencyPairs ?? this.currencyPairs,
      showTrend: showTrend ?? this.showTrend,
      showFlag: showFlag ?? this.showFlag,
      refreshInterval: refreshInterval ?? this.refreshInterval,
      theme: theme ?? this.theme,
    );
  }
}

/// 小组件数据项
class RateWidgetItem {
  final String fromCurrency;
  final String toCurrency;
  final double rate;
  final double changePercent;
  final DateTime updatedAt;

  RateWidgetItem({
    required this.fromCurrency,
    required this.toCurrency,
    required this.rate,
    required this.changePercent,
    required this.updatedAt,
  });

  factory RateWidgetItem.fromJson(Map<String, dynamic> json) {
    return RateWidgetItem(
      fromCurrency: json['fromCurrency'],
      toCurrency: json['toCurrency'],
      rate: (json['rate'] as num).toDouble(),
      changePercent: (json['changePercent'] as num).toDouble(),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'fromCurrency': fromCurrency,
        'toCurrency': toCurrency,
        'rate': rate,
        'changePercent': changePercent,
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get isUp => changePercent > 0;
  bool get isDown => changePercent < 0;

  String get changeText {
    final sign = isUp ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(2)}%';
  }

  String get displayRate {
    if (rate >= 1000) return rate.toStringAsFixed(0);
    if (rate >= 1) return rate.toStringAsFixed(2);
    if (rate >= 0.01) return rate.toStringAsFixed(4);
    return rate.toStringAsFixed(6);
  }

  String get fromFlag => CurrencyDefaults.getAllCurrencies()
      .firstWhere((c) => c['code'] == fromCurrency, orElse: () => {})['flag'] as String? ?? fromCurrency;

  String get toFlag => CurrencyDefaults.getAllCurrencies()
      .firstWhere((c) => c['code'] == toCurrency, orElse: () => {})['flag'] as String? ?? toCurrency;
}

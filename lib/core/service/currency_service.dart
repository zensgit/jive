import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:isar/isar.dart';
import '../database/currency_model.dart';

/// 汇率 API 响应模型
class ExchangeRateResponse {
  final String from;
  final String to;
  final double rate;
  final DateTime date;
  final String source;

  ExchangeRateResponse({
    required this.from,
    required this.to,
    required this.rate,
    required this.date,
    required this.source,
  });
}

/// 货币服务
class CurrencyService {
  final Isar _isar;

  // 免费汇率 API（无需 key）
  // 使用 exchangerate.host 或 frankfurter.app 作为备选
  static const String _primaryApiUrl = 'https://api.frankfurter.app';
  static const String _fallbackApiUrl = 'https://api.exchangerate.host';

  CurrencyService(this._isar);

  /// 初始化货币数据（首次启动时调用）
  Future<void> initCurrencies() async {
    final existing = await _isar.jiveCurrencys.count();
    if (existing > 0) return;

    final currencies = CurrencyDefaults.getAllCurrencies();
    await _isar.writeTxn(() async {
      for (final data in currencies) {
        final currency = JiveCurrency()
          ..code = data['code'] as String
          ..name = data['name'] as String
          ..nameZh = data['nameZh'] as String
          ..symbol = data['symbol'] as String
          ..decimalPlaces = data['decimalPlaces'] as int
          ..flag = data['flag'] as String?
          ..isCrypto = data['isCrypto'] == true
          ..sortOrder = data['sortOrder'] as int;
        await _isar.jiveCurrencys.put(currency);
      }
    });

    // 初始化默认偏好
    await _initDefaultPreference();

    // 初始化 Mock 汇率
    await _initMockRates();
  }

  /// 初始化默认偏好设置
  Future<void> _initDefaultPreference() async {
    final existing = await _isar.jiveCurrencyPreferences.count();
    if (existing > 0) return;

    await _isar.writeTxn(() async {
      final pref = JiveCurrencyPreference()
        ..baseCurrency = 'CNY'
        ..enabledCurrencies = ['CNY', 'USD', 'EUR', 'JPY', 'HKD']
        ..autoUpdateRates = false;
      await _isar.jiveCurrencyPreferences.put(pref);
    });
  }

  /// 初始化 Mock 汇率数据
  Future<void> _initMockRates() async {
    final existing = await _isar.jiveExchangeRates.count();
    if (existing > 0) return;

    final now = DateTime.now();
    final rates = <JiveExchangeRate>[];

    // 生成所有货币对的汇率（以 USD 为中转）
    final codes = CurrencyDefaults.ratesAgainstUSD.keys.toList();
    for (final from in codes) {
      for (final to in codes) {
        if (from == to) continue;
        final rate = CurrencyDefaults.getRate(from, to);
        if (rate != null) {
          rates.add(JiveExchangeRate()
            ..fromCurrency = from
            ..toCurrency = to
            ..rate = rate
            ..effectiveDate = now
            ..source = 'mock'
            ..updatedAt = now);
        }
      }
    }

    await _isar.writeTxn(() async {
      await _isar.jiveExchangeRates.putAll(rates);
    });
  }

  /// 获取所有货币
  Future<List<JiveCurrency>> getAllCurrencies() async {
    return await _isar.jiveCurrencys.where().sortBySortOrder().findAll();
  }

  /// 获取法定货币
  Future<List<JiveCurrency>> getFiatCurrencies() async {
    return await _isar.jiveCurrencys
        .filter()
        .isCryptoEqualTo(false)
        .sortBySortOrder()
        .findAll();
  }

  /// 获取加密货币
  Future<List<JiveCurrency>> getCryptoCurrencies() async {
    return await _isar.jiveCurrencys
        .filter()
        .isCryptoEqualTo(true)
        .sortBySortOrder()
        .findAll();
  }

  /// 根据代码获取货币
  Future<JiveCurrency?> getCurrencyByCode(String code) async {
    return await _isar.jiveCurrencys.filter().codeEqualTo(code).findFirst();
  }

  /// 获取用户偏好
  Future<JiveCurrencyPreference?> getPreference() async {
    return await _isar.jiveCurrencyPreferences.where().findFirst();
  }

  /// 获取基础货币代码
  Future<String> getBaseCurrency() async {
    final pref = await getPreference();
    return pref?.baseCurrency ?? 'CNY';
  }

  /// 更新用户偏好
  Future<void> updatePreference(JiveCurrencyPreference pref) async {
    await _isar.writeTxn(() async {
      await _isar.jiveCurrencyPreferences.put(pref);
    });
  }

  /// 设置主币种
  Future<void> setBaseCurrency(String code) async {
    final pref = await getPreference();
    if (pref == null) return;
    pref.baseCurrency = code;
    if (!pref.enabledCurrencies.contains(code)) {
      pref.enabledCurrencies = [code, ...pref.enabledCurrencies];
    }
    await updatePreference(pref);
  }

  /// 获取汇率
  Future<double?> getRate(String from, String to) async {
    if (from == to) return 1.0;

    // 先查本地数据库
    final rate = await _isar.jiveExchangeRates
        .filter()
        .fromCurrencyEqualTo(from)
        .toCurrencyEqualTo(to)
        .sortByEffectiveDateDesc()
        .findFirst();

    if (rate != null) {
      return rate.rate;
    }

    // 本地没有则使用默认汇率
    return CurrencyDefaults.getRate(from, to);
  }

  /// 获取完整汇率记录（包含来源信息）
  Future<JiveExchangeRate?> getRateRecord(String from, String to) async {
    if (from == to) return null;

    return await _isar.jiveExchangeRates
        .filter()
        .fromCurrencyEqualTo(from)
        .toCurrencyEqualTo(to)
        .sortByEffectiveDateDesc()
        .findFirst();
  }

  /// 货币转换
  Future<double?> convert(double amount, String from, String to) async {
    final rate = await getRate(from, to);
    if (rate == null) return null;
    return amount * rate;
  }

  /// 从在线 API 获取实时汇率
  Future<ExchangeRateResponse?> fetchLiveRate(String from, String to) async {
    // 加密货币不支持在线获取
    final currencies = CurrencyDefaults.getAllCurrencies();
    final fromCurrency = currencies.firstWhere(
      (c) => c['code'] == from,
      orElse: () => <String, dynamic>{},
    );
    final toCurrency = currencies.firstWhere(
      (c) => c['code'] == to,
      orElse: () => <String, dynamic>{},
    );

    if (fromCurrency['isCrypto'] == true || toCurrency['isCrypto'] == true) {
      // 加密货币使用本地 Mock 数据
      final rate = CurrencyDefaults.getRate(from, to);
      if (rate == null) return null;
      return ExchangeRateResponse(
        from: from,
        to: to,
        rate: rate,
        date: DateTime.now(),
        source: 'mock',
      );
    }

    try {
      // 尝试主 API
      final response = await _fetchFromFrankfurter(from, to);
      if (response != null) return response;

      // 主 API 失败，尝试备用
      return await _fetchFromExchangeRateHost(from, to);
    } catch (e) {
      // API 失败，返回本地数据
      final rate = CurrencyDefaults.getRate(from, to);
      if (rate == null) return null;
      return ExchangeRateResponse(
        from: from,
        to: to,
        rate: rate,
        date: DateTime.now(),
        source: 'fallback',
      );
    }
  }

  /// 从 Frankfurter API 获取汇率
  Future<ExchangeRateResponse?> _fetchFromFrankfurter(String from, String to) async {
    try {
      final url = '$_primaryApiUrl/latest?from=$from&to=$to';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;
        if (rates != null && rates.containsKey(to)) {
          final rate = (rates[to] as num).toDouble();
          return ExchangeRateResponse(
            from: from,
            to: to,
            rate: rate,
            date: DateTime.now(),
            source: 'frankfurter',
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// 从 ExchangeRate.host API 获取汇率
  Future<ExchangeRateResponse?> _fetchFromExchangeRateHost(String from, String to) async {
    try {
      final url = '$_fallbackApiUrl/latest?base=$from&symbols=$to';
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final rates = data['rates'] as Map<String, dynamic>?;
        if (rates != null && rates.containsKey(to)) {
          final rate = (rates[to] as num).toDouble();
          return ExchangeRateResponse(
            from: from,
            to: to,
            rate: rate,
            date: DateTime.now(),
            source: 'exchangerate.host',
          );
        }
      }
    } catch (_) {}
    return null;
  }

  /// 批量获取汇率并更新本地数据库
  Future<Map<String, double>> fetchAndUpdateRates(String baseCurrency, List<String> targets) async {
    final results = <String, double>{};
    final now = DateTime.now();

    for (final to in targets) {
      if (to == baseCurrency) continue;

      final response = await fetchLiveRate(baseCurrency, to);
      if (response != null) {
        results[to] = response.rate;

        // 更新本地数据库
        await _isar.writeTxn(() async {
          // 查找现有记录
          final existing = await _isar.jiveExchangeRates
              .filter()
              .fromCurrencyEqualTo(baseCurrency)
              .toCurrencyEqualTo(to)
              .findFirst();

          if (existing != null) {
            existing.rate = response.rate;
            existing.source = response.source;
            existing.updatedAt = now;
            await _isar.jiveExchangeRates.put(existing);
          } else {
            final newRate = JiveExchangeRate()
              ..fromCurrency = baseCurrency
              ..toCurrency = to
              ..rate = response.rate
              ..effectiveDate = now
              ..source = response.source
              ..updatedAt = now;
            await _isar.jiveExchangeRates.put(newRate);
          }

          // 同时更新反向汇率
          final reverseExisting = await _isar.jiveExchangeRates
              .filter()
              .fromCurrencyEqualTo(to)
              .toCurrencyEqualTo(baseCurrency)
              .findFirst();

          final reverseRate = 1.0 / response.rate;
          if (reverseExisting != null) {
            reverseExisting.rate = reverseRate;
            reverseExisting.source = response.source;
            reverseExisting.updatedAt = now;
            await _isar.jiveExchangeRates.put(reverseExisting);
          } else {
            final newReverseRate = JiveExchangeRate()
              ..fromCurrency = to
              ..toCurrency = baseCurrency
              ..rate = reverseRate
              ..effectiveDate = now
              ..source = response.source
              ..updatedAt = now;
            await _isar.jiveExchangeRates.put(newReverseRate);
          }
        });
      }
    }

    // 更新最后刷新时间
    final pref = await getPreference();
    if (pref != null) {
      pref.lastRateUpdate = now;
      await updatePreference(pref);
    }

    return results;
  }

  /// 手动设置汇率
  Future<void> setManualRate(String from, String to, double rate) async {
    final now = DateTime.now();
    await _isar.writeTxn(() async {
      // 更新正向汇率
      final existing = await _isar.jiveExchangeRates
          .filter()
          .fromCurrencyEqualTo(from)
          .toCurrencyEqualTo(to)
          .findFirst();

      if (existing != null) {
        existing.rate = rate;
        existing.source = 'manual';
        existing.updatedAt = now;
        await _isar.jiveExchangeRates.put(existing);
      } else {
        final newRate = JiveExchangeRate()
          ..fromCurrency = from
          ..toCurrency = to
          ..rate = rate
          ..effectiveDate = now
          ..source = 'manual'
          ..updatedAt = now;
        await _isar.jiveExchangeRates.put(newRate);
      }

      // 同时更新反向汇率
      final reverseExisting = await _isar.jiveExchangeRates
          .filter()
          .fromCurrencyEqualTo(to)
          .toCurrencyEqualTo(from)
          .findFirst();

      final reverseRate = 1.0 / rate;
      if (reverseExisting != null) {
        reverseExisting.rate = reverseRate;
        reverseExisting.source = 'manual';
        reverseExisting.updatedAt = now;
        await _isar.jiveExchangeRates.put(reverseExisting);
      } else {
        final newReverseRate = JiveExchangeRate()
          ..fromCurrency = to
          ..toCurrency = from
          ..rate = reverseRate
          ..effectiveDate = now
          ..source = 'manual'
          ..updatedAt = now;
        await _isar.jiveExchangeRates.put(newReverseRate);
      }
    });
  }

  /// 获取所有汇率记录
  Future<List<JiveExchangeRate>> getAllRates() async {
    return await _isar.jiveExchangeRates.where().findAll();
  }

  /// 获取基于某货币的所有汇率
  Future<List<JiveExchangeRate>> getRatesFrom(String baseCurrency) async {
    return await _isar.jiveExchangeRates
        .filter()
        .fromCurrencyEqualTo(baseCurrency)
        .findAll();
  }

  /// 格式化金额（根据货币）
  String formatAmount(double amount, String currencyCode) {
    final symbol = CurrencyDefaults.getSymbol(currencyCode);
    final decimals = CurrencyDefaults.getDecimalPlaces(currencyCode);
    final formatted = amount.toStringAsFixed(decimals);

    // 添加千分位
    final parts = formatted.split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
    final result = parts.length > 1 ? '$intPart.${parts[1]}' : intPart;

    return '$symbol$result';
  }

  /// 格式化汇率显示
  String formatRate(double rate, {int decimals = 4}) {
    if (rate >= 100) {
      return rate.toStringAsFixed(2);
    } else if (rate >= 1) {
      return rate.toStringAsFixed(4);
    } else if (rate >= 0.01) {
      return rate.toStringAsFixed(6);
    } else {
      return rate.toStringAsFixed(8);
    }
  }
}

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

  // 内存缓存
  static final Map<String, _CachedRate> _rateCache = {};
  static const Duration _cacheDuration = Duration(minutes: 30);

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

  /// 重置为离线汇率包（清除手动和API汇率，恢复预置数据）
  Future<void> resetToOfflineRates() async {
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
            ..source = 'offline'
            ..updatedAt = now);
        }
      }
    }

    await _isar.writeTxn(() async {
      // 清除所有现有汇率
      await _isar.jiveExchangeRates.clear();
      // 写入离线汇率包
      await _isar.jiveExchangeRates.putAll(rates);
    });

    // 清除内存缓存
    clearCache();
  }

  /// 获取离线汇率包信息
  static Map<String, String> getOfflinePackageInfo() {
    return {
      'version': CurrencyDefaults.offlineRateVersion,
      'date': CurrencyDefaults.offlineRateDate,
      'currencies': CurrencyDefaults.ratesAgainstUSD.length.toString(),
    };
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

  /// 获取收藏的货币对
  Future<List<String>> getFavoritePairs() async {
    final pref = await getPreference();
    return pref?.favoritePairs ?? [];
  }

  /// 添加货币对到收藏夹
  Future<void> addFavoritePair(String from, String to) async {
    final pref = await getPreference();
    if (pref == null) return;
    final pair = '$from/$to';
    if (!pref.favoritePairs.contains(pair)) {
      pref.favoritePairs = [...pref.favoritePairs, pair];
      await updatePreference(pref);
    }
  }

  /// 从收藏夹移除货币对
  Future<void> removeFavoritePair(String from, String to) async {
    final pref = await getPreference();
    if (pref == null) return;
    final pair = '$from/$to';
    if (pref.favoritePairs.contains(pair)) {
      pref.favoritePairs = pref.favoritePairs.where((p) => p != pair).toList();
      await updatePreference(pref);
    }
  }

  /// 检查货币对是否已收藏
  Future<bool> isFavoritePair(String from, String to) async {
    final pairs = await getFavoritePairs();
    return pairs.contains('$from/$to');
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

  /// 获取汇率（带内存缓存）
  Future<double?> getRate(String from, String to) async {
    if (from == to) return 1.0;

    // 检查内存缓存
    final cacheKey = '$from/$to';
    final cached = _rateCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      return cached.rate;
    }

    // 查本地数据库
    final rate = await _isar.jiveExchangeRates
        .filter()
        .fromCurrencyEqualTo(from)
        .toCurrencyEqualTo(to)
        .sortByEffectiveDateDesc()
        .findFirst();

    if (rate != null) {
      // 更新内存缓存
      _rateCache[cacheKey] = _CachedRate(
        rate: rate.rate,
        cachedAt: DateTime.now(),
        source: rate.source,
      );
      return rate.rate;
    }

    // 本地没有则使用默认汇率
    final defaultRate = CurrencyDefaults.getRate(from, to);
    if (defaultRate != null) {
      _rateCache[cacheKey] = _CachedRate(
        rate: defaultRate,
        cachedAt: DateTime.now(),
        source: 'default',
      );
    }
    return defaultRate;
  }

  /// 清除汇率缓存
  static void clearCache() {
    _rateCache.clear();
  }

  /// 检查汇率是否需要更新（超过指定时间）
  Future<bool> shouldUpdateRates({Duration maxAge = const Duration(hours: 6)}) async {
    final pref = await getPreference();
    if (pref?.lastRateUpdate == null) return true;
    return DateTime.now().difference(pref!.lastRateUpdate!) > maxAge;
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

  /// 获取汇率历史记录
  Future<List<JiveExchangeRateHistory>> getRateHistory(
    String from,
    String to, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 30,
  }) async {
    var query = _isar.jiveExchangeRateHistorys
        .filter()
        .fromCurrencyEqualTo(from)
        .toCurrencyEqualTo(to);

    if (startDate != null) {
      query = query.recordedAtGreaterThan(startDate);
    }
    if (endDate != null) {
      query = query.recordedAtLessThan(endDate);
    }

    return await query.sortByRecordedAtDesc().limit(limit).findAll();
  }

  /// 保存汇率历史记录
  Future<void> saveRateHistory(String from, String to, double rate, String source) async {
    final history = JiveExchangeRateHistory()
      ..fromCurrency = from
      ..toCurrency = to
      ..rate = rate
      ..recordedAt = DateTime.now()
      ..source = source;

    await _isar.writeTxn(() async {
      await _isar.jiveExchangeRateHistorys.put(history);
    });
  }

  /// 查询指定日期的历史汇率
  Future<double?> getHistoricalRate(String from, String to, DateTime date) async {
    // 查找最接近指定日期的记录
    final history = await _isar.jiveExchangeRateHistorys
        .filter()
        .fromCurrencyEqualTo(from)
        .toCurrencyEqualTo(to)
        .recordedAtLessThan(date.add(const Duration(days: 1)))
        .sortByRecordedAtDesc()
        .findFirst();

    return history?.rate;
  }

  /// 获取汇率趋势统计
  Future<RateTrendStats?> getRateTrendStats(
    String from,
    String to, {
    int days = 30,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days));
    final history = await getRateHistory(from, to, startDate: startDate, limit: 100);

    if (history.isEmpty) return null;

    final rates = history.map((h) => h.rate).toList();
    final min = rates.reduce((a, b) => a < b ? a : b);
    final max = rates.reduce((a, b) => a > b ? a : b);
    final sum = rates.reduce((a, b) => a + b);
    final avg = sum / rates.length;

    final current = await getRate(from, to) ?? rates.first;
    final first = rates.last;
    final change = current - first;
    final changePercent = first > 0 ? (change / first) * 100 : 0;

    return RateTrendStats(
      from: from,
      to: to,
      current: current,
      min: min,
      max: max,
      avg: avg,
      change: change,
      changePercent: changePercent.toDouble(),
      dataPoints: history.length,
      period: days,
    );
  }

  /// 货币转换
  Future<double?> convert(double amount, String from, String to) async {
    final rate = await getRate(from, to);
    if (rate == null) return null;
    return amount * rate;
  }

  /// 从在线 API 获取实时汇率
  Future<ExchangeRateResponse?> fetchLiveRate(String from, String to) async {
    // 检查是否为加密货币
    final currencies = CurrencyDefaults.getAllCurrencies();
    final fromCurrency = currencies.firstWhere(
      (c) => c['code'] == from,
      orElse: () => <String, dynamic>{},
    );
    final toCurrency = currencies.firstWhere(
      (c) => c['code'] == to,
      orElse: () => <String, dynamic>{},
    );

    final fromIsCrypto = fromCurrency['isCrypto'] == true;
    final toIsCrypto = toCurrency['isCrypto'] == true;

    if (fromIsCrypto || toIsCrypto) {
      // 尝试从 CoinGecko 获取加密货币价格
      final cryptoResponse = await _fetchCryptoRate(from, to, fromIsCrypto, toIsCrypto);
      if (cryptoResponse != null) return cryptoResponse;

      // 失败则使用本地 Mock 数据
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

  /// 从 CoinGecko 获取加密货币价格
  Future<ExchangeRateResponse?> _fetchCryptoRate(
    String from,
    String to,
    bool fromIsCrypto,
    bool toIsCrypto,
  ) async {
    try {
      // CoinGecko 使用的币种 ID 映射
      const coinGeckoIds = {
        'BTC': 'bitcoin',
        'ETH': 'ethereum',
        'USDT': 'tether',
        'USDC': 'usd-coin',
        'BNB': 'binancecoin',
        'SOL': 'solana',
        'XRP': 'ripple',
        'ADA': 'cardano',
        'DOGE': 'dogecoin',
        'LTC': 'litecoin',
      };

      if (fromIsCrypto && !toIsCrypto) {
        // 从加密货币转换为法币
        final cryptoId = coinGeckoIds[from];
        if (cryptoId == null) return null;

        final vsCurrency = to.toLowerCase();
        final url = 'https://api.coingecko.com/api/v3/simple/price?ids=$cryptoId&vs_currencies=$vsCurrency';
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final priceData = data[cryptoId] as Map<String, dynamic>?;
          if (priceData != null && priceData.containsKey(vsCurrency)) {
            final price = (priceData[vsCurrency] as num).toDouble();
            return ExchangeRateResponse(
              from: from,
              to: to,
              rate: price,
              date: DateTime.now(),
              source: 'coingecko',
            );
          }
        }
      } else if (!fromIsCrypto && toIsCrypto) {
        // 从法币转换为加密货币
        final cryptoId = coinGeckoIds[to];
        if (cryptoId == null) return null;

        final vsCurrency = from.toLowerCase();
        final url = 'https://api.coingecko.com/api/v3/simple/price?ids=$cryptoId&vs_currencies=$vsCurrency';
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final priceData = data[cryptoId] as Map<String, dynamic>?;
          if (priceData != null && priceData.containsKey(vsCurrency)) {
            final price = (priceData[vsCurrency] as num).toDouble();
            // 反向汇率
            return ExchangeRateResponse(
              from: from,
              to: to,
              rate: 1.0 / price,
              date: DateTime.now(),
              source: 'coingecko',
            );
          }
        }
      } else if (fromIsCrypto && toIsCrypto) {
        // 两个都是加密货币，通过 USD 中转
        final fromId = coinGeckoIds[from];
        final toId = coinGeckoIds[to];
        if (fromId == null || toId == null) return null;

        final url = 'https://api.coingecko.com/api/v3/simple/price?ids=$fromId,$toId&vs_currencies=usd';
        final response = await http.get(Uri.parse(url)).timeout(
          const Duration(seconds: 10),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final fromPriceData = data[fromId] as Map<String, dynamic>?;
          final toPriceData = data[toId] as Map<String, dynamic>?;
          if (fromPriceData != null &&
              toPriceData != null &&
              fromPriceData.containsKey('usd') &&
              toPriceData.containsKey('usd')) {
            final fromPrice = (fromPriceData['usd'] as num).toDouble();
            final toPrice = (toPriceData['usd'] as num).toDouble();
            if (toPrice > 0) {
              return ExchangeRateResponse(
                from: from,
                to: to,
                rate: fromPrice / toPrice,
                date: DateTime.now(),
                source: 'coingecko',
              );
            }
          }
        }
      }
    } catch (_) {}
    return null;
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

          // 保存汇率历史记录
          final history = JiveExchangeRateHistory()
            ..fromCurrency = baseCurrency
            ..toCurrency = to
            ..rate = response.rate
            ..recordedAt = now
            ..source = response.source;
          await _isar.jiveExchangeRateHistorys.put(history);
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

      // 保存汇率历史记录
      final history = JiveExchangeRateHistory()
        ..fromCurrency = from
        ..toCurrency = to
        ..rate = rate
        ..recordedAt = now
        ..source = 'manual';
      await _isar.jiveExchangeRateHistorys.put(history);
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

  /// 计算多币种资产总览
  /// [accounts] 所有账户列表
  /// [balances] 账户余额映射
  /// [baseCurrency] 转换的基础货币
  Future<MultiCurrencyAssetOverview> calculateMultiCurrencyOverview(
    List<dynamic> accounts, // JiveAccount list
    Map<int, double> balances,
    String? baseCurrency,
  ) async {
    final targetCurrency = baseCurrency ?? await getBaseCurrency();

    // 按币种和类型分组
    final assetsByType = <String, Map<String, List<dynamic>>>{}; // 'asset' or 'liability' -> currency -> accounts
    assetsByType['asset'] = {};
    assetsByType['liability'] = {};

    for (final account in accounts) {
      if (account.isHidden || account.isArchived || !account.includeInBalance) continue;

      final currency = account.currency as String;
      final type = (account.type as String) == 'liability' ? 'liability' : 'asset';

      assetsByType[type] ??= {};
      assetsByType[type]![currency] ??= [];
      assetsByType[type]![currency]!.add(account);
    }

    // 处理资产组
    final assetGroups = <CurrencyAssetGroup>[];
    double totalAssets = 0;

    for (final entry in assetsByType['asset']!.entries) {
      final currency = entry.key;
      final currencyAccounts = entry.value;
      final currencyData = CurrencyDefaults.getAllCurrencies().firstWhere(
        (c) => c['code'] == currency,
        orElse: () => {'code': currency, 'nameZh': currency, 'symbol': currency},
      );

      double totalAmount = 0;
      final accountItems = <CurrencyAccountItem>[];

      for (final account in currencyAccounts) {
        final balance = balances[account.id] ?? account.openingBalance;
        totalAmount += balance;

        // 转换为基础货币
        double convertedBalance = balance;
        if (currency != targetCurrency) {
          convertedBalance = await convert(balance, currency, targetCurrency) ?? balance;
        }

        accountItems.add(CurrencyAccountItem(
          accountId: account.id,
          accountName: account.name,
          accountType: account.type,
          iconName: account.iconName,
          balance: balance,
          convertedBalance: convertedBalance,
        ));
      }

      // 计算该币种的转换总额
      double convertedTotal = totalAmount;
      if (currency != targetCurrency) {
        convertedTotal = await convert(totalAmount, currency, targetCurrency) ?? totalAmount;
      }
      totalAssets += convertedTotal;

      assetGroups.add(CurrencyAssetGroup(
        currency: currency,
        currencyName: currencyData['nameZh'] as String,
        flag: currencyData['flag'] as String?,
        symbol: currencyData['symbol'] as String,
        totalAmount: totalAmount,
        convertedAmount: convertedTotal,
        accountCount: currencyAccounts.length,
        accounts: accountItems,
      ));
    }

    // 处理负债组
    final liabilityGroups = <CurrencyAssetGroup>[];
    double totalLiabilities = 0;

    for (final entry in assetsByType['liability']!.entries) {
      final currency = entry.key;
      final currencyAccounts = entry.value;
      final currencyData = CurrencyDefaults.getAllCurrencies().firstWhere(
        (c) => c['code'] == currency,
        orElse: () => {'code': currency, 'nameZh': currency, 'symbol': currency},
      );

      double totalAmount = 0;
      final accountItems = <CurrencyAccountItem>[];

      for (final account in currencyAccounts) {
        final balance = (balances[account.id] ?? account.openingBalance).abs();
        totalAmount += balance;

        double convertedBalance = balance;
        if (currency != targetCurrency) {
          convertedBalance = await convert(balance, currency, targetCurrency) ?? balance;
        }

        accountItems.add(CurrencyAccountItem(
          accountId: account.id,
          accountName: account.name,
          accountType: account.type,
          iconName: account.iconName,
          balance: balance,
          convertedBalance: convertedBalance,
        ));
      }

      double convertedTotal = totalAmount;
      if (currency != targetCurrency) {
        convertedTotal = await convert(totalAmount, currency, targetCurrency) ?? totalAmount;
      }
      totalLiabilities += convertedTotal;

      liabilityGroups.add(CurrencyAssetGroup(
        currency: currency,
        currencyName: currencyData['nameZh'] as String,
        flag: currencyData['flag'] as String?,
        symbol: currencyData['symbol'] as String,
        totalAmount: totalAmount,
        convertedAmount: convertedTotal,
        accountCount: currencyAccounts.length,
        accounts: accountItems,
      ));
    }

    // 按转换后金额排序
    assetGroups.sort((a, b) => b.convertedAmount.compareTo(a.convertedAmount));
    liabilityGroups.sort((a, b) => b.convertedAmount.compareTo(a.convertedAmount));

    return MultiCurrencyAssetOverview(
      baseCurrency: targetCurrency,
      totalAssets: totalAssets,
      totalLiabilities: totalLiabilities,
      netWorth: totalAssets - totalLiabilities,
      assetGroups: assetGroups,
      liabilityGroups: liabilityGroups,
      calculatedAt: DateTime.now(),
    );
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

  /// 获取所有汇率历史记录（用于清理）
  Future<List<JiveExchangeRateHistory>> getAllRateHistory() async {
    return await _isar.jiveExchangeRateHistorys.where().findAll();
  }

  /// 清理旧的汇率历史记录（保留最近N条）
  Future<int> cleanOldRateHistory({int keepCount = 100}) async {
    // 获取所有货币对
    final allHistory = await _isar.jiveExchangeRateHistorys.where().findAll();
    final pairs = <String>{};
    for (final h in allHistory) {
      pairs.add('${h.fromCurrency}/${h.toCurrency}');
    }

    var deletedCount = 0;
    for (final pair in pairs) {
      final parts = pair.split('/');
      final from = parts[0];
      final to = parts[1];

      // 获取该货币对的所有历史记录，按时间降序
      final history = await _isar.jiveExchangeRateHistorys
          .filter()
          .fromCurrencyEqualTo(from)
          .toCurrencyEqualTo(to)
          .sortByRecordedAtDesc()
          .findAll();

      // 删除超出保留数量的记录
      if (history.length > keepCount) {
        final toDelete = history.sublist(keepCount);
        await _isar.writeTxn(() async {
          for (final h in toDelete) {
            await _isar.jiveExchangeRateHistorys.delete(h.id);
            deletedCount++;
          }
        });
      }
    }

    return deletedCount;
  }

  /// 汇率变动信息
  RateChangeInfo? calculateRateChange(double oldRate, double newRate, String from, String to) {
    if (oldRate == 0) return null;
    final changePercent = ((newRate - oldRate) / oldRate) * 100;
    return RateChangeInfo(
      from: from,
      to: to,
      oldRate: oldRate,
      newRate: newRate,
      changePercent: changePercent,
    );
  }

  /// 批量获取汇率并检测变动
  Future<RateUpdateResult> fetchAndUpdateRatesWithChangeDetection(
    String baseCurrency,
    List<String> targets, {
    double? changeThreshold,
  }) async {
    final changes = <RateChangeInfo>[];
    final threshold = changeThreshold ?? 1.0;

    // 先获取旧汇率
    final oldRates = <String, double>{};
    for (final to in targets) {
      if (to == baseCurrency) continue;
      final rate = await getRate(baseCurrency, to);
      if (rate != null) {
        oldRates[to] = rate;
      }
    }

    // 更新汇率
    final updatedRates = await fetchAndUpdateRates(baseCurrency, targets);

    // 检测变动
    for (final entry in updatedRates.entries) {
      final to = entry.key;
      final newRate = entry.value;
      final oldRate = oldRates[to];

      if (oldRate != null) {
        final change = calculateRateChange(oldRate, newRate, baseCurrency, to);
        if (change != null && change.changePercent.abs() >= threshold) {
          changes.add(change);
        }
      }
    }

    return RateUpdateResult(
      updatedRates: updatedRates,
      significantChanges: changes,
    );
  }
}

/// 汇率变动信息
class RateChangeInfo {
  final String from;
  final String to;
  final double oldRate;
  final double newRate;
  final double changePercent;

  RateChangeInfo({
    required this.from,
    required this.to,
    required this.oldRate,
    required this.newRate,
    required this.changePercent,
  });

  bool get isIncrease => changePercent > 0;

  String get changeText {
    final sign = isIncrease ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(2)}%';
  }
}

/// 汇率更新结果
class RateUpdateResult {
  final Map<String, double> updatedRates;
  final List<RateChangeInfo> significantChanges;

  RateUpdateResult({
    required this.updatedRates,
    required this.significantChanges,
  });

  bool get hasSignificantChanges => significantChanges.isNotEmpty;
}

/// 缓存的汇率
class _CachedRate {
  final double rate;
  final DateTime cachedAt;
  final String source;

  _CachedRate({
    required this.rate,
    required this.cachedAt,
    required this.source,
  });

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > CurrencyService._cacheDuration;
}

/// 汇率趋势统计
class RateTrendStats {
  final String from;
  final String to;
  final double current;
  final double min;
  final double max;
  final double avg;
  final double change;
  final double changePercent;
  final int dataPoints;
  final int period; // 统计周期（天）

  RateTrendStats({
    required this.from,
    required this.to,
    required this.current,
    required this.min,
    required this.max,
    required this.avg,
    required this.change,
    required this.changePercent,
    required this.dataPoints,
    required this.period,
  });

  bool get isUp => changePercent > 0;
  bool get isDown => changePercent < 0;

  String get changeText {
    final sign = isUp ? '+' : '';
    return '$sign${changePercent.toStringAsFixed(2)}%';
  }

  String get trendIcon {
    if (changePercent.abs() < 0.1) return '→';
    return isUp ? '↑' : '↓';
  }
}

/// 按币种分组的资产数据
class CurrencyAssetGroup {
  final String currency;
  final String currencyName;
  final String? flag;
  final String symbol;
  final double totalAmount; // 该币种的总金额
  final double convertedAmount; // 转换为主币种后的金额
  final int accountCount; // 该币种的账户数量
  final List<CurrencyAccountItem> accounts; // 该币种下的账户列表

  CurrencyAssetGroup({
    required this.currency,
    required this.currencyName,
    this.flag,
    required this.symbol,
    required this.totalAmount,
    required this.convertedAmount,
    required this.accountCount,
    required this.accounts,
  });

  /// 该币种占总资产的百分比
  double percentageOf(double totalAssets) {
    if (totalAssets <= 0) return 0;
    return convertedAmount / totalAssets * 100;
  }
}

/// 单个账户的资产项
class CurrencyAccountItem {
  final int accountId;
  final String accountName;
  final String accountType;
  final String iconName;
  final double balance;
  final double convertedBalance;

  CurrencyAccountItem({
    required this.accountId,
    required this.accountName,
    required this.accountType,
    required this.iconName,
    required this.balance,
    required this.convertedBalance,
  });
}

/// 多币种资产总览数据
class MultiCurrencyAssetOverview {
  final String baseCurrency;
  final double totalAssets; // 转换后的总资产
  final double totalLiabilities; // 转换后的总负债
  final double netWorth; // 净资产
  final List<CurrencyAssetGroup> assetGroups; // 按币种分组的资产
  final List<CurrencyAssetGroup> liabilityGroups; // 按币种分组的负债
  final DateTime calculatedAt;

  MultiCurrencyAssetOverview({
    required this.baseCurrency,
    required this.totalAssets,
    required this.totalLiabilities,
    required this.netWorth,
    required this.assetGroups,
    required this.liabilityGroups,
    required this.calculatedAt,
  });

  /// 获取所有涉及的币种列表
  List<String> get allCurrencies {
    final currencies = <String>{};
    for (final group in [...assetGroups, ...liabilityGroups]) {
      currencies.add(group.currency);
    }
    return currencies.toList()..sort();
  }

  /// 获取资产前N的币种
  List<CurrencyAssetGroup> topAssetCurrencies(int n) {
    final sorted = List<CurrencyAssetGroup>.from(assetGroups)
      ..sort((a, b) => b.convertedAmount.compareTo(a.convertedAmount));
    return sorted.take(n).toList();
  }
}

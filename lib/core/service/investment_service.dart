import 'package:isar/isar.dart';

import '../database/currency_model.dart';
import '../database/investment_model.dart';
import 'currency_service.dart';

class InvestmentValidationException implements Exception {
  final String code;
  final String message;

  const InvestmentValidationException(this.code, this.message);

  @override
  String toString() => 'InvestmentValidationException($code): $message';
}

/// 持仓估值快照
class HoldingValuation {
  final JiveHolding holding;
  final JiveSecurity security;
  final String baseCurrency;
  final double currentPrice;
  final double marketValue; // quantity * currentPrice, security currency
  final double totalCost; // quantity * costBasis, security currency
  final double profitLoss; // marketValue - totalCost, security currency
  final double marketValueInBase; // converted into base currency
  final double totalCostInBase; // converted into base currency
  final double profitLossInBase; // converted into base currency
  final double profitLossPercent; // (profitLoss / totalCost) * 100

  const HoldingValuation({
    required this.holding,
    required this.security,
    required this.baseCurrency,
    required this.currentPrice,
    required this.marketValue,
    required this.totalCost,
    required this.profitLoss,
    required this.marketValueInBase,
    required this.totalCostInBase,
    required this.profitLossInBase,
    required this.profitLossPercent,
  });
}

/// 投资组合汇总
class PortfolioSummary {
  final String baseCurrency;
  final double totalMarketValue;
  final double totalCost;
  final double totalProfitLoss;
  final double totalProfitLossPercent;
  final int holdingCount;
  final List<HoldingValuation> holdings;

  const PortfolioSummary({
    required this.baseCurrency,
    required this.totalMarketValue,
    required this.totalCost,
    required this.totalProfitLoss,
    required this.totalProfitLossPercent,
    required this.holdingCount,
    required this.holdings,
  });
}

class InvestmentService {
  final Isar _isar;

  InvestmentService(this._isar);

  // ── Securities ──

  Future<JiveSecurity> addSecurity({
    required String ticker,
    required String name,
    required String type,
    required String currency,
    String? exchange,
    double? latestPrice,
  }) async {
    final normalizedTicker = ticker.toUpperCase().trim();
    final normalizedName = name.trim();
    final normalizedCurrency = currency.toUpperCase().trim();

    if (normalizedTicker.isEmpty) {
      throw const InvestmentValidationException('ticker_required', '证券代码不能为空');
    }
    if (normalizedName.isEmpty) {
      throw const InvestmentValidationException('name_required', '证券名称不能为空');
    }
    if (!_isSupportedCurrency(normalizedCurrency)) {
      throw InvestmentValidationException(
        'currency_unsupported',
        '暂不支持币种 $normalizedCurrency',
      );
    }
    if (latestPrice != null && (!_isFinitePositive(latestPrice))) {
      throw const InvestmentValidationException('price_invalid', '当前价格必须大于 0');
    }

    final existing = await _isar.jiveSecuritys.getByTicker(normalizedTicker);
    if (existing != null) {
      throw const InvestmentValidationException('ticker_exists', '证券代码已存在');
    }

    final now = DateTime.now();
    final security = JiveSecurity()
      ..ticker = normalizedTicker
      ..name = normalizedName
      ..type = type
      ..exchange = exchange
      ..currency = normalizedCurrency
      ..latestPrice = latestPrice
      ..priceUpdatedAt = latestPrice != null ? now : null
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.jiveSecuritys.put(security);
    });
    return security;
  }

  Future<List<JiveSecurity>> getSecurities() async {
    return _isar.jiveSecuritys.where().sortByName().findAll();
  }

  Future<void> updatePrice(int securityId, double price) async {
    if (!_isFinitePositive(price)) {
      throw const InvestmentValidationException('price_invalid', '最新价格必须大于 0');
    }
    final security = await _isar.jiveSecuritys.get(securityId);
    if (security == null) {
      throw StateError('security_missing');
    }
    security.latestPrice = price;
    security.priceUpdatedAt = DateTime.now();
    security.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveSecuritys.put(security);
    });

    // 记录价格历史
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final existing = await _isar.jivePriceHistorys
        .filter()
        .securityIdEqualTo(securityId)
        .dateEqualTo(today)
        .findFirst();
    if (existing != null) {
      existing.closePrice = price;
      await _isar.writeTxn(() async {
        await _isar.jivePriceHistorys.put(existing);
      });
    } else {
      final history = JivePriceHistory()
        ..securityId = securityId
        ..date = today
        ..closePrice = price;
      await _isar.writeTxn(() async {
        await _isar.jivePriceHistorys.put(history);
      });
    }
  }

  // ── Holdings ──

  Future<JiveHolding> addHolding({
    required int securityId,
    required double quantity,
    required double costBasis,
    int? accountId,
    String? note,
  }) async {
    if (!_isFinitePositive(quantity)) {
      throw const InvestmentValidationException(
        'quantity_invalid',
        '持仓数量必须大于 0',
      );
    }
    if (!_isFinitePositive(costBasis)) {
      throw const InvestmentValidationException(
        'cost_basis_invalid',
        '成本价必须大于 0',
      );
    }
    final now = DateTime.now();
    final holding = JiveHolding()
      ..securityId = securityId
      ..quantity = quantity
      ..costBasis = costBasis
      ..accountId = accountId
      ..note = note
      ..createdAt = now
      ..updatedAt = now;

    await _isar.writeTxn(() async {
      await _isar.jiveHoldings.put(holding);
    });
    return holding;
  }

  Future<List<JiveHolding>> getHoldings() async {
    return _isar.jiveHoldings.where().findAll();
  }

  Future<JiveHolding?> getHolding({
    required int securityId,
    int? accountId,
  }) async {
    return _isar.jiveHoldings
        .filter()
        .securityIdEqualTo(securityId)
        .accountIdEqualTo(accountId)
        .findFirst();
  }

  Future<double> getHoldingQuantity({
    required int securityId,
    int? accountId,
  }) async {
    final holding = await getHolding(
      securityId: securityId,
      accountId: accountId,
    );
    return holding?.quantity ?? 0;
  }

  Future<void> updateHolding(JiveHolding holding) async {
    holding.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveHoldings.put(holding);
    });
  }

  Future<void> deleteHolding(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveHoldings.delete(id);
    });
  }

  // ── Investment Transactions ──

  Future<void> recordTransaction({
    required int securityId,
    required String action, // 'buy' or 'sell'
    required double quantity,
    required double price,
    double fee = 0,
    int? accountId,
    DateTime? transactionDate,
    String? note,
  }) async {
    final normalizedAction = action.trim().toLowerCase();
    if (normalizedAction != 'buy' && normalizedAction != 'sell') {
      throw InvestmentValidationException(
        'action_invalid',
        '不支持的交易类型: $action',
      );
    }
    if (!_isFinitePositive(quantity)) {
      throw const InvestmentValidationException(
        'quantity_invalid',
        '交易数量必须大于 0',
      );
    }
    if (!_isFinitePositive(price)) {
      throw const InvestmentValidationException('price_invalid', '交易价格必须大于 0');
    }
    if (!_isFiniteNonNegative(fee)) {
      throw const InvestmentValidationException('fee_invalid', '手续费不能为负数');
    }

    final tx = JiveInvestmentTransaction()
      ..securityId = securityId
      ..action = normalizedAction
      ..quantity = quantity
      ..price = price
      ..fee = fee
      ..accountId = accountId
      ..transactionDate = transactionDate ?? DateTime.now()
      ..note = note
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() async {
      final security = await _isar.jiveSecuritys.get(securityId);
      if (security == null) {
        throw StateError('security_missing');
      }
      if (normalizedAction == 'sell') {
        final holding = await _isar.jiveHoldings
            .filter()
            .securityIdEqualTo(securityId)
            .accountIdEqualTo(accountId)
            .findFirst();
        final availableQuantity = holding?.quantity ?? 0;
        if (quantity > availableQuantity + 1e-9) {
          throw InvestmentValidationException(
            'insufficient_holding',
            '卖出数量超过当前持仓（可卖 ${availableQuantity.toStringAsFixed(4)}）',
          );
        }
      }

      await _isar.jiveInvestmentTransactions.put(tx);
      await _syncHoldingWithinTxn(securityId, accountId);
    });
  }

  Future<void> _syncHoldingWithinTxn(int securityId, int? accountId) async {
    final txs = await _isar.jiveInvestmentTransactions
        .filter()
        .securityIdEqualTo(securityId)
        .accountIdEqualTo(accountId)
        .sortByTransactionDate()
        .findAll();

    double totalQty = 0;
    double totalCost = 0;

    for (final tx in txs) {
      if (tx.action == 'buy') {
        totalCost += tx.quantity * tx.price + tx.fee;
        totalQty += tx.quantity;
      } else {
        if (tx.quantity > totalQty + 1e-9) {
          throw InvestmentValidationException(
            'insufficient_holding_history',
            '交易历史中的卖出数量超过当时持仓，无法重算持仓',
          );
        }
        if (tx.quantity >= totalQty - 1e-9) {
          totalQty = 0;
          totalCost = 0;
          continue;
        }

        // sell: reduce quantity, adjust cost proportionally.
        final avgCost = totalCost / totalQty;
        totalQty -= tx.quantity;
        totalCost = totalQty * avgCost;
      }
    }

    // Find or create holding
    var holding = await _isar.jiveHoldings
        .filter()
        .securityIdEqualTo(securityId)
        .accountIdEqualTo(accountId)
        .findFirst();

    if (totalQty <= 0) {
      // 清仓：删除持仓
      if (holding != null) {
        await _isar.jiveHoldings.delete(holding.id);
      }
      return;
    }

    final avgCost = totalQty > 0 ? totalCost / totalQty : 0.0;

    if (holding == null) {
      final now = DateTime.now();
      holding = JiveHolding()
        ..securityId = securityId
        ..quantity = totalQty
        ..costBasis = avgCost
        ..accountId = accountId
        ..createdAt = now
        ..updatedAt = now;
    } else {
      holding.quantity = totalQty;
      holding.costBasis = avgCost;
      holding.updatedAt = DateTime.now();
    }
    await _isar.jiveHoldings.put(holding);
  }

  // ── Valuation ──

  Future<PortfolioSummary> getPortfolioSummary({
    CurrencyService? currencyService,
    String? baseCurrency,
  }) async {
    final holdings = await getHoldings();
    final securities = await getSecurities();
    final securityMap = {for (final s in securities) s.id: s};
    final effectiveCurrencyService = currencyService ?? CurrencyService(_isar);
    await effectiveCurrencyService.initCurrencies();
    final effectiveBaseCurrency =
        (baseCurrency ?? await effectiveCurrencyService.getBaseCurrency())
            .toUpperCase();

    final valuations = <HoldingValuation>[];
    double totalMV = 0;
    double totalCost = 0;

    for (final h in holdings) {
      final security = securityMap[h.securityId];
      if (security == null) continue;
      final price = security.latestPrice ?? h.costBasis;
      final mv = h.quantity * price;
      final cost = h.totalCost;
      final pl = mv - cost;
      final plPct = cost > 0 ? pl / cost * 100 : 0.0;
      final mvInBase = await _convertAmount(
        value: mv,
        fromCurrency: security.currency,
        toCurrency: effectiveBaseCurrency,
        currencyService: effectiveCurrencyService,
      );
      final costInBase = await _convertAmount(
        value: cost,
        fromCurrency: security.currency,
        toCurrency: effectiveBaseCurrency,
        currencyService: effectiveCurrencyService,
      );
      final plInBase = mvInBase - costInBase;

      valuations.add(
        HoldingValuation(
          holding: h,
          security: security,
          baseCurrency: effectiveBaseCurrency,
          currentPrice: price,
          marketValue: mv,
          totalCost: cost,
          profitLoss: pl,
          marketValueInBase: mvInBase,
          totalCostInBase: costInBase,
          profitLossInBase: plInBase,
          profitLossPercent: plPct,
        ),
      );

      totalMV += mvInBase;
      totalCost += costInBase;
    }

    // Sort by converted market value descending.
    valuations.sort(
      (a, b) => b.marketValueInBase.compareTo(a.marketValueInBase),
    );

    final totalPL = totalMV - totalCost;
    final totalPLPct = totalCost > 0 ? totalPL / totalCost * 100 : 0.0;

    return PortfolioSummary(
      baseCurrency: effectiveBaseCurrency,
      totalMarketValue: totalMV,
      totalCost: totalCost,
      totalProfitLoss: totalPL,
      totalProfitLossPercent: totalPLPct,
      holdingCount: valuations.length,
      holdings: valuations,
    );
  }

  /// 获取价格历史
  Future<List<JivePriceHistory>> getPriceHistory(
    int securityId, {
    int days = 30,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    return _isar.jivePriceHistorys
        .filter()
        .securityIdEqualTo(securityId)
        .dateGreaterThan(since)
        .sortByDate()
        .findAll();
  }

  /// 删除证券及其所有关联数据
  Future<void> deleteSecurity(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveHoldings.filter().securityIdEqualTo(id).deleteAll();
      await _isar.jiveInvestmentTransactions
          .filter()
          .securityIdEqualTo(id)
          .deleteAll();
      await _isar.jivePriceHistorys.filter().securityIdEqualTo(id).deleteAll();
      await _isar.jiveSecuritys.delete(id);
    });
  }

  bool _isSupportedCurrency(String code) {
    return CurrencyDefaults.getAllCurrencies().any(
      (currency) => currency['code'] == code,
    );
  }

  bool _isFinitePositive(double value) => value.isFinite && value > 0;

  bool _isFiniteNonNegative(double value) => value.isFinite && value >= 0;

  Future<double> _convertAmount({
    required double value,
    required String fromCurrency,
    required String toCurrency,
    required CurrencyService currencyService,
  }) async {
    if (fromCurrency == toCurrency) {
      return value;
    }
    final convertedValue = await currencyService.convert(
      value,
      fromCurrency,
      toCurrency,
    );
    if (convertedValue == null) {
      throw InvestmentValidationException(
        'missing_exchange_rate',
        '无法从 $fromCurrency 转换为 $toCurrency：未找到汇率',
      );
    }
    return convertedValue;
  }
}

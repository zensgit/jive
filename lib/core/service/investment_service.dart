import 'package:isar/isar.dart';

import '../database/investment_model.dart';

/// 持仓估值快照
class HoldingValuation {
  final JiveHolding holding;
  final JiveSecurity security;
  final double currentPrice;
  final double marketValue; // quantity * currentPrice
  final double totalCost; // quantity * costBasis
  final double profitLoss; // marketValue - totalCost
  final double profitLossPercent; // (profitLoss / totalCost) * 100

  const HoldingValuation({
    required this.holding,
    required this.security,
    required this.currentPrice,
    required this.marketValue,
    required this.totalCost,
    required this.profitLoss,
    required this.profitLossPercent,
  });
}

/// 投资组合汇总
class PortfolioSummary {
  final double totalMarketValue;
  final double totalCost;
  final double totalProfitLoss;
  final double totalProfitLossPercent;
  final int holdingCount;
  final List<HoldingValuation> holdings;

  const PortfolioSummary({
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
    String? exchange,
    String currency = 'CNY',
    double? latestPrice,
  }) async {
    final now = DateTime.now();
    final security = JiveSecurity()
      ..ticker = ticker.toUpperCase().trim()
      ..name = name.trim()
      ..type = type
      ..exchange = exchange
      ..currency = currency
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
    final security = await _isar.jiveSecuritys.get(securityId);
    if (security == null) return;
    security.latestPrice = price;
    security.priceUpdatedAt = DateTime.now();
    security.updatedAt = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.jiveSecuritys.put(security);
    });

    // 记录价格历史
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
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
    final tx = JiveInvestmentTransaction()
      ..securityId = securityId
      ..action = action
      ..quantity = quantity
      ..price = price
      ..fee = fee
      ..accountId = accountId
      ..transactionDate = transactionDate ?? DateTime.now()
      ..note = note
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveInvestmentTransactions.put(tx);
    });

    // 更新持仓
    await _syncHolding(securityId, accountId);
    // 更新最新价格
    await updatePrice(securityId, price);
  }

  /// 根据交易记录重算持仓
  Future<void> _syncHolding(int securityId, int? accountId) async {
    final txs = await _isar.jiveInvestmentTransactions
        .filter()
        .securityIdEqualTo(securityId)
        .sortByTransactionDate()
        .findAll();

    double totalQty = 0;
    double totalCost = 0;

    for (final tx in txs) {
      if (tx.action == 'buy') {
        totalCost += tx.quantity * tx.price + tx.fee;
        totalQty += tx.quantity;
      } else {
        // sell: reduce quantity, adjust cost proportionally
        if (totalQty > 0) {
          final avgCost = totalCost / totalQty;
          totalQty -= tx.quantity;
          totalCost = totalQty > 0 ? totalQty * avgCost : 0;
        }
      }
    }

    // Find or create holding
    var holding = await _isar.jiveHoldings
        .filter()
        .securityIdEqualTo(securityId)
        .findFirst();

    if (totalQty <= 0) {
      // 清仓：删除持仓
      if (holding != null) {
        await _isar.writeTxn(() async {
          await _isar.jiveHoldings.delete(holding!.id);
        });
      }
      return;
    }

    final avgCost = totalQty > 0 ? totalCost / totalQty : 0.0;

    if (holding == null) {
      await addHolding(
        securityId: securityId,
        quantity: totalQty,
        costBasis: avgCost,
        accountId: accountId,
      );
    } else {
      holding.quantity = totalQty;
      holding.costBasis = avgCost;
      await updateHolding(holding);
    }
  }

  // ── Valuation ──

  Future<PortfolioSummary> getPortfolioSummary() async {
    final holdings = await getHoldings();
    final securities = await getSecurities();
    final securityMap = {for (final s in securities) s.id: s};

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

      valuations.add(HoldingValuation(
        holding: h,
        security: security,
        currentPrice: price,
        marketValue: mv,
        totalCost: cost,
        profitLoss: pl,
        profitLossPercent: plPct,
      ));

      totalMV += mv;
      totalCost += cost;
    }

    // Sort by market value descending
    valuations.sort((a, b) => b.marketValue.compareTo(a.marketValue));

    final totalPL = totalMV - totalCost;
    final totalPLPct = totalCost > 0 ? totalPL / totalCost * 100 : 0.0;

    return PortfolioSummary(
      totalMarketValue: totalMV,
      totalCost: totalCost,
      totalProfitLoss: totalPL,
      totalProfitLossPercent: totalPLPct,
      holdingCount: holdings.length,
      holdings: valuations,
    );
  }

  /// 获取价格历史
  Future<List<JivePriceHistory>> getPriceHistory(int securityId, {int days = 30}) async {
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
      await _isar.jiveInvestmentTransactions.filter().securityIdEqualTo(id).deleteAll();
      await _isar.jivePriceHistorys.filter().securityIdEqualTo(id).deleteAll();
      await _isar.jiveSecuritys.delete(id);
    });
  }
}

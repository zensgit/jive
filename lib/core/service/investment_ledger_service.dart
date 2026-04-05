import 'package:isar/isar.dart';

import '../database/investment_model.dart';

/// 投资操作类型
enum InvestmentAction {
  buy,
  sell,
  dividend,
  split,
  fee;

  String get label {
    switch (this) {
      case InvestmentAction.buy:
        return '买入';
      case InvestmentAction.sell:
        return '卖出';
      case InvestmentAction.dividend:
        return '分红';
      case InvestmentAction.split:
        return '拆股';
      case InvestmentAction.fee:
        return '费用';
    }
  }
}

/// 成本基础快照
class CostBasis {
  final double totalCost;
  final double avgCostPerShare;
  final double totalShares;

  const CostBasis({
    required this.totalCost,
    required this.avgCostPerShare,
    required this.totalShares,
  });
}

/// 增强型投资账本服务 — 支持分红、拆股、成本基础追踪
class InvestmentLedgerService {
  final Isar _isar;

  InvestmentLedgerService(this._isar);

  // ── Dividend ──

  /// 记录现金分红，写入交易记录
  Future<void> recordDividend({
    required int securityId,
    required double amount,
    int? accountId,
    DateTime? date,
  }) async {
    if (!amount.isFinite || amount <= 0) {
      throw ArgumentError('分红金额必须大于 0');
    }

    final security = await _isar.jiveSecuritys.get(securityId);
    if (security == null) {
      throw StateError('security_missing');
    }

    final tx = JiveInvestmentTransaction()
      ..securityId = securityId
      ..action = InvestmentAction.dividend.name
      ..quantity = 0
      ..price = amount // store dividend amount in price field
      ..fee = 0
      ..accountId = accountId
      ..transactionDate = date ?? DateTime.now()
      ..note = '现金分红 ¥${amount.toStringAsFixed(2)}'
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveInvestmentTransactions.put(tx);
    });
  }

  // ── Split ──

  /// 记录拆股。ratio 为新股数/旧股数，如 2:1 拆股传 ratio=2.0
  /// 持仓数量乘以 ratio，成本价除以 ratio，总成本不变
  Future<void> recordSplit({
    required int securityId,
    required double ratio,
    int? accountId,
  }) async {
    if (!ratio.isFinite || ratio <= 0) {
      throw ArgumentError('拆股比例必须大于 0');
    }

    final security = await _isar.jiveSecuritys.get(securityId);
    if (security == null) {
      throw StateError('security_missing');
    }

    // 记录拆股交易
    final tx = JiveInvestmentTransaction()
      ..securityId = securityId
      ..action = InvestmentAction.split.name
      ..quantity = ratio // store ratio in quantity
      ..price = 0
      ..fee = 0
      ..accountId = accountId
      ..transactionDate = DateTime.now()
      ..note = '拆股 ${ratio.toStringAsFixed(0)}:1'
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveInvestmentTransactions.put(tx);
    });

    // 更新持仓: 数量 * ratio, 成本价 / ratio
    final holding = await _isar.jiveHoldings
        .filter()
        .securityIdEqualTo(securityId)
        .optional(accountId != null, (q) => q.accountIdEqualTo(accountId))
        .findFirst();

    if (holding != null) {
      holding.quantity = holding.quantity * ratio;
      holding.costBasis = holding.costBasis / ratio;
      holding.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.jiveHoldings.put(holding);
      });
    }

    // 更新证券最新价格（拆股后价格也应除以 ratio）
    if (security.latestPrice != null) {
      security.latestPrice = security.latestPrice! / ratio;
      security.priceUpdatedAt = DateTime.now();
      security.updatedAt = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.jiveSecuritys.put(security);
      });
    }
  }

  // ── Cost Basis ──

  /// 计算加权平均成本基础（考虑买入、卖出、拆股）
  CostBasis calculateCostBasis(List<JiveInvestmentTransaction> transactions) {
    double totalShares = 0;
    double totalCost = 0;

    for (final tx in transactions) {
      switch (tx.action) {
        case 'buy':
          totalCost += tx.quantity * tx.price + tx.fee;
          totalShares += tx.quantity;
        case 'sell':
          if (totalShares > 0) {
            final avgCost = totalCost / totalShares;
            totalShares -= tx.quantity;
            totalCost = totalShares > 0 ? totalShares * avgCost : 0;
          }
        case 'split':
          // quantity stores the ratio
          if (tx.quantity > 0) {
            totalShares *= tx.quantity;
            // total cost stays the same — cost per share drops
          }
        default:
          break; // dividend / fee don't affect cost basis
      }
    }

    final avgCost = totalShares > 0 ? totalCost / totalShares : 0.0;
    return CostBasis(
      totalCost: totalCost,
      avgCostPerShare: avgCost,
      totalShares: totalShares,
    );
  }

  /// 从数据库获取成本基础
  Future<CostBasis> getCostBasis(int securityId) async {
    final txs = await getInvestmentHistory(securityId);
    return calculateCostBasis(txs);
  }

  // ── Realized Gain ──

  /// 计算已实现盈亏（所有卖出交易的累计收益）
  double calculateRealizedGain(List<JiveInvestmentTransaction> transactions) {
    double totalShares = 0;
    double totalCost = 0;
    double realizedGain = 0;

    for (final tx in transactions) {
      switch (tx.action) {
        case 'buy':
          totalCost += tx.quantity * tx.price + tx.fee;
          totalShares += tx.quantity;
        case 'sell':
          if (totalShares > 0) {
            final avgCost = totalCost / totalShares;
            final sellProceeds = tx.quantity * tx.price - tx.fee;
            final sellCost = tx.quantity * avgCost;
            realizedGain += sellProceeds - sellCost;

            totalShares -= tx.quantity;
            totalCost = totalShares > 0 ? totalShares * avgCost : 0;
          }
        case 'split':
          if (tx.quantity > 0) {
            totalShares *= tx.quantity;
          }
        default:
          break;
      }
    }

    return realizedGain;
  }

  /// 从数据库获取已实现盈亏
  Future<double> getRealizedGain(int securityId) async {
    final txs = await getInvestmentHistory(securityId);
    return calculateRealizedGain(txs);
  }

  // ── History Queries ──

  /// 获取某证券的全部交易记录，按日期排序
  Future<List<JiveInvestmentTransaction>> getInvestmentHistory(
    int securityId,
  ) async {
    return _isar.jiveInvestmentTransactions
        .filter()
        .securityIdEqualTo(securityId)
        .sortByTransactionDate()
        .findAll();
  }

  /// 获取某证券的分红记录
  Future<List<JiveInvestmentTransaction>> getDividendHistory(
    int securityId,
  ) async {
    return _isar.jiveInvestmentTransactions
        .filter()
        .securityIdEqualTo(securityId)
        .actionEqualTo(InvestmentAction.dividend.name)
        .sortByTransactionDate()
        .findAll();
  }

  // ── Portfolio Allocation ──

  /// 获取投资组合配置: 按证券类型 → 占比
  Future<Map<String, double>> getPortfolioAllocation() async {
    final holdings = await _isar.jiveHoldings.where().findAll();
    if (holdings.isEmpty) return {};

    final securities = await _isar.jiveSecuritys.where().findAll();
    final secMap = {for (final s in securities) s.id: s};

    final typeValues = <String, double>{};
    double total = 0;

    for (final h in holdings) {
      final security = secMap[h.securityId];
      if (security == null) continue;
      final price = security.latestPrice ?? h.costBasis;
      final mv = h.quantity * price;
      final typeLabel = security.type;
      typeValues[typeLabel] = (typeValues[typeLabel] ?? 0) + mv;
      total += mv;
    }

    if (total <= 0) return {};

    return {
      for (final entry in typeValues.entries)
        entry.key: entry.value / total * 100,
    };
  }
}

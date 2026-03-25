import 'package:isar/isar.dart';

part 'investment_model.g.dart';

/// 证券/资产类型
class SecurityType {
  static const String stock = 'stock'; // 股票
  static const String fund = 'fund'; // 基金
  static const String bond = 'bond'; // 债券
  static const String crypto = 'crypto'; // 加密货币
  static const String other = 'other'; // 其他

  static String label(String type) {
    switch (type) {
      case stock:
        return '股票';
      case fund:
        return '基金';
      case bond:
        return '债券';
      case crypto:
        return '加密货币';
      default:
        return '其他';
    }
  }
}

/// 证券定义
@collection
class JiveSecurity {
  Id id = Isar.autoIncrement;

  /// 代码 (e.g. "AAPL", "600519.SH", "BTC-USD")
  @Index(unique: true)
  late String ticker;

  /// 名称 (e.g. "苹果", "贵州茅台", "比特币")
  late String name;

  /// 类型: stock / fund / bond / crypto / other
  @Index()
  late String type;

  /// 交易所/市场 (e.g. "NASDAQ", "SSE", "crypto")
  String? exchange;

  /// 币种
  String currency = 'CNY';

  /// 最新价格（手动更新或 API）
  double? latestPrice;

  /// 价格更新时间
  DateTime? priceUpdatedAt;

  late DateTime createdAt;
  late DateTime updatedAt;
}

/// 持仓记录
@collection
class JiveHolding {
  Id id = Isar.autoIncrement;

  /// 关联的证券 ID
  @Index()
  late int securityId;

  /// 关联的账户 ID（券商账户）
  int? accountId;

  /// 持有数量（股/份/个）
  late double quantity;

  /// 成本价（买入均价）
  late double costBasis;

  /// 总成本
  double get totalCost => quantity * costBasis;

  /// 备注
  String? note;

  late DateTime createdAt;
  late DateTime updatedAt;
}

/// 交易记录（买入/卖出）
@collection
class JiveInvestmentTransaction {
  Id id = Isar.autoIncrement;

  /// 关联的证券 ID
  @Index()
  late int securityId;

  /// 关联的持仓 ID
  int? holdingId;

  /// 关联的账户 ID
  int? accountId;

  /// 类型: buy / sell
  @Index()
  late String action; // 'buy' or 'sell'

  /// 数量
  late double quantity;

  /// 单价
  late double price;

  /// 手续费
  double fee = 0;

  /// 总金额 = quantity * price + fee (buy) 或 quantity * price - fee (sell)
  double get totalAmount {
    if (action == 'buy') return quantity * price + fee;
    return quantity * price - fee;
  }

  /// 交易日期
  late DateTime transactionDate;

  /// 备注
  String? note;

  late DateTime createdAt;
}

/// 价格历史
@collection
class JivePriceHistory {
  Id id = Isar.autoIncrement;

  /// 关联的证券 ID
  @Index()
  late int securityId;

  /// 日期
  @Index()
  late DateTime date;

  /// 收盘价
  late double closePrice;

  /// 开盘价（可选）
  double? openPrice;

  /// 最高价（可选）
  double? highPrice;

  /// 最低价（可选）
  double? lowPrice;
}

import 'package:isar/isar.dart';

part 'currency_model.g.dart';

/// 货币模型
@collection
class JiveCurrency {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String code; // ISO 4217 代码: CNY, USD, JPY, BTC

  late String name; // 英文名: Chinese Yuan
  late String nameZh; // 中文名: 人民币
  late String symbol; // 符号: ¥, $, ₿

  int decimalPlaces = 2; // 小数位数
  String? flag; // 国旗 emoji: 🇨🇳
  bool isCrypto = false; // 是否为加密货币
  bool isEnabled = true; // 是否启用
  int sortOrder = 0; // 排序顺序
}

/// 汇率模型
@collection
class JiveExchangeRate {
  Id id = Isar.autoIncrement;

  @Index()
  late String fromCurrency; // 源货币代码

  @Index()
  late String toCurrency; // 目标货币代码

  late double rate; // 汇率
  late DateTime effectiveDate; // 生效日期
  String source = 'mock'; // 数据源: mock, manual, api
  DateTime? updatedAt; // 更新时间
}

/// 用户货币偏好
@collection
class JiveCurrencyPreference {
  Id id = Isar.autoIncrement;

  late String baseCurrency; // 主币种代码
  List<String> enabledCurrencies = []; // 启用的货币列表
  bool autoUpdateRates = false; // 是否自动更新汇率
  DateTime? lastRateUpdate; // 最后更新时间
  bool rateChangeAlert = false; // 是否启用汇率变动提醒
  double rateChangeThreshold = 1.0; // 汇率变动提醒阈值（百分比）
}

/// 汇率历史记录
@collection
class JiveExchangeRateHistory {
  Id id = Isar.autoIncrement;

  @Index()
  late String fromCurrency; // 源货币代码

  @Index()
  late String toCurrency; // 目标货币代码

  late double rate; // 汇率

  @Index()
  late DateTime recordedAt; // 记录时间

  String source = 'api'; // 数据源: api, manual
}

/// 内置货币数据
class CurrencyDefaults {
  /// 法定货币列表
  static const List<Map<String, dynamic>> fiatCurrencies = [
    // 主要货币
    {'code': 'CNY', 'name': 'Chinese Yuan', 'nameZh': '人民币', 'symbol': '¥', 'decimalPlaces': 2, 'flag': '🇨🇳', 'sortOrder': 1},
    {'code': 'USD', 'name': 'US Dollar', 'nameZh': '美元', 'symbol': '\$', 'decimalPlaces': 2, 'flag': '🇺🇸', 'sortOrder': 2},
    {'code': 'EUR', 'name': 'Euro', 'nameZh': '欧元', 'symbol': '€', 'decimalPlaces': 2, 'flag': '🇪🇺', 'sortOrder': 3},
    {'code': 'GBP', 'name': 'British Pound', 'nameZh': '英镑', 'symbol': '£', 'decimalPlaces': 2, 'flag': '🇬🇧', 'sortOrder': 4},
    {'code': 'JPY', 'name': 'Japanese Yen', 'nameZh': '日元', 'symbol': '¥', 'decimalPlaces': 0, 'flag': '🇯🇵', 'sortOrder': 5},
    {'code': 'HKD', 'name': 'Hong Kong Dollar', 'nameZh': '港元', 'symbol': 'HK\$', 'decimalPlaces': 2, 'flag': '🇭🇰', 'sortOrder': 6},
    {'code': 'TWD', 'name': 'Taiwan Dollar', 'nameZh': '新台币', 'symbol': 'NT\$', 'decimalPlaces': 2, 'flag': '🇹🇼', 'sortOrder': 7},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'nameZh': '新加坡元', 'symbol': 'S\$', 'decimalPlaces': 2, 'flag': '🇸🇬', 'sortOrder': 8},
    {'code': 'KRW', 'name': 'South Korean Won', 'nameZh': '韩元', 'symbol': '₩', 'decimalPlaces': 0, 'flag': '🇰🇷', 'sortOrder': 9},
    {'code': 'AUD', 'name': 'Australian Dollar', 'nameZh': '澳元', 'symbol': 'A\$', 'decimalPlaces': 2, 'flag': '🇦🇺', 'sortOrder': 10},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'nameZh': '加元', 'symbol': 'C\$', 'decimalPlaces': 2, 'flag': '🇨🇦', 'sortOrder': 11},
    {'code': 'CHF', 'name': 'Swiss Franc', 'nameZh': '瑞士法郎', 'symbol': 'CHF', 'decimalPlaces': 2, 'flag': '🇨🇭', 'sortOrder': 12},
    {'code': 'NZD', 'name': 'New Zealand Dollar', 'nameZh': '新西兰元', 'symbol': 'NZ\$', 'decimalPlaces': 2, 'flag': '🇳🇿', 'sortOrder': 13},
    {'code': 'THB', 'name': 'Thai Baht', 'nameZh': '泰铢', 'symbol': '฿', 'decimalPlaces': 2, 'flag': '🇹🇭', 'sortOrder': 14},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'nameZh': '马来西亚林吉特', 'symbol': 'RM', 'decimalPlaces': 2, 'flag': '🇲🇾', 'sortOrder': 15},
    {'code': 'INR', 'name': 'Indian Rupee', 'nameZh': '印度卢比', 'symbol': '₹', 'decimalPlaces': 2, 'flag': '🇮🇳', 'sortOrder': 16},
    {'code': 'PHP', 'name': 'Philippine Peso', 'nameZh': '菲律宾比索', 'symbol': '₱', 'decimalPlaces': 2, 'flag': '🇵🇭', 'sortOrder': 17},
    {'code': 'VND', 'name': 'Vietnamese Dong', 'nameZh': '越南盾', 'symbol': '₫', 'decimalPlaces': 0, 'flag': '🇻🇳', 'sortOrder': 18},
    {'code': 'IDR', 'name': 'Indonesian Rupiah', 'nameZh': '印尼盾', 'symbol': 'Rp', 'decimalPlaces': 0, 'flag': '🇮🇩', 'sortOrder': 19},
    {'code': 'RUB', 'name': 'Russian Ruble', 'nameZh': '俄罗斯卢布', 'symbol': '₽', 'decimalPlaces': 2, 'flag': '🇷🇺', 'sortOrder': 20},
    {'code': 'BRL', 'name': 'Brazilian Real', 'nameZh': '巴西雷亚尔', 'symbol': 'R\$', 'decimalPlaces': 2, 'flag': '🇧🇷', 'sortOrder': 21},
    {'code': 'MXN', 'name': 'Mexican Peso', 'nameZh': '墨西哥比索', 'symbol': 'MX\$', 'decimalPlaces': 2, 'flag': '🇲🇽', 'sortOrder': 22},
    {'code': 'AED', 'name': 'UAE Dirham', 'nameZh': '阿联酋迪拉姆', 'symbol': 'د.إ', 'decimalPlaces': 2, 'flag': '🇦🇪', 'sortOrder': 23},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'nameZh': '沙特里亚尔', 'symbol': '﷼', 'decimalPlaces': 2, 'flag': '🇸🇦', 'sortOrder': 24},
    {'code': 'TRY', 'name': 'Turkish Lira', 'nameZh': '土耳其里拉', 'symbol': '₺', 'decimalPlaces': 2, 'flag': '🇹🇷', 'sortOrder': 25},
    {'code': 'ZAR', 'name': 'South African Rand', 'nameZh': '南非兰特', 'symbol': 'R', 'decimalPlaces': 2, 'flag': '🇿🇦', 'sortOrder': 26},
    {'code': 'SEK', 'name': 'Swedish Krona', 'nameZh': '瑞典克朗', 'symbol': 'kr', 'decimalPlaces': 2, 'flag': '🇸🇪', 'sortOrder': 27},
    {'code': 'NOK', 'name': 'Norwegian Krone', 'nameZh': '挪威克朗', 'symbol': 'kr', 'decimalPlaces': 2, 'flag': '🇳🇴', 'sortOrder': 28},
    {'code': 'DKK', 'name': 'Danish Krone', 'nameZh': '丹麦克朗', 'symbol': 'kr', 'decimalPlaces': 2, 'flag': '🇩🇰', 'sortOrder': 29},
    {'code': 'PLN', 'name': 'Polish Zloty', 'nameZh': '波兰兹罗提', 'symbol': 'zł', 'decimalPlaces': 2, 'flag': '🇵🇱', 'sortOrder': 30},
  ];

  /// 加密货币列表
  static const List<Map<String, dynamic>> cryptoCurrencies = [
    {'code': 'BTC', 'name': 'Bitcoin', 'nameZh': '比特币', 'symbol': '₿', 'decimalPlaces': 8, 'flag': '₿', 'isCrypto': true, 'sortOrder': 101},
    {'code': 'ETH', 'name': 'Ethereum', 'nameZh': '以太坊', 'symbol': 'Ξ', 'decimalPlaces': 8, 'flag': 'Ξ', 'isCrypto': true, 'sortOrder': 102},
    {'code': 'USDT', 'name': 'Tether', 'nameZh': '泰达币', 'symbol': '₮', 'decimalPlaces': 6, 'flag': '₮', 'isCrypto': true, 'sortOrder': 103},
    {'code': 'USDC', 'name': 'USD Coin', 'nameZh': 'USD币', 'symbol': 'USDC', 'decimalPlaces': 6, 'flag': '💵', 'isCrypto': true, 'sortOrder': 104},
    {'code': 'BNB', 'name': 'Binance Coin', 'nameZh': '币安币', 'symbol': 'BNB', 'decimalPlaces': 8, 'flag': '🔸', 'isCrypto': true, 'sortOrder': 105},
    {'code': 'SOL', 'name': 'Solana', 'nameZh': 'Solana', 'symbol': 'SOL', 'decimalPlaces': 6, 'flag': '◎', 'isCrypto': true, 'sortOrder': 106},
    {'code': 'XRP', 'name': 'XRP', 'nameZh': '瑞波币', 'symbol': 'XRP', 'decimalPlaces': 6, 'flag': '✕', 'isCrypto': true, 'sortOrder': 107},
    {'code': 'ADA', 'name': 'Cardano', 'nameZh': '卡尔达诺', 'symbol': '₳', 'decimalPlaces': 6, 'flag': '₳', 'isCrypto': true, 'sortOrder': 108},
    {'code': 'DOGE', 'name': 'Dogecoin', 'nameZh': '狗狗币', 'symbol': 'DOGE', 'decimalPlaces': 8, 'flag': '🐕', 'isCrypto': true, 'sortOrder': 109},
    {'code': 'LTC', 'name': 'Litecoin', 'nameZh': '莱特币', 'symbol': 'Ł', 'decimalPlaces': 8, 'flag': 'Ł', 'isCrypto': true, 'sortOrder': 110},
  ];

  /// 预置汇率（以 USD 为基准）
  static const Map<String, double> ratesAgainstUSD = {
    'USD': 1.0,
    'CNY': 7.25,
    'EUR': 0.92,
    'GBP': 0.79,
    'JPY': 154.5,
    'HKD': 7.82,
    'TWD': 32.0,
    'SGD': 1.34,
    'KRW': 1380.0,
    'AUD': 1.55,
    'CAD': 1.36,
    'CHF': 0.88,
    'NZD': 1.68,
    'THB': 35.5,
    'MYR': 4.72,
    'INR': 83.5,
    'PHP': 58.5,
    'VND': 25400.0,
    'IDR': 16200.0,
    'RUB': 92.0,
    'BRL': 4.95,
    'MXN': 17.2,
    'AED': 3.67,
    'SAR': 3.75,
    'TRY': 32.5,
    'ZAR': 18.5,
    'SEK': 10.8,
    'NOK': 10.9,
    'DKK': 6.9,
    'PLN': 4.0,
    // 加密货币（以 USD 计价）
    'BTC': 0.000015,    // 1 USD ≈ 0.000015 BTC (BTC ≈ 67,000 USD)
    'ETH': 0.0003,      // 1 USD ≈ 0.0003 ETH (ETH ≈ 3,300 USD)
    'USDT': 1.0,
    'USDC': 1.0,
    'BNB': 0.0016,      // BNB ≈ 620 USD
    'SOL': 0.005,       // SOL ≈ 200 USD
    'XRP': 1.85,        // XRP ≈ 0.54 USD
    'ADA': 2.5,         // ADA ≈ 0.40 USD
    'DOGE': 8.0,        // DOGE ≈ 0.125 USD
    'LTC': 0.012,       // LTC ≈ 83 USD
  };

  /// 获取所有货币数据
  static List<Map<String, dynamic>> getAllCurrencies() {
    return [...fiatCurrencies, ...cryptoCurrencies];
  }

  /// 根据代码获取货币符号
  static String getSymbol(String code) {
    for (final c in getAllCurrencies()) {
      if (c['code'] == code) return c['symbol'] as String;
    }
    return code;
  }

  /// 根据代码获取小数位数
  static int getDecimalPlaces(String code) {
    for (final c in getAllCurrencies()) {
      if (c['code'] == code) return c['decimalPlaces'] as int;
    }
    return 2;
  }

  /// 计算两种货币之间的汇率
  static double? getRate(String from, String to) {
    if (from == to) return 1.0;

    final fromRate = ratesAgainstUSD[from];
    final toRate = ratesAgainstUSD[to];

    if (fromRate == null || toRate == null) return null;

    // 交叉汇率计算
    if (from == 'USD') {
      return toRate;
    } else if (to == 'USD') {
      return 1.0 / fromRate;
    } else {
      return toRate / fromRate;
    }
  }

  /// 限制加密货币的国家/地区代码
  static const List<String> cryptoRestrictedCountries = [
    'CN', 'IN', 'BD', 'EG', 'ID', 'IQ', 'MA', 'NP', 'TN', 'VN',
    'AF', 'DZ', 'AO', 'BO', 'KH', 'CM', 'DO', 'EC', 'GH', 'GT',
    'JO', 'KZ', 'KW', 'LB', 'LY', 'ML', 'NE', 'NG', 'PK', 'QA',
    'SA', 'SY', 'TZ', 'TD', 'UZ', 'ZW',
  ];
}

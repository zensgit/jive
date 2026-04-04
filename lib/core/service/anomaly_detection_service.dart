import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/transaction_model.dart';
import 'budget_service.dart';
import 'currency_service.dart';
import 'database_service.dart';

/// 消费异常类型
enum AnomalyType {
  largeExpense,
  budgetExceeded,
  duplicateCharge,
  unusualTime,
  monthlyBreach,
}

/// 异常严重程度
enum AnomalySeverity {
  info,
  warning,
  critical,
}

/// 消费异常
class SpendingAnomaly {
  final AnomalyType type;
  final String title;
  final String description;
  final AnomalySeverity severity;

  const SpendingAnomaly({
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
  });
}

/// 消费异常检测服务
///
/// 分析每笔交易，检测大额消费、预算超支、重复扣费、
/// 异常时间消费和月度限额突破等异常情况。
class AnomalyDetectionService {
  final Isar _isar;
  final BudgetService _budgetService;

  // SharedPreferences keys
  static const _prefEnabled = 'anomaly_detection_enabled';
  static const _prefLargeExpense = 'anomaly_large_expense';
  static const _prefBudgetExceeded = 'anomaly_budget_exceeded';
  static const _prefDuplicateCharge = 'anomaly_duplicate_charge';
  static const _prefUnusualTime = 'anomaly_unusual_time';
  static const _prefMonthlyBreach = 'anomaly_monthly_breach';
  static const _prefThresholdMultiplier = 'anomaly_threshold_multiplier';
  static const _prefQuietStart = 'anomaly_quiet_start';
  static const _prefQuietEnd = 'anomaly_quiet_end';

  AnomalyDetectionService(this._isar, this._budgetService);

  /// 创建使用默认数据库实例的服务
  static Future<AnomalyDetectionService> create() async {
    final isar = await DatabaseService.getInstance();
    final currencyService = CurrencyService(isar);
    final budgetService = BudgetService(isar, currencyService);
    return AnomalyDetectionService(isar, budgetService);
  }

  /// 检测是否已启用异常检测
  static Future<bool> isEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefEnabled) ?? false;
  }

  /// 设置启用状态
  static Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefEnabled, enabled);
  }

  /// 获取某类异常的启用状态
  static Future<bool> isTypeEnabled(AnomalyType type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _keyForType(type);
    return prefs.getBool(key) ?? true; // 默认全部启用
  }

  /// 设置某类异常的启用状态
  static Future<void> setTypeEnabled(AnomalyType type, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyForType(type), enabled);
  }

  /// 获取大额消费倍数阈值（默认 3.0）
  static Future<double> getThresholdMultiplier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_prefThresholdMultiplier) ?? 3.0;
  }

  /// 设置大额消费倍数阈值
  static Future<void> setThresholdMultiplier(double multiplier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefThresholdMultiplier, multiplier);
  }

  /// 获取免打扰时间段 (startHour, endHour)
  static Future<(int, int)> getQuietHours() async {
    final prefs = await SharedPreferences.getInstance();
    final start = prefs.getInt(_prefQuietStart) ?? 23;
    final end = prefs.getInt(_prefQuietEnd) ?? 7;
    return (start, end);
  }

  /// 设置免打扰时间段
  static Future<void> setQuietHours(int startHour, int endHour) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefQuietStart, startHour);
    await prefs.setInt(_prefQuietEnd, endHour);
  }

  /// 当前是否处于免打扰时段
  static Future<bool> isInQuietHours() async {
    final (start, end) = await getQuietHours();
    final hour = DateTime.now().hour;
    if (start <= end) {
      return hour >= start && hour < end;
    }
    // 跨午夜: e.g. 23:00 ~ 07:00
    return hour >= start || hour < end;
  }

  /// 检测交易中的消费异常
  ///
  /// 返回检测到的所有异常列表（可能为空）。
  Future<List<SpendingAnomaly>> checkTransaction(JiveTransaction tx) async {
    // 仅检测支出
    if (tx.type != 'expense') return [];

    final enabled = await isEnabled();
    if (!enabled) return [];

    final anomalies = <SpendingAnomaly>[];

    // 并行加载各类型启用状态
    final enabledFlags = await Future.wait([
      isTypeEnabled(AnomalyType.largeExpense),
      isTypeEnabled(AnomalyType.budgetExceeded),
      isTypeEnabled(AnomalyType.duplicateCharge),
      isTypeEnabled(AnomalyType.unusualTime),
      isTypeEnabled(AnomalyType.monthlyBreach),
    ]);

    if (enabledFlags[0]) {
      final result = await _checkLargeExpense(tx);
      if (result != null) anomalies.add(result);
    }

    if (enabledFlags[1]) {
      final results = await _checkBudgetExceeded(tx);
      anomalies.addAll(results);
    }

    if (enabledFlags[2]) {
      final result = await _checkDuplicateCharge(tx);
      if (result != null) anomalies.add(result);
    }

    if (enabledFlags[3]) {
      final result = _checkUnusualTime(tx);
      if (result != null) anomalies.add(result);
    }

    if (enabledFlags[4]) {
      final result = await _checkMonthlyBreach(tx);
      if (result != null) anomalies.add(result);
    }

    return anomalies;
  }

  /// 大额消费检测：金额 > 阈值倍数 * 近 30 天日均
  Future<SpendingAnomaly?> _checkLargeExpense(JiveTransaction tx) async {
    final multiplier = await getThresholdMultiplier();
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    final recentExpenses = await _isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .timestampGreaterThan(thirtyDaysAgo)
        .findAll();

    if (recentExpenses.isEmpty) return null;

    final totalAmount =
        recentExpenses.fold<double>(0, (sum, t) => sum + t.amount);
    final dailyAverage = totalAmount / 30;

    if (dailyAverage <= 0) return null;

    if (tx.amount > dailyAverage * multiplier) {
      return SpendingAnomaly(
        type: AnomalyType.largeExpense,
        title: '大额消费提醒',
        description:
            '本笔消费 ¥${tx.amount.toStringAsFixed(2)} 超过近30天日均'
            '（¥${dailyAverage.toStringAsFixed(2)}）的'
            '${multiplier.toStringAsFixed(1)}倍',
        severity: AnomalySeverity.warning,
      );
    }
    return null;
  }

  /// 预算超支检测：该笔交易导致任意活跃预算超支
  Future<List<SpendingAnomaly>> _checkBudgetExceeded(
    JiveTransaction tx,
  ) async {
    final results = <SpendingAnomaly>[];
    final budgets = await _budgetService.getActiveBudgets();

    for (final budget in budgets) {
      // 检查分类匹配
      if (budget.categoryKey != null &&
          budget.categoryKey != tx.categoryKey) {
        continue;
      }

      final summary = await _budgetService.calculateBudgetUsage(budget);
      final newUsed = summary.usedAmount + tx.amount;

      if (newUsed > summary.effectiveAmount &&
          summary.usedAmount <= summary.effectiveAmount) {
        results.add(SpendingAnomaly(
          type: AnomalyType.budgetExceeded,
          title: '预算超支警告',
          description: '「${budget.name}」预算将被超出，'
              '已用 ¥${newUsed.toStringAsFixed(2)}'
              ' / ¥${summary.effectiveAmount.toStringAsFixed(2)}',
          severity: AnomalySeverity.critical,
        ));
      }
    }
    return results;
  }

  /// 重复扣费检测：同金额 + 同分类，1小时内
  Future<SpendingAnomaly?> _checkDuplicateCharge(JiveTransaction tx) async {
    final oneHourAgo = tx.timestamp.subtract(const Duration(hours: 1));

    final duplicates = await _isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .amountEqualTo(tx.amount)
        .timestampGreaterThan(oneHourAgo)
        .timestampLessThan(tx.timestamp)
        .findAll();

    final hasDuplicate = duplicates.any(
      (t) => t.categoryKey == tx.categoryKey && t.id != tx.id,
    );

    if (hasDuplicate) {
      return SpendingAnomaly(
        type: AnomalyType.duplicateCharge,
        title: '疑似重复扣费',
        description: '1小时内发现相同金额（¥${tx.amount.toStringAsFixed(2)}）'
            '和相同分类的交易，请确认是否重复',
        severity: AnomalySeverity.warning,
      );
    }
    return null;
  }

  /// 异常时间检测：工作日 00:00-05:00
  SpendingAnomaly? _checkUnusualTime(JiveTransaction tx) {
    final weekday = tx.timestamp.weekday; // 1=Mon, 7=Sun
    final hour = tx.timestamp.hour;

    // 仅工作日（周一~周五）
    if (weekday >= 1 && weekday <= 5 && hour >= 0 && hour < 5) {
      return SpendingAnomaly(
        type: AnomalyType.unusualTime,
        title: '异常时间消费',
        description: '在凌晨 ${hour.toString().padLeft(2, '0')}:'
            '${tx.timestamp.minute.toString().padLeft(2, '0')} 发生了消费，'
            '请确认是否为本人操作',
        severity: AnomalySeverity.info,
      );
    }
    return null;
  }

  /// 月度限额突破检测：当月总支出 > 近 3 个月月均的 120%
  Future<SpendingAnomaly?> _checkMonthlyBreach(JiveTransaction tx) async {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month);
    final threeMonthsAgo = DateTime(now.year, now.month - 3);

    // 当月已有支出
    final currentMonthExpenses = await _isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .timestampGreaterThan(monthStart)
        .findAll();

    final currentTotal =
        currentMonthExpenses.fold<double>(0, (s, t) => s + t.amount) +
            tx.amount;

    // 近 3 个月支出
    final pastExpenses = await _isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .timestampGreaterThan(threeMonthsAgo)
        .timestampLessThan(monthStart)
        .findAll();

    if (pastExpenses.isEmpty) return null;

    final pastTotal = pastExpenses.fold<double>(0, (s, t) => s + t.amount);
    final monthlyAverage = pastTotal / 3;

    if (monthlyAverage <= 0) return null;

    final threshold = monthlyAverage * 1.2;

    if (currentTotal > threshold) {
      return SpendingAnomaly(
        type: AnomalyType.monthlyBreach,
        title: '月度消费超限',
        description: '本月总消费 ¥${currentTotal.toStringAsFixed(2)} '
            '已超过近3个月月均（¥${monthlyAverage.toStringAsFixed(2)}）的120%',
        severity: AnomalySeverity.critical,
      );
    }
    return null;
  }

  static String _keyForType(AnomalyType type) {
    switch (type) {
      case AnomalyType.largeExpense:
        return _prefLargeExpense;
      case AnomalyType.budgetExceeded:
        return _prefBudgetExceeded;
      case AnomalyType.duplicateCharge:
        return _prefDuplicateCharge;
      case AnomalyType.unusualTime:
        return _prefUnusualTime;
      case AnomalyType.monthlyBreach:
        return _prefMonthlyBreach;
    }
  }
}

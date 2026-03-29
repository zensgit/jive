import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/installment_model.dart';
import '../database/recurring_rule_model.dart';
import 'budget_service.dart';
import 'currency_service.dart';
import 'notification_service.dart';

/// 提醒项
class ReminderItem {
  final String id;
  final String title;
  final String body;
  final ReminderType type;
  final DateTime dueDate;
  final Map<String, dynamic>? data;

  const ReminderItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.dueDate,
    this.data,
  });
}

enum ReminderType {
  recurringDue, // 周期交易到期
  budgetWarning, // 预算超限
  installmentDue, // 分期还款到期
}

/// 提醒服务 — 检查各类到期事项并生成应用内通知
class ReminderService {
  final Isar _isar;
  static const _prefKeyLastCheck = 'reminder_last_check_date';

  ReminderService(this._isar);

  /// 检查所有提醒（每天最多执行一次）
  Future<List<ReminderItem>> checkReminders({bool force = false}) async {
    if (!force) {
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_prefKeyLastCheck);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      if (lastCheck == today) return [];
      await prefs.setString(_prefKeyLastCheck, today);
    }

    final reminders = <ReminderItem>[];
    reminders.addAll(await _checkRecurringRules());
    reminders.addAll(await _checkBudgetAlerts());
    reminders.addAll(await _checkInstallments());

    // 注入到应用内通知队列
    final notificationService = InAppNotificationService();
    for (final r in reminders) {
      notificationService.addNotification(InAppNotification(
        id: r.id,
        title: r.title,
        body: r.body,
        type: _mapType(r.type),
      ));
    }

    return reminders;
  }

  /// 检查即将到期的周期交易
  Future<List<ReminderItem>> _checkRecurringRules() async {
    final rules = await _isar.jiveRecurringRules
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final reminders = <ReminderItem>[];

    for (final rule in rules) {
      final next = rule.nextRunAt;

      // 今天或明天到期
      if (_isSameDay(next, now) || _isSameDay(next, tomorrow)) {
        final dueLabel = _isSameDay(next, now) ? '今天' : '明天';
        reminders.add(ReminderItem(
          id: 'recurring_${rule.id}_${now.toIso8601String().substring(0, 10)}',
          title: '周期交易提醒',
          body: '「${rule.name}」$dueLabel到期',
          type: ReminderType.recurringDue,
          dueDate: next,
          data: {'ruleId': rule.id},
        ));
      }
    }

    return reminders;
  }

  /// 检查预算超限
  Future<List<ReminderItem>> _checkBudgetAlerts() async {
    final reminders = <ReminderItem>[];
    try {
      final currencyService = CurrencyService(_isar);
      final budgetService = BudgetService(_isar, currencyService);
      final alerts = await budgetService.checkBudgetAlerts();
      for (final summary in alerts) {
        final pct = summary.usedPercent.toStringAsFixed(0);
        final isExceeded = summary.usedPercent >= 100;
        final statusLabel = isExceeded ? '已超支' : '即将超支';
        reminders.add(ReminderItem(
          id: 'budget_${summary.budget.id}_${DateTime.now().toIso8601String().substring(0, 10)}',
          title: '预算$statusLabel',
          body: '「${summary.budget.name}」已使用 $pct%',
          type: ReminderType.budgetWarning,
          dueDate: summary.budget.endDate,
          data: {'budgetId': summary.budget.id},
        ));
      }
    } catch (_) {
      // Budget calculation may timeout
    }
    return reminders;
  }

  /// 检查即将到期的分期还款
  Future<List<ReminderItem>> _checkInstallments() async {
    final installments = await _isar.jiveInstallments
        .filter()
        .statusEqualTo(InstallmentStatus.active.value)
        .findAll();

    final now = DateTime.now();
    final reminders = <ReminderItem>[];

    for (final inst in installments) {
      // 计算下一期还款日
      final nextDue = _nextInstallmentDue(inst);
      if (nextDue == null) continue;

      final daysUntil = nextDue.difference(DateTime(now.year, now.month, now.day)).inDays;

      // 提前 3 天提醒
      if (daysUntil >= 0 && daysUntil <= 3) {
        final dueLabel = daysUntil == 0
            ? '今天'
            : daysUntil == 1
                ? '明天'
                : '$daysUntil天后';
        final perPeriod = inst.totalPeriods > 0
            ? (inst.principalAmount + inst.totalFee) / inst.totalPeriods
            : inst.principalAmount;
        reminders.add(ReminderItem(
          id: 'installment_${inst.id}_${now.toIso8601String().substring(0, 10)}',
          title: '分期还款提醒',
          body: '「${inst.name}」$dueLabel到期，金额 ¥${perPeriod.toStringAsFixed(2)}',
          type: ReminderType.installmentDue,
          dueDate: nextDue,
          data: {'installmentId': inst.id},
        ));
      }
    }

    return reminders;
  }

  /// 获取下一期还款日
  DateTime? _nextInstallmentDue(JiveInstallment inst) {
    if (inst.executedPeriods >= inst.totalPeriods) return null;
    return inst.nextDueAt;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  NotificationType _mapType(ReminderType type) {
    switch (type) {
      case ReminderType.budgetWarning:
        return NotificationType.alert;
      case ReminderType.recurringDue:
      case ReminderType.installmentDue:
        return NotificationType.info;
    }
  }
}

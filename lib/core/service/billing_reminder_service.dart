import 'package:isar/isar.dart';

import '../database/billing_cycle_model.dart';

/// 账单提醒数据
class BillingReminder {
  final String accountName;

  /// 'billing' 表示账单日, 'due' 表示还款日
  final String type;
  final int daysUntil;
  final double? amount;

  const BillingReminder({
    required this.accountName,
    required this.type,
    required this.daysUntil,
    this.amount,
  });

  /// 是否紧急（今天或明天）
  bool get isUrgent => daysUntil <= 1;

  /// 是否临近（2-5 天内）
  bool get isNear => daysUntil >= 2 && daysUntil <= 5;
}

/// 账单日/还款日提醒服务
class BillingReminderService {
  final Isar _isar;

  BillingReminderService(this._isar);

  /// 检查所有账单周期，生成需要提醒的列表
  Future<List<BillingReminder>> checkBillingReminders({
    DateTime? referenceDate,
  }) async {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final cycles = await _isar
        .collection<JiveBillingCycle>()
        .filter()
        .isEnabledEqualTo(true)
        .findAll();

    final reminders = <BillingReminder>[];

    for (final cycle in cycles) {
      final billingReminder = _checkDay(
        today: today,
        targetDay: cycle.billingDay,
        reminderDaysBefore: cycle.reminderDaysBefore,
        accountName: cycle.accountName,
        type: 'billing',
      );
      if (billingReminder != null) reminders.add(billingReminder);

      final dueReminder = _checkDay(
        today: today,
        targetDay: cycle.dueDay,
        reminderDaysBefore: cycle.reminderDaysBefore,
        accountName: cycle.accountName,
        type: 'due',
      );
      if (dueReminder != null) reminders.add(dueReminder);
    }

    // 按紧急程度排序: daysUntil 升序
    reminders.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return reminders;
  }

  /// 获取未来 N 天内的所有提醒
  Future<List<BillingReminder>> getUpcomingReminders(
    int daysAhead, {
    DateTime? referenceDate,
  }) async {
    final now = referenceDate ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final cycles = await _isar
        .collection<JiveBillingCycle>()
        .filter()
        .isEnabledEqualTo(true)
        .findAll();

    final reminders = <BillingReminder>[];

    for (final cycle in cycles) {
      final billingDaysUntil =
          _daysUntilTargetDay(today, cycle.billingDay);
      if (billingDaysUntil <= daysAhead) {
        reminders.add(BillingReminder(
          accountName: cycle.accountName,
          type: 'billing',
          daysUntil: billingDaysUntil,
        ));
      }

      final dueDaysUntil = _daysUntilTargetDay(today, cycle.dueDay);
      if (dueDaysUntil <= daysAhead) {
        reminders.add(BillingReminder(
          accountName: cycle.accountName,
          type: 'due',
          daysUntil: dueDaysUntil,
        ));
      }
    }

    reminders.sort((a, b) => a.daysUntil.compareTo(b.daysUntil));
    return reminders;
  }

  BillingReminder? _checkDay({
    required DateTime today,
    required int targetDay,
    required int reminderDaysBefore,
    required String accountName,
    required String type,
  }) {
    final daysUntil = _daysUntilTargetDay(today, targetDay);

    // 当距离目标日 <= reminderDaysBefore 时生成提醒
    if (daysUntil <= reminderDaysBefore) {
      return BillingReminder(
        accountName: accountName,
        type: type,
        daysUntil: daysUntil,
      );
    }
    return null;
  }

  /// 计算从 today 到本月（或下月）targetDay 的天数
  int _daysUntilTargetDay(DateTime today, int targetDay) {
    // 本月的目标日
    final daysInCurrentMonth =
        DateTime(today.year, today.month + 1, 0).day;
    final clampedDay =
        targetDay > daysInCurrentMonth ? daysInCurrentMonth : targetDay;
    final targetDate = DateTime(today.year, today.month, clampedDay);

    if (!targetDate.isBefore(today)) {
      return targetDate.difference(today).inDays;
    }

    // 目标日已过，看下个月
    final nextMonth = DateTime(today.year, today.month + 1, 1);
    final daysInNextMonth =
        DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
    final nextClampedDay =
        targetDay > daysInNextMonth ? daysInNextMonth : targetDay;
    final nextTargetDate =
        DateTime(nextMonth.year, nextMonth.month, nextClampedDay);
    return nextTargetDate.difference(today).inDays;
  }
}

import 'package:isar/isar.dart';

import '../database/budget_model.dart';
import '../database/category_model.dart';
import '../database/transaction_model.dart';
import 'account_service.dart';
import 'currency_service.dart';
import 'database_service.dart';

// ── Data classes ──

enum InsightType { tip, warning, achievement }

class SpendingInsight {
  final String title;
  final String description;
  final InsightType type;
  final String iconName;

  const SpendingInsight({
    required this.title,
    required this.description,
    required this.type,
    required this.iconName,
  });
}

class SpendingAnalysis {
  final List<SpendingInsight> insights;
  final DateTime generatedAt;

  const SpendingAnalysis({
    required this.insights,
    required this.generatedAt,
  });
}

// ── Service ──

class SpendingAnalysisService {
  final Isar isar;
  final CurrencyService currencyService;

  SpendingAnalysisService(this.isar, this.currencyService);

  /// Create from DatabaseService singleton.
  static Future<SpendingAnalysisService> create() async {
    final isar = await DatabaseService.getInstance();
    final cs = CurrencyService(isar);
    return SpendingAnalysisService(isar, cs);
  }

  /// Analyze spending over the given number of months and return insights.
  Future<SpendingAnalysis> analyzeSpending(int months) async {
    final currency = await currencyService.getBaseCurrency();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - months + 1, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    // Fetch all expense transactions in the period
    final txs = await isar.jiveTransactions
        .filter()
        .typeEqualTo('expense')
        .timestampBetween(start, end, includeUpper: false)
        .findAll();

    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts();
    final accountById = {for (final a in accounts) a.id: a};

    // Category map for names
    final categories = await isar.collection<JiveCategory>().where().findAll();
    final categoryMap = {for (final c in categories) c.key: c};

    // Build per-month per-category amounts
    final Map<String, Map<String, double>> monthCategoryAmounts = {};
    final Map<String, double> monthTotals = {};
    // weekday spending (1=Mon..7=Sun)
    double weekdayTotal = 0;
    int weekdayCount = 0;
    double weekendTotal = 0;
    int weekendCount = 0;

    for (final tx in txs) {
      if (tx.amount <= 0) continue;

      final account = tx.accountId != null ? accountById[tx.accountId] : null;
      final txCurrency = account?.currency ?? 'CNY';
      double amount = tx.amount;
      if (txCurrency != currency) {
        amount =
            await currencyService.convert(amount, txCurrency, currency) ??
                amount;
      }

      final monthKey =
          '${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}';
      final catKey = tx.categoryKey ?? tx.category ?? '其他';

      monthCategoryAmounts.putIfAbsent(monthKey, () => {});
      monthCategoryAmounts[monthKey]![catKey] =
          (monthCategoryAmounts[monthKey]![catKey] ?? 0) + amount;
      monthTotals[monthKey] = (monthTotals[monthKey] ?? 0) + amount;

      // Weekday vs weekend
      final wd = tx.timestamp.weekday;
      if (wd >= 6) {
        weekendTotal += amount;
        weekendCount++;
      } else {
        weekdayTotal += amount;
        weekdayCount++;
      }
    }

    final insights = <SpendingInsight>[];

    // Sort month keys chronologically
    final sortedMonths = monthTotals.keys.toList()..sort();

    if (sortedMonths.isEmpty) {
      return SpendingAnalysis(
        insights: [
          const SpendingInsight(
            title: '暂无数据',
            description: '当前时段没有支出记录，开始记账后即可获得财务洞察。',
            type: InsightType.tip,
            iconName: 'info_outline',
          ),
        ],
        generatedAt: now,
      );
    }

    // --- 1. Spending decreased vs last month (achievement) ---
    if (sortedMonths.length >= 2) {
      final currentTotal = monthTotals[sortedMonths.last]!;
      final previousTotal = monthTotals[sortedMonths[sortedMonths.length - 2]]!;
      if (previousTotal > 0 && currentTotal < previousTotal) {
        final pct = ((previousTotal - currentTotal) / previousTotal * 100)
            .toStringAsFixed(1);
        insights.add(SpendingInsight(
          title: '支出下降',
          description: '本月支出比上月减少了 $pct%，继续保持！',
          type: InsightType.achievement,
          iconName: 'trending_down',
        ));
      }
    }

    // --- 2. Unusual spending spikes (category > 2x monthly average) ---
    if (sortedMonths.length >= 2) {
      final currentMonth = sortedMonths.last;
      final currentCats = monthCategoryAmounts[currentMonth] ?? {};

      // Compute average per category from previous months
      final previousMonths =
          sortedMonths.sublist(0, sortedMonths.length - 1);
      final Map<String, double> catAvg = {};
      for (final m in previousMonths) {
        final cats = monthCategoryAmounts[m] ?? {};
        for (final entry in cats.entries) {
          catAvg[entry.key] = (catAvg[entry.key] ?? 0) + entry.value;
        }
      }
      for (final key in catAvg.keys.toList()) {
        catAvg[key] = catAvg[key]! / previousMonths.length;
      }

      for (final entry in currentCats.entries) {
        final avg = catAvg[entry.key];
        if (avg != null && avg > 0 && entry.value > avg * 2) {
          final catName = categoryMap[entry.key]?.name ?? entry.key;
          final ratio = (entry.value / avg).toStringAsFixed(1);
          insights.add(SpendingInsight(
            title: '$catName 支出异常',
            description: '本月 $catName 支出是月均的 ${ratio}x，请留意是否合理。',
            type: InsightType.warning,
            iconName: 'warning_amber',
          ));
        }
      }
    }

    // --- 3. Top growing categories (month-over-month increase) ---
    if (sortedMonths.length >= 2) {
      final cur = monthCategoryAmounts[sortedMonths.last] ?? {};
      final prev =
          monthCategoryAmounts[sortedMonths[sortedMonths.length - 2]] ?? {};

      final growthEntries = <MapEntry<String, double>>[];
      for (final entry in cur.entries) {
        final prevAmt = prev[entry.key] ?? 0;
        if (prevAmt > 0) {
          final growth = (entry.value - prevAmt) / prevAmt * 100;
          if (growth > 30) {
            growthEntries.add(MapEntry(entry.key, growth));
          }
        }
      }
      growthEntries.sort((a, b) => b.value.compareTo(a.value));

      for (final g in growthEntries.take(2)) {
        final catName = categoryMap[g.key]?.name ?? g.key;
        final pct = g.value.toStringAsFixed(0);
        insights.add(SpendingInsight(
          title: '$catName 增长明显',
          description: '$catName 本月环比增长 $pct%，建议关注支出趋势。',
          type: InsightType.tip,
          iconName: 'trending_up',
        ));
      }
    }

    // --- 4. Category concentration risk (one category > 40%) ---
    if (sortedMonths.isNotEmpty) {
      final currentMonth = sortedMonths.last;
      final currentCats = monthCategoryAmounts[currentMonth] ?? {};
      final currentTotal = monthTotals[currentMonth] ?? 0;

      if (currentTotal > 0) {
        for (final entry in currentCats.entries) {
          final pct = entry.value / currentTotal * 100;
          if (pct > 40) {
            final catName = categoryMap[entry.key]?.name ?? entry.key;
            insights.add(SpendingInsight(
              title: '$catName 占比过高',
              description:
                  '$catName 占本月支出 ${pct.toStringAsFixed(0)}%，建议分散支出结构。',
              type: InsightType.warning,
              iconName: 'pie_chart',
            ));
          }
        }
      }
    }

    // --- 5. Potential savings: recurring small expenses ---
    if (sortedMonths.length >= 2) {
      // Find categories that appear every month with small per-transaction avg
      final allCatMonthCounts = <String, int>{};
      final allCatTotalAmounts = <String, double>{};
      final allCatTxCounts = <String, int>{};

      for (final m in sortedMonths) {
        final cats = monthCategoryAmounts[m] ?? {};
        for (final key in cats.keys) {
          allCatMonthCounts[key] = (allCatMonthCounts[key] ?? 0) + 1;
          allCatTotalAmounts[key] =
              (allCatTotalAmounts[key] ?? 0) + cats[key]!;
        }
      }
      // Count transactions per category
      for (final tx in txs) {
        if (tx.amount <= 0) continue;
        final catKey = tx.categoryKey ?? tx.category ?? '其他';
        allCatTxCounts[catKey] = (allCatTxCounts[catKey] ?? 0) + 1;
      }

      for (final key in allCatMonthCounts.keys) {
        if (allCatMonthCounts[key] == sortedMonths.length &&
            sortedMonths.length >= 2) {
          final totalAmt = allCatTotalAmounts[key] ?? 0;
          final txCount = allCatTxCounts[key] ?? 1;
          final avgPerTx = totalAmt / txCount;
          final monthlyAvg = totalAmt / sortedMonths.length;

          // Small per-transaction but adds up across months
          if (avgPerTx < monthlyAvg * 0.3 && txCount >= sortedMonths.length * 3) {
            final catName = categoryMap[key]?.name ?? key;
            final totalStr = totalAmt.toStringAsFixed(0);
            insights.add(SpendingInsight(
              title: '$catName 小额频繁',
              description:
                  '$catName 在 ${sortedMonths.length} 个月内累计 $totalStr 元，小额支出容易被忽视。',
              type: InsightType.tip,
              iconName: 'savings',
            ));
          }
        }
      }
    }

    // --- 6. Spending rhythm (weekday vs weekend) ---
    if (weekdayCount > 0 && weekendCount > 0) {
      final avgWeekday = weekdayTotal / weekdayCount;
      final avgWeekend = weekendTotal / weekendCount;

      if (avgWeekend > avgWeekday * 1.5) {
        final ratio = (avgWeekend / avgWeekday).toStringAsFixed(1);
        insights.add(SpendingInsight(
          title: '周末消费偏高',
          description: '周末笔均支出是工作日的 ${ratio}x，注意周末消费习惯。',
          type: InsightType.tip,
          iconName: 'calendar_today',
        ));
      } else if (avgWeekday > avgWeekend * 1.5) {
        insights.add(const SpendingInsight(
          title: '工作日消费较高',
          description: '工作日笔均支出偏高，可能与通勤或工作餐有关。',
          type: InsightType.tip,
          iconName: 'work_outline',
        ));
      }
    }

    // --- 7. Budget pacing alerts ---
    final budgets = await isar.jiveBudgets
        .filter()
        .isActiveEqualTo(true)
        .findAll();

    for (final budget in budgets) {
      // Only check budgets covering the current month
      if (budget.endDate.isBefore(now) || budget.startDate.isAfter(now)) {
        continue;
      }

      final periodDays = budget.endDate.difference(budget.startDate).inDays;
      final elapsedDays = now.difference(budget.startDate).inDays;
      if (periodDays <= 0) continue;

      final progress = elapsedDays / periodDays;

      // Calculate spent amount for this budget
      var budgetQuery = isar.jiveTransactions
          .filter()
          .typeEqualTo('expense')
          .timestampBetween(budget.startDate, budget.endDate,
              includeUpper: false);
      if (budget.categoryKey != null) {
        budgetQuery =
            budgetQuery.categoryKeyEqualTo(budget.categoryKey);
      }
      if (budget.bookId != null) {
        budgetQuery = budgetQuery.bookIdEqualTo(budget.bookId);
      }
      final budgetTxs = await budgetQuery.findAll();

      double spent = 0;
      for (final tx in budgetTxs) {
        if (tx.amount <= 0 || tx.excludeFromBudget) continue;
        final account =
            tx.accountId != null ? accountById[tx.accountId] : null;
        final txCurrency = account?.currency ?? 'CNY';
        double amount = tx.amount;
        if (txCurrency != budget.currency) {
          amount =
              await currencyService.convert(
                      amount, txCurrency, budget.currency) ??
                  amount;
        }
        spent += amount;
      }

      final effectiveBudget = budget.amount + budget.carryoverAmount;
      if (effectiveBudget <= 0) continue;
      final usageRatio = spent / effectiveBudget;

      if (usageRatio > progress + 0.2 && usageRatio < 1.0) {
        final usagePct = (usageRatio * 100).toStringAsFixed(0);
        final progressPct = (progress * 100).toStringAsFixed(0);
        insights.add(SpendingInsight(
          title: '${budget.name} 预算偏快',
          description:
              '已使用 $usagePct%（时间进度 $progressPct%），建议控制节奏。',
          type: InsightType.warning,
          iconName: 'speed',
        ));
      } else if (usageRatio >= 1.0) {
        insights.add(SpendingInsight(
          title: '${budget.name} 预算已超',
          description:
              '已超出预算 ${((usageRatio - 1) * 100).toStringAsFixed(0)}%，请注意控制。',
          type: InsightType.warning,
          iconName: 'error_outline',
        ));
      }
    }

    // --- 8. Quarter-over-quarter trend ---
    if (sortedMonths.length >= 6) {
      // Current quarter: last 3 months; previous quarter: 3 months before that
      final curQuarterMonths = sortedMonths.sublist(sortedMonths.length - 3);
      final prevQuarterMonths = sortedMonths.sublist(
        sortedMonths.length - 6,
        sortedMonths.length - 3,
      );
      double curQuarterTotal = 0;
      for (final m in curQuarterMonths) {
        curQuarterTotal += monthTotals[m] ?? 0;
      }
      double prevQuarterTotal = 0;
      for (final m in prevQuarterMonths) {
        prevQuarterTotal += monthTotals[m] ?? 0;
      }
      if (prevQuarterTotal > 0) {
        final changePct =
            (curQuarterTotal - prevQuarterTotal) / prevQuarterTotal * 100;
        if (changePct > 20) {
          insights.add(SpendingInsight(
            title: '季度支出上升',
            description:
                '近三个月支出比上季度增长 ${changePct.toStringAsFixed(1)}%，注意整体趋势。',
            type: InsightType.warning,
            iconName: 'trending_up',
          ));
        } else if (changePct < -20) {
          insights.add(SpendingInsight(
            title: '季度支出下降',
            description:
                '近三个月支出比上季度减少 ${changePct.abs().toStringAsFixed(1)}%，做得很好！',
            type: InsightType.achievement,
            iconName: 'trending_down',
          ));
        }
      }
    }

    // --- 9. Year-over-year comparison ---
    if (sortedMonths.length >= 12) {
      final currentMonthKey = sortedMonths.last;
      // Build the same-month key from last year
      final parts = currentMonthKey.split('-');
      final lastYearKey =
          '${int.parse(parts[0]) - 1}-${parts[1]}';
      final curAmt = monthTotals[currentMonthKey] ?? 0;
      final lastYearAmt = monthTotals[lastYearKey];
      if (lastYearAmt != null && lastYearAmt > 0) {
        final changePct = (curAmt - lastYearAmt) / lastYearAmt * 100;
        if (changePct > 20) {
          insights.add(SpendingInsight(
            title: '同比支出增长',
            description:
                '本月支出比去年同月增长 ${changePct.toStringAsFixed(1)}%，请关注变化原因。',
            type: InsightType.warning,
            iconName: 'compare_arrows',
          ));
        } else if (changePct < -20) {
          insights.add(SpendingInsight(
            title: '同比支出下降',
            description:
                '本月支出比去年同月减少 ${changePct.abs().toStringAsFixed(1)}%，节省有成效！',
            type: InsightType.achievement,
            iconName: 'compare_arrows',
          ));
        }
      }
    }

    // --- 10. Spending forecast (project month-end total) ---
    if (sortedMonths.isNotEmpty) {
      final currentMonthKey = sortedMonths.last;
      final curMonthTotal = monthTotals[currentMonthKey] ?? 0;
      final dayOfMonth = now.day;
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      if (dayOfMonth >= 5 && dayOfMonth < daysInMonth) {
        final avgDaily = curMonthTotal / dayOfMonth;
        final projected = avgDaily * daysInMonth;
        // Compare to previous month if available
        if (sortedMonths.length >= 2) {
          final prevMonthTotal =
              monthTotals[sortedMonths[sortedMonths.length - 2]] ?? 0;
          if (prevMonthTotal > 0) {
            final diffPct = (projected - prevMonthTotal) / prevMonthTotal * 100;
            if (diffPct > 20) {
              insights.add(SpendingInsight(
                title: '本月预计超支',
                description:
                    '按当前节奏，本月预计支出 ${projected.toStringAsFixed(0)} 元，'
                    '比上月多 ${diffPct.toStringAsFixed(0)}%。',
                type: InsightType.warning,
                iconName: 'auto_graph',
              ));
            } else if (diffPct < -20) {
              insights.add(SpendingInsight(
                title: '本月预计节省',
                description:
                    '按当前节奏，本月预计支出 ${projected.toStringAsFixed(0)} 元，'
                    '比上月少 ${diffPct.abs().toStringAsFixed(0)}%。',
                type: InsightType.achievement,
                iconName: 'auto_graph',
              ));
            }
          }
        }
      }
    }

    // --- 11. Month-end spike detection ---
    if (sortedMonths.isNotEmpty) {
      // Check the previous complete month for month-end spending spikes
      final String targetMonth;
      if (sortedMonths.length >= 2) {
        targetMonth = sortedMonths[sortedMonths.length - 2];
      } else {
        targetMonth = sortedMonths.last;
      }
      final targetParts = targetMonth.split('-');
      final targetYear = int.parse(targetParts[0]);
      final targetMon = int.parse(targetParts[1]);
      final daysInTarget = DateTime(targetYear, targetMon + 1, 0).day;
      final cutoffDay = daysInTarget - 5;

      double earlyTotal = 0;
      int earlyDays = 0;
      double lateTotal = 0;
      int lateDays = 0;

      // Group daily amounts for the target month
      final Map<int, double> dailyAmounts = {};
      for (final tx in txs) {
        if (tx.amount <= 0) continue;
        final txMonthKey =
            '${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}';
        if (txMonthKey != targetMonth) continue;

        final account =
            tx.accountId != null ? accountById[tx.accountId] : null;
        final txCurrency = account?.currency ?? 'CNY';
        double amount = tx.amount;
        if (txCurrency != currency) {
          amount =
              await currencyService.convert(amount, txCurrency, currency) ??
                  amount;
        }
        final day = tx.timestamp.day;
        dailyAmounts[day] = (dailyAmounts[day] ?? 0) + amount;
      }

      for (final entry in dailyAmounts.entries) {
        if (entry.key <= cutoffDay) {
          earlyTotal += entry.value;
          earlyDays++;
        } else {
          lateTotal += entry.value;
          lateDays++;
        }
      }

      if (earlyDays > 0 && lateDays > 0) {
        final earlyAvg = earlyTotal / earlyDays;
        final lateAvg = lateTotal / lateDays;
        if (earlyAvg > 0 && lateAvg > earlyAvg * 1.3) {
          final ratio = (lateAvg / earlyAvg).toStringAsFixed(1);
          insights.add(SpendingInsight(
            title: '月末消费偏高',
            description:
                '月末最后几天日均支出是月初的 ${ratio}x，建议均匀安排消费节奏。',
            type: InsightType.tip,
            iconName: 'event',
          ));
        }
      }
    }

    // --- 12. Consistent saver achievement ---
    if (sortedMonths.length >= 3) {
      // Fetch income transactions for the same period
      final incomeTxs = await isar.jiveTransactions
          .filter()
          .typeEqualTo('income')
          .timestampBetween(start, end, includeUpper: false)
          .findAll();

      final Map<String, double> monthIncome = {};
      for (final tx in incomeTxs) {
        if (tx.amount <= 0) continue;
        final account =
            tx.accountId != null ? accountById[tx.accountId] : null;
        final txCurrency = account?.currency ?? 'CNY';
        double amount = tx.amount;
        if (txCurrency != currency) {
          amount =
              await currencyService.convert(amount, txCurrency, currency) ??
                  amount;
        }
        final monthKey =
            '${tx.timestamp.year}-${tx.timestamp.month.toString().padLeft(2, '0')}';
        monthIncome[monthKey] = (monthIncome[monthKey] ?? 0) + amount;
      }

      // Check consecutive months with positive balance (income > expense)
      int consecutivePositive = 0;
      int maxConsecutive = 0;
      for (final m in sortedMonths) {
        final income = monthIncome[m] ?? 0;
        final expense = monthTotals[m] ?? 0;
        if (income > expense) {
          consecutivePositive++;
          if (consecutivePositive > maxConsecutive) {
            maxConsecutive = consecutivePositive;
          }
        } else {
          consecutivePositive = 0;
        }
      }

      if (maxConsecutive >= 3) {
        insights.add(SpendingInsight(
          title: '持续储蓄达人',
          description: '已连续 $maxConsecutive 个月收入大于支出，理财习惯非常棒！',
          type: InsightType.achievement,
          iconName: 'emoji_events',
        ));
      }
    }

    return SpendingAnalysis(insights: insights, generatedAt: now);
  }
}

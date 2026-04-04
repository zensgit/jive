import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'stats_aggregation_service.dart';
import 'database_service.dart';
import 'currency_service.dart';
import 'account_service.dart';

/// Generates a PDF annual report.
class PdfReportService {
  /// Generate annual report for the given year.
  static Future<Uint8List> generateAnnualReport(int year) async {
    final isar = await DatabaseService.getInstance();
    final cs = CurrencyService(isar);
    final stats = StatsAggregationService(isar, cs);
    final baseCurrency = await cs.getBaseCurrency();
    final symbol = baseCurrency == 'CNY' ? '¥' : '\$';

    // Gather data
    final monthlyData = <_MonthData>[];
    double yearIncome = 0;
    double yearExpense = 0;
    final categoryTotals = <String, double>{};

    for (int m = 1; m <= 12; m++) {
      final month = DateTime(year, m, 1);
      final summary = await stats.getMonthSummary(month, currencyCode: baseCurrency);
      monthlyData.add(_MonthData(
        month: m,
        income: summary.totalIncome,
        expense: summary.totalExpense,
        balance: summary.balance,
        txCount: summary.transactionCount,
      ));
      yearIncome += summary.totalIncome;
      yearExpense += summary.totalExpense;

      // Category breakdown
      final cats = await stats.getCategoryBreakdown(month, currencyCode: baseCurrency);
      for (final cat in cats) {
        categoryTotals[cat.name] = (categoryTotals[cat.name] ?? 0) + cat.amount;
      }
    }

    // Asset snapshot
    final accountService = AccountService(isar);
    final accounts = await accountService.getActiveAccounts();
    final balances = await accountService.computeBalances(accounts: accounts);
    final totals = accountService.calculateTotals(accounts, balances);

    // Sort categories
    final sortedCats = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Build PDF
    final pdf = pw.Document();
    final fmt = NumberFormat('#,##0.00');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          // Title
          pw.Header(
            level: 0,
            child: pw.Text(
              '${year}年 年度财务报告',
              style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            '生成时间: ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 20),

          // Annual Summary
          pw.Header(level: 1, text: '年度总览'),
          pw.SizedBox(height: 8),
          _buildSummaryTable(symbol, fmt, yearIncome, yearExpense, totals.assets, totals.liabilities),
          pw.SizedBox(height: 20),

          // Monthly Breakdown
          pw.Header(level: 1, text: '月度收支明细'),
          pw.SizedBox(height: 8),
          _buildMonthlyTable(symbol, fmt, monthlyData),
          pw.SizedBox(height: 20),

          // Category Breakdown
          pw.Header(level: 1, text: '支出分类排行'),
          pw.SizedBox(height: 8),
          _buildCategoryTable(symbol, fmt, sortedCats, yearExpense),
          pw.SizedBox(height: 20),

          // Financial Insights
          pw.Header(level: 1, text: '财务洞察'),
          pw.SizedBox(height: 8),
          ..._buildInsights(symbol, fmt, yearIncome, yearExpense, monthlyData, sortedCats),
        ],
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSummaryTable(
    String symbol,
    NumberFormat fmt,
    double income,
    double expense,
    double totalAssets,
    double totalLiabilities,
  ) {
    final balance = income - expense;
    final savingsRate = income > 0 ? balance / income * 100 : 0.0;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(2),
        1: const pw.FlexColumnWidth(3),
      },
      children: [
        _tableRow('年度总收入', '$symbol${fmt.format(income)}', bold: true),
        _tableRow('年度总支出', '$symbol${fmt.format(expense)}', bold: true),
        _tableRow('年度结余', '$symbol${fmt.format(balance)}',
            color: balance >= 0 ? PdfColors.green700 : PdfColors.red700, bold: true),
        _tableRow('储蓄率', '${savingsRate.toStringAsFixed(1)}%'),
        _tableRow('当前总资产', '$symbol${fmt.format(totalAssets)}'),
        _tableRow('当前总负债', '$symbol${fmt.format(totalLiabilities)}'),
        _tableRow('当前净资产', '$symbol${fmt.format(totalAssets - totalLiabilities)}',
            color: totalAssets >= totalLiabilities ? PdfColors.green700 : PdfColors.red700),
      ],
    );
  }

  static pw.TableRow _tableRow(String label, String value, {PdfColor? color, bool bold = false}) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : null)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 11, color: color, fontWeight: bold ? pw.FontWeight.bold : null),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMonthlyTable(String symbol, NumberFormat fmt, List<_MonthData> data) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1.5),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
        4: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: ['月份', '收入', '支出', '结余', '笔数']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        ...data.map((d) => pw.TableRow(
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${d.month}月', style: const pw.TextStyle(fontSize: 10))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$symbol${fmt.format(d.income)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.green700))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$symbol${fmt.format(d.expense)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.red700))),
                pw.Padding(
                  padding: const pw.EdgeInsets.all(6),
                  child: pw.Text(
                    '$symbol${fmt.format(d.balance)}',
                    style: pw.TextStyle(fontSize: 10, color: d.balance >= 0 ? PdfColors.green700 : PdfColors.red700),
                  ),
                ),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${d.txCount}', style: const pw.TextStyle(fontSize: 10))),
              ],
            )),
      ],
    );
  }

  static pw.Widget _buildCategoryTable(String symbol, NumberFormat fmt, List<MapEntry<String, double>> cats, double total) {
    final top10 = cats.take(10).toList();
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: ['排名', '分类', '金额', '占比']
              .map((h) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ))
              .toList(),
        ),
        ...top10.asMap().entries.map((e) {
          final pct = total > 0 ? e.value.value / total * 100 : 0.0;
          return pw.TableRow(
            children: [
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${e.key + 1}', style: const pw.TextStyle(fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.value.key, style: const pw.TextStyle(fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('$symbol${fmt.format(e.value.value)}', style: const pw.TextStyle(fontSize: 10))),
              pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${pct.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 10))),
            ],
          );
        }),
      ],
    );
  }

  static List<pw.Widget> _buildInsights(
    String symbol,
    NumberFormat fmt,
    double yearIncome,
    double yearExpense,
    List<_MonthData> months,
    List<MapEntry<String, double>> cats,
  ) {
    final insights = <String>[];
    final balance = yearIncome - yearExpense;

    // Monthly averages
    final activeMonths = months.where((m) => m.txCount > 0).length;
    if (activeMonths > 0) {
      insights.add('月均支出 $symbol${fmt.format(yearExpense / activeMonths)}，月均收入 $symbol${fmt.format(yearIncome / activeMonths)}');
    }

    // Best/worst month
    final sorted = [...months]..sort((a, b) => a.balance.compareTo(b.balance));
    if (sorted.isNotEmpty && sorted.last.balance > 0) {
      insights.add('结余最多的月份: ${sorted.last.month}月 ($symbol${fmt.format(sorted.last.balance)})');
    }
    if (sorted.isNotEmpty && sorted.first.balance < 0) {
      insights.add('超支最多的月份: ${sorted.first.month}月 ($symbol${fmt.format(sorted.first.balance)})');
    }

    // Top category
    if (cats.isNotEmpty) {
      insights.add('最大支出分类: ${cats.first.key} ($symbol${fmt.format(cats.first.value)})');
    }

    // Savings rate
    if (yearIncome > 0) {
      final rate = balance / yearIncome * 100;
      if (rate >= 30) {
        insights.add('储蓄率 ${rate.toStringAsFixed(1)}%，表现优秀！');
      } else if (rate >= 10) {
        insights.add('储蓄率 ${rate.toStringAsFixed(1)}%，继续保持！');
      } else if (rate > 0) {
        insights.add('储蓄率仅 ${rate.toStringAsFixed(1)}%，建议关注支出控制');
      } else {
        insights.add('年度收不抵支，建议制定预算计划');
      }
    }

    return insights
        .map((text) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 6),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('• ', style: const pw.TextStyle(fontSize: 11)),
                  pw.Expanded(child: pw.Text(text, style: const pw.TextStyle(fontSize: 11))),
                ],
              ),
            ))
        .toList();
  }
}

class _MonthData {
  final int month;
  final double income;
  final double expense;
  final double balance;
  final int txCount;

  const _MonthData({
    required this.month,
    required this.income,
    required this.expense,
    required this.balance,
    required this.txCount,
  });
}

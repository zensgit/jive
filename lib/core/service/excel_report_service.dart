import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../database/category_model.dart';
import '../database/transaction_model.dart';

/// Generates a formatted annual Excel report with multiple sheets.
class ExcelReportService {
  static final DateFormat _dateFmt = DateFormat('yyyy-MM-dd');

  final Isar _isar;

  const ExcelReportService(this._isar);

  /// Generate a full annual Excel report for [year] and return its raw bytes.
  Future<Uint8List> generateAnnualExcel(int year) async {
    final start = DateTime(year);
    final end = DateTime(year, 12, 31, 23, 59, 59);

    final transactions = await _isar.jiveTransactions
        .filter()
        .timestampBetween(start, end)
        .sortByTimestamp()
        .findAll();

    final categories =
        await _isar.collection<JiveCategory>().where().findAll();
    final categoryByKey = {for (final c in categories) c.key: c};

    final workbook = Workbook(4);

    _buildSummarySheet(workbook.worksheets[0], transactions, year);
    _buildMonthlySheet(workbook.worksheets[1], transactions, year);
    _buildCategorySheet(workbook.worksheets[2], transactions, categoryByKey);
    _buildDetailSheet(workbook.worksheets[3], transactions, categoryByKey);

    final bytes = workbook.saveAsStream();
    workbook.dispose();
    return Uint8List.fromList(bytes);
  }

  // ---------------------------------------------------------------------------
  // Sheet 1: 年度总览
  // ---------------------------------------------------------------------------
  void _buildSummarySheet(
    Worksheet sheet,
    List<JiveTransaction> transactions,
    int year,
  ) {
    sheet.name = '年度总览';

    final totalIncome = _sumByType(transactions, 'income');
    final totalExpense = _sumByType(transactions, 'expense');
    final balance = totalIncome - totalExpense;
    final savingsRate =
        totalIncome > 0 ? (balance / totalIncome * 100) : 0.0;

    // Title
    final titleCell = sheet.getRangeByIndex(1, 1);
    titleCell.setText('$year 年度财务总览');
    titleCell.cellStyle.bold = true;
    titleCell.cellStyle.fontSize = 16;

    // Headers (row 3)
    final headers = ['总收入', '总支出', '结余', '储蓄率'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(3, i + 1);
      cell.setText(headers[i]);
      _applyHeaderStyle(cell);
    }

    // Data (row 4)
    _setNumber(sheet, 4, 1, totalIncome, fontColor: '#2E7D32');
    _setNumber(sheet, 4, 2, totalExpense, fontColor: '#C62828');
    _setNumber(sheet, 4, 3, balance);
    final rateCell = sheet.getRangeByIndex(4, 4);
    rateCell.setText('${savingsRate.toStringAsFixed(1)}%');
    rateCell.cellStyle.bold = true;

    for (var i = 1; i <= 4; i++) {
      sheet.autoFitColumn(i);
    }
  }

  // ---------------------------------------------------------------------------
  // Sheet 2: 月度明细
  // ---------------------------------------------------------------------------
  void _buildMonthlySheet(
    Worksheet sheet,
    List<JiveTransaction> transactions,
    int year,
  ) {
    sheet.name = '月度明细';

    final headers = ['月份', '收入', '支出', '结余', '交易笔数'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      _applyHeaderStyle(cell);
    }

    for (var month = 1; month <= 12; month++) {
      final monthTx = transactions
          .where((t) => t.timestamp.month == month)
          .toList();
      final income = _sumByType(monthTx, 'income');
      final expense = _sumByType(monthTx, 'expense');
      final row = month + 1;

      sheet.getRangeByIndex(row, 1).setText('$month月');
      _setNumber(sheet, row, 2, income, fontColor: '#2E7D32');
      _setNumber(sheet, row, 3, expense, fontColor: '#C62828');
      _setNumber(sheet, row, 4, income - expense);
      sheet.getRangeByIndex(row, 5).setNumber(monthTx.length.toDouble());
    }

    for (var i = 1; i <= 5; i++) {
      sheet.autoFitColumn(i);
    }
  }

  // ---------------------------------------------------------------------------
  // Sheet 3: 分类排行
  // ---------------------------------------------------------------------------
  void _buildCategorySheet(
    Worksheet sheet,
    List<JiveTransaction> transactions,
    Map<String, JiveCategory> categoryByKey,
  ) {
    sheet.name = '分类排行';

    final headers = ['排名', '分类', '类型', '金额', '占比'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      _applyHeaderStyle(cell);
    }

    // Aggregate amounts per category key
    final catTotals = <String, double>{};
    final catTypes = <String, String>{};
    for (final tx in transactions) {
      final key = tx.categoryKey ?? '未分类';
      catTotals[key] = (catTotals[key] ?? 0) + tx.amount;
      catTypes.putIfAbsent(key, () => tx.type ?? 'expense');
    }

    final totalAmount =
        catTotals.values.fold<double>(0, (s, v) => s + v);

    // Sort descending by amount
    final sorted = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (var i = 0; i < sorted.length; i++) {
      final entry = sorted[i];
      final row = i + 2;
      final catName = categoryByKey[entry.key]?.name ?? entry.key;
      final type = catTypes[entry.key] ?? 'expense';
      final pct =
          totalAmount > 0 ? (entry.value / totalAmount * 100) : 0.0;

      sheet.getRangeByIndex(row, 1).setNumber((i + 1).toDouble());
      sheet.getRangeByIndex(row, 2).setText(catName);
      sheet.getRangeByIndex(row, 3).setText(type == 'income' ? '收入' : '支出');
      _setNumber(sheet, row, 4, entry.value);
      sheet.getRangeByIndex(row, 5).setText('${pct.toStringAsFixed(1)}%');
    }

    for (var i = 1; i <= 5; i++) {
      sheet.autoFitColumn(i);
    }
  }

  // ---------------------------------------------------------------------------
  // Sheet 4: 交易明细
  // ---------------------------------------------------------------------------
  void _buildDetailSheet(
    Worksheet sheet,
    List<JiveTransaction> transactions,
    Map<String, JiveCategory> categoryByKey,
  ) {
    sheet.name = '交易明细';

    final headers = ['日期', '金额', '分类', '备注', '类型'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      _applyHeaderStyle(cell);
    }

    for (var r = 0; r < transactions.length; r++) {
      final tx = transactions[r];
      final row = r + 2;
      final catName = categoryByKey[tx.categoryKey]?.name ?? '';

      sheet.getRangeByIndex(row, 1).setText(_dateFmt.format(tx.timestamp));
      _setNumber(sheet, row, 2, tx.amount,
          fontColor: tx.type == 'income' ? '#2E7D32' : '#C62828');
      sheet.getRangeByIndex(row, 3).setText(catName);
      sheet.getRangeByIndex(row, 4).setText(tx.note?.trim() ?? '');
      sheet.getRangeByIndex(row, 5).setText(_typeLabel(tx.type));
    }

    for (var i = 1; i <= 5; i++) {
      sheet.autoFitColumn(i);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  double _sumByType(List<JiveTransaction> list, String type) {
    return list
        .where((t) => t.type == type)
        .fold<double>(0, (s, t) => s + t.amount);
  }

  void _applyHeaderStyle(Range cell) {
    cell.cellStyle.bold = true;
    cell.cellStyle.backColor = '#E8F5E9';
    cell.cellStyle.fontColor = '#1B5E20';
  }

  void _setNumber(
    Worksheet sheet,
    int row,
    int col,
    double value, {
    String? fontColor,
  }) {
    final cell = sheet.getRangeByIndex(row, col);
    cell.setNumber(value);
    cell.numberFormat = '#,##0.00';
    if (fontColor != null) {
      cell.cellStyle.fontColor = fontColor;
    }
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      default:
        return '支出';
    }
  }
}

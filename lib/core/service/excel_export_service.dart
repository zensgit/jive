import 'dart:io';

import 'package:intl/intl.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';

import '../database/account_model.dart';
import '../database/category_model.dart';
import '../database/tag_model.dart';
import '../database/transaction_model.dart';

/// Exports transactions to a formatted .xlsx file.
class ExcelExportService {
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm');

  final Isar _isar;

  const ExcelExportService(this._isar);

  /// Export transactions in the given date range to an Excel file.
  Future<File> exportTransactions(
    DateTime start,
    DateTime end, {
    String? categoryKey,
  }) async {
    // Load data
    final rangeStart = DateTime(start.year, start.month, start.day);
    final rangeEnd = DateTime(end.year, end.month, end.day, 23, 59, 59);

    var query = _isar.jiveTransactions
        .filter()
        .timestampBetween(rangeStart, rangeEnd);

    if (categoryKey != null && categoryKey.isNotEmpty) {
      query = query.group((q) =>
          q.categoryKeyEqualTo(categoryKey).or().subCategoryKeyEqualTo(categoryKey));
    }

    final transactions = await query.sortByTimestampDesc().findAll();
    final accounts = await _isar.collection<JiveAccount>().where().findAll();
    final categories = await _isar.collection<JiveCategory>().where().findAll();
    final tags = await _isar.collection<JiveTag>().where().findAll();

    final accountById = {for (final a in accounts) a.id: a};
    final categoryByKey = {for (final c in categories) c.key: c};
    final tagByKey = {for (final t in tags) t.key: t};

    // Create workbook
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = '交易记录';

    // Header row
    final headers = ['日期', '类型', '金额', '分类', '子分类', '备注', '账户', '标签'];
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#E8F5E9';
      cell.cellStyle.fontColor = '#1B5E20';
    }

    // Data rows
    for (var r = 0; r < transactions.length; r++) {
      final tx = transactions[r];
      final row = r + 2;

      sheet.getRangeByIndex(row, 1).setText(_dateFormat.format(tx.timestamp));
      sheet.getRangeByIndex(row, 2).setText(_typeLabel(tx.type));
      sheet.getRangeByIndex(row, 3).setNumber(tx.amount);
      sheet.getRangeByIndex(row, 3).numberFormat = '#,##0.00';
      sheet.getRangeByIndex(row, 4).setText(_categoryName(tx.categoryKey, categoryByKey));
      sheet.getRangeByIndex(row, 5).setText(_categoryName(tx.subCategoryKey, categoryByKey));
      sheet.getRangeByIndex(row, 6).setText(tx.note?.trim() ?? '');
      sheet.getRangeByIndex(row, 7).setText(_accountName(tx.accountId, accountById));
      sheet.getRangeByIndex(row, 8).setText(_tagNames(tx.tagKeys, tagByKey));

      // Color code by type
      if (tx.type == 'income') {
        sheet.getRangeByIndex(row, 3).cellStyle.fontColor = '#2E7D32';
      } else if (tx.type == 'expense') {
        sheet.getRangeByIndex(row, 3).cellStyle.fontColor = '#C62828';
      }
    }

    // Auto-fit column widths (approximate)
    for (var i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }

    // Summary row
    final summaryRow = transactions.length + 3;
    sheet.getRangeByIndex(summaryRow, 1).setText('汇总');
    sheet.getRangeByIndex(summaryRow, 1).cellStyle.bold = true;

    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold<double>(0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0, (s, t) => s + t.amount);

    sheet.getRangeByIndex(summaryRow + 1, 1).setText('总收入');
    sheet.getRangeByIndex(summaryRow + 1, 2).setNumber(totalIncome);
    sheet.getRangeByIndex(summaryRow + 1, 2).numberFormat = '#,##0.00';
    sheet.getRangeByIndex(summaryRow + 1, 2).cellStyle.fontColor = '#2E7D32';

    sheet.getRangeByIndex(summaryRow + 2, 1).setText('总支出');
    sheet.getRangeByIndex(summaryRow + 2, 2).setNumber(totalExpense);
    sheet.getRangeByIndex(summaryRow + 2, 2).numberFormat = '#,##0.00';
    sheet.getRangeByIndex(summaryRow + 2, 2).cellStyle.fontColor = '#C62828';

    sheet.getRangeByIndex(summaryRow + 3, 1).setText('结余');
    sheet.getRangeByIndex(summaryRow + 3, 1).cellStyle.bold = true;
    sheet.getRangeByIndex(summaryRow + 3, 2).setNumber(totalIncome - totalExpense);
    sheet.getRangeByIndex(summaryRow + 3, 2).numberFormat = '#,##0.00';
    sheet.getRangeByIndex(summaryRow + 3, 2).cellStyle.bold = true;

    // Save to file
    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final dir = await getApplicationDocumentsDirectory();
    final startStr = DateFormat('yyyyMMdd').format(start);
    final endStr = DateFormat('yyyyMMdd').format(end);
    final file = File('${dir.path}/jive_transactions_${startStr}_$endStr.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    return file;
  }

  String _typeLabel(String? type) {
    switch (type) {
      case 'income': return '收入';
      case 'transfer': return '转账';
      default: return '支出';
    }
  }

  String _categoryName(String? key, Map<String, JiveCategory> map) {
    if (key == null || key.isEmpty) return '';
    return map[key]?.name ?? '';
  }

  String _accountName(int? id, Map<int, JiveAccount> map) {
    if (id == null) return '';
    return map[id]?.name ?? '';
  }

  String _tagNames(List<String> keys, Map<String, JiveTag> map) {
    if (keys.isEmpty) return '';
    return keys.map((k) => map[k]?.name ?? k).join(', ');
  }
}

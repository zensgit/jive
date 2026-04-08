import 'import_service.dart';

/// Specialized parser for WeChat (微信) bill export CSV.
///
/// WeChat CSV format:
/// - Header rows start with "微信支付账单明细" and metadata
/// - Actual data starts after a header row containing column names
/// - Columns: 交易时间, 交易类型, 交易对方, 商品, 收/支, 金额(元), 支付方式, 当前状态, 交易单号, 商户单号, 备注
class WechatCsvParser {
  /// Parse WeChat CSV content into ImportParsedRecord list.
  static List<ImportParsedRecord> parse(String content) {
    final lines = content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return [];

    // Find the header row (contains "交易时间")
    int headerIdx = -1;
    for (int i = 0; i < lines.length && i < 20; i++) {
      if (lines[i].contains('交易时间') && lines[i].contains('金额')) {
        headerIdx = i;
        break;
      }
    }
    if (headerIdx < 0) return [];

    final headers = _splitCsvLine(lines[headerIdx]);
    final colMap = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      colMap[headers[i].replaceAll('"', '').trim()] = i;
    }

    final records = <ImportParsedRecord>[];

    for (int i = headerIdx + 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty || line.startsWith(',,')) continue;

      final cols = _splitCsvLine(line);
      final record = _parseRow(cols, colMap, i + 1);
      if (record != null) records.add(record);
    }

    return records;
  }

  static ImportParsedRecord? _parseRow(List<String> cols, Map<String, int> colMap, int lineNumber) {
    String col(String name) {
      final idx = colMap[name];
      if (idx == null || idx >= cols.length) return '';
      return cols[idx].replaceAll('"', '').trim();
    }

    final timeStr = col('交易时间');
    final txType = col('交易类型');
    final counterparty = col('交易对方');
    final product = col('商品');
    final direction = col('收/支');
    final amountStr = col('金额(元)').replaceAll('¥', '').replaceAll('￥', '').trim();
    final payMethod = col('支付方式');
    final status = col('当前状态');
    // final remark = _col('备注');

    // Skip non-completed transactions
    if (status.isNotEmpty && !status.contains('支付成功') && !status.contains('已收钱') && !status.contains('已转账') && !status.contains('充值完成') && !status.contains('已退款') && status != '/') {
      return null;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) return null;

    DateTime? timestamp;
    if (timeStr.isNotEmpty) {
      timestamp = DateTime.tryParse(timeStr.replaceAll('/', '-'));
    }

    // Determine type
    String type = 'expense';
    if (direction.contains('收入') || status.contains('已收钱') || status.contains('已退款')) {
      type = 'income';
    } else if (txType.contains('转账') || direction.contains('转账')) {
      type = 'transfer';
    }

    return ImportParsedRecord(
      amount: amount,
      source: '微信支付',
      timestamp: timestamp ?? DateTime.now(),
      rawText: '$counterparty - $product',
      type: type,
      accountName: payMethod.isNotEmpty ? payMethod : null,
      parentCategoryName: _inferCategory(txType, product, counterparty),
      lineNumber: lineNumber,
      confidence: 0.9,
      warnings: [],
    );
  }

  static String? _inferCategory(String txType, String product, String counterparty) {
    final combined = '$txType $product $counterparty'.toLowerCase();
    if (combined.contains('红包')) return '红包';
    if (combined.contains('转账')) return '转账';
    if (combined.contains('外卖') || combined.contains('美团') || combined.contains('饿了么')) return '餐饮';
    if (combined.contains('超市') || combined.contains('便利店')) return '购物';
    if (combined.contains('打车') || combined.contains('滴滴') || combined.contains('出行')) return '交通';
    if (combined.contains('话费') || combined.contains('充值')) return '通讯';
    if (combined.contains('水电') || combined.contains('燃气') || combined.contains('物业')) return '住房';
    return null;
  }

  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;

    for (int i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        inQuotes = !inQuotes;
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString());
    return result;
  }

  /// Check if content looks like a WeChat CSV export.
  static bool isWechatFormat(String content) {
    final firstLines = content.substring(0, content.length.clamp(0, 500));
    return firstLines.contains('微信支付账单') || (firstLines.contains('交易时间') && firstLines.contains('交易对方'));
  }
}

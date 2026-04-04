import 'import_service.dart';

/// Specialized parser for Alipay (支付宝) bill export CSV.
///
/// Alipay CSV format:
/// - Header rows with account info and date range
/// - Column row: 交易号, 商家订单号, 交易创建时间, 付款时间, 最近修改时间,
///   交易来源地, 类型, 交易对方, 商品名称, 金额（元）, 收/支, 交易状态,
///   服务费（元）, 成功退款（元）, 备注, 资金状态
class AlipayCsvParser {
  /// Parse Alipay CSV content into ImportParsedRecord list.
  static List<ImportParsedRecord> parse(String content) {
    final lines = content.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
    if (lines.isEmpty) return [];

    // Find the header row
    int headerIdx = -1;
    for (int i = 0; i < lines.length && i < 30; i++) {
      final line = lines[i];
      if ((line.contains('交易号') || line.contains('交易创建时间')) && line.contains('金额')) {
        headerIdx = i;
        break;
      }
    }
    if (headerIdx < 0) return [];

    final headers = _splitCsvLine(lines[headerIdx]);
    final colMap = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      final h = headers[i].replaceAll('"', '').trim();
      if (h.isNotEmpty) colMap[h] = i;
    }

    final records = <ImportParsedRecord>[];

    for (int i = headerIdx + 1; i < lines.length; i++) {
      final line = lines[i];
      if (line.isEmpty || line.startsWith('-')) continue;

      final cols = _splitCsvLine(line);
      final record = _parseRow(cols, colMap, i + 1);
      if (record != null) records.add(record);
    }

    return records;
  }

  static ImportParsedRecord? _parseRow(List<String> cols, Map<String, int> colMap, int lineNumber) {
    String _col(String name) {
      final idx = colMap[name];
      if (idx == null || idx >= cols.length) return '';
      return cols[idx].replaceAll('"', '').trim();
    }

    // Try multiple possible column names
    String _colAny(List<String> names) {
      for (final name in names) {
        final v = _col(name);
        if (v.isNotEmpty) return v;
      }
      return '';
    }

    final timeStr = _colAny(['交易创建时间', '付款时间', '交易时间']);
    final txType = _colAny(['类型', '交易类型']);
    final counterparty = _colAny(['交易对方', '对方']);
    final product = _colAny(['商品名称', '商品说明', '商品']);
    final direction = _colAny(['收/支', '收支']);
    final amountStr = _colAny(['金额（元）', '金额(元)', '金额']).replaceAll('¥', '').replaceAll('￥', '').trim();
    final status = _colAny(['交易状态', '状态']);
    final feeStr = _colAny(['服务费（元）', '服务费(元)', '服务费']).replaceAll('¥', '').replaceAll('￥', '').trim();
    final refundStr = _colAny(['成功退款（元）', '成功退款(元)', '退款']).replaceAll('¥', '').replaceAll('￥', '').trim();
    final fundStatus = _colAny(['资金状态']);

    // Skip non-completed
    if (status.isNotEmpty && !status.contains('交易成功') && !status.contains('退款成功') && !status.contains('已收钱') && !status.contains('交易关闭') && status != '/') {
      // Allow "交易关闭" only if it has a refund amount
      if (!status.contains('交易关闭') || refundStr.isEmpty) {
        return null;
      }
    }

    // Skip closed with no financial impact
    if (fundStatus.isNotEmpty && fundStatus.contains('不计收支')) {
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
    if (direction.contains('收入') || direction.contains('已收入')) {
      type = 'income';
    } else if (txType.contains('转账') || direction.contains('不计收支')) {
      type = 'transfer';
    }

    // Handle refunds
    final refundAmount = double.tryParse(refundStr) ?? 0;
    if (refundAmount > 0 && status.contains('退款成功')) {
      type = 'income';
    }

    // Service fee
    final fee = double.tryParse(feeStr) ?? 0;
    final warnings = <String>[];
    if (fee > 0) {
      warnings.add('手续费: ¥${fee.toStringAsFixed(2)}');
    }

    return ImportParsedRecord(
      amount: refundAmount > 0 ? refundAmount : amount,
      source: '支付宝',
      timestamp: timestamp ?? DateTime.now(),
      rawText: '$counterparty - $product',
      type: type,
      parentCategoryName: _inferCategory(txType, product, counterparty),
      serviceCharge: fee > 0 ? fee : null,
      lineNumber: lineNumber,
      confidence: 0.9,
      warnings: warnings,
    );
  }

  static String? _inferCategory(String txType, String product, String counterparty) {
    final combined = '$txType $product $counterparty'.toLowerCase();
    if (combined.contains('转账')) return '转账';
    if (combined.contains('红包')) return '红包';
    if (combined.contains('外卖') || combined.contains('美团') || combined.contains('饿了么') || combined.contains('餐')) return '餐饮';
    if (combined.contains('淘宝') || combined.contains('天猫') || combined.contains('京东') || combined.contains('购物')) return '购物';
    if (combined.contains('滴滴') || combined.contains('打车') || combined.contains('出行') || combined.contains('地铁') || combined.contains('公交')) return '交通';
    if (combined.contains('话费') || combined.contains('充值') || combined.contains('流量')) return '通讯';
    if (combined.contains('水费') || combined.contains('电费') || combined.contains('燃气') || combined.contains('物业') || combined.contains('房租')) return '住房';
    if (combined.contains('医院') || combined.contains('药房') || combined.contains('医疗')) return '医疗';
    if (combined.contains('教育') || combined.contains('培训') || combined.contains('学费')) return '教育';
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

  /// Check if content looks like an Alipay CSV export.
  static bool isAlipayFormat(String content) {
    final firstLines = content.substring(0, content.length.clamp(0, 800));
    return firstLines.contains('支付宝') && (firstLines.contains('交易号') || firstLines.contains('交易创建时间'));
  }
}

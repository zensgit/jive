import 'package:isar/isar.dart';

import '../database/invoice_model.dart';

/// 发票/收据管理服务
class InvoiceService {
  final Isar isar;

  InvoiceService(this.isar);

  /// 从 QR 码数据创建发票
  /// QR 格式假定: key=value 对以 & 分隔, 或逗号分隔
  Future<JiveInvoice> createFromQR(String qrData) async {
    final parsed = _parseQRData(qrData);
    final invoice = JiveInvoice()
      ..invoiceNumber = parsed['invoiceNumber'] ?? 'QR-${DateTime.now().millisecondsSinceEpoch}'
      ..amount = double.tryParse(parsed['amount'] ?? '')
      ..vendorName = parsed['vendorName']
      ..invoiceDate = DateTime.tryParse(parsed['date'] ?? '')
      ..qrData = qrData
      ..status = 'pending'
      ..createdAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.jiveInvoices.put(invoice);
    });
    return invoice;
  }

  /// 从图片路径创建发票（手动录入占位）
  Future<JiveInvoice> createFromImage(String imagePath) async {
    final invoice = JiveInvoice()
      ..invoiceNumber = 'IMG-${DateTime.now().millisecondsSinceEpoch}'
      ..imagePath = imagePath
      ..status = 'pending'
      ..createdAt = DateTime.now();

    await isar.writeTxn(() async {
      await isar.jiveInvoices.put(invoice);
    });
    return invoice;
  }

  /// 关联发票到交易
  Future<void> linkToTransaction(int invoiceId, int transactionId) async {
    final invoice = await isar.jiveInvoices.get(invoiceId);
    if (invoice == null) throw StateError('发票不存在');

    invoice.transactionId = transactionId;
    invoice.status = 'linked';

    await isar.writeTxn(() async {
      await isar.jiveInvoices.put(invoice);
    });
  }

  /// 获取所有未关联的发票
  Future<List<JiveInvoice>> getUnlinked() async {
    return isar.jiveInvoices
        .filter()
        .statusEqualTo('pending')
        .sortByCreatedAtDesc()
        .findAll();
  }

  /// 获取某交易关联的发票
  Future<List<JiveInvoice>> getByTransaction(int transactionId) async {
    return isar.jiveInvoices
        .filter()
        .transactionIdEqualTo(transactionId)
        .findAll();
  }

  /// 获取所有发票（按日期倒序）
  Future<List<JiveInvoice>> getAll() async {
    return isar.jiveInvoices.where().sortByCreatedAtDesc().findAll();
  }

  /// 归档发票
  Future<void> archive(int invoiceId) async {
    final invoice = await isar.jiveInvoices.get(invoiceId);
    if (invoice == null) return;
    invoice.status = 'archived';
    await isar.writeTxn(() async {
      await isar.jiveInvoices.put(invoice);
    });
  }

  /// 删除发票
  Future<void> delete(int invoiceId) async {
    await isar.writeTxn(() async {
      await isar.jiveInvoices.delete(invoiceId);
    });
  }

  /// 解析 QR 码数据
  /// 支持格式:
  ///   invoiceNumber=xxx&amount=100&vendorName=yyy&date=2024-01-01
  ///   或自由文本 (整个作为 invoiceNumber)
  Map<String, String> _parseQRData(String data) {
    final result = <String, String>{};
    if (data.contains('=')) {
      final parts = data.split('&');
      for (final part in parts) {
        final kv = part.split('=');
        if (kv.length == 2) {
          result[kv[0].trim()] = Uri.decodeComponent(kv[1].trim());
        }
      }
    }
    if (!result.containsKey('invoiceNumber')) {
      // 尝试从中国国税发票 QR 格式提取
      // 格式: 01,10,发票代码,发票号码,金额,日期,...
      final commas = data.split(',');
      if (commas.length >= 6) {
        result['invoiceNumber'] = commas[3];
        result['amount'] = commas[4];
        result['date'] = commas[5];
      }
    }
    return result;
  }
}

import 'package:isar/isar.dart';

part 'invoice_model.g.dart';

@collection
class JiveInvoice {
  Id id = Isar.autoIncrement;

  /// 发票号码
  late String invoiceNumber;

  /// 金额
  double? amount;

  /// 商户/供应商名称
  String? vendorName;

  /// 发票日期
  DateTime? invoiceDate;

  /// 关联交易 ID
  @Index()
  int? transactionId;

  /// 收据照片路径
  String? imagePath;

  /// 原始 QR 码数据
  String? qrData;

  /// 状态: pending | linked | archived
  @Index()
  String status = 'pending';

  /// 创建时间
  @Index()
  DateTime createdAt = DateTime.now();
}

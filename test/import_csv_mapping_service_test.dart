import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/import_csv_mapping_service.dart';
import 'package:jive/core/service/import_service.dart';

void main() {
  final service = ImportCsvMappingService();

  test('inspect infers mapping from known headers', () {
    const payload =
        '账本,渠道,转入账户,一级分类,二级分类,交易时间,金额,手续费,收支类型,备注,标签\n'
        '家庭账本,WeChat,招商银行,餐饮,早餐,2026-03-15 08:00,18.50,1.20,支出,早餐,工作日 早餐';

    final draft = service.inspect(payload);

    expect(draft.hasHeader, isTrue);
    expect(draft.mapping.accountBookColumnIndex, 0);
    expect(draft.mapping.assetColumnIndex, 1);
    expect(draft.mapping.toAssetColumnIndex, 2);
    expect(draft.mapping.parentCategoryColumnIndex, 3);
    expect(draft.mapping.childCategoryColumnIndex, 4);
    expect(draft.mapping.dateColumnIndex, 5);
    expect(draft.mapping.amountColumnIndex, 6);
    expect(draft.mapping.serviceChargeColumnIndex, 7);
    expect(draft.mapping.typeColumnIndex, 8);
    expect(draft.mapping.remarkColumnIndex, 9);
    expect(draft.mapping.tagColumnIndex, 10);
  });

  test('parseWithMapping repairs blocked amount column in preview payload', () {
    const payload =
        '总额,交易时间,渠道,一级分类,二级分类,收支类型,备注,标签\n'
        '12.50,2026-03-15 08:00,WeChat,餐饮,早餐,支出,早餐映射修复,工作日 早餐';

    final records = service.parseWithMapping(
      payload,
      mapping: const ImportCsvColumnMapping(
        amountColumnIndex: 0,
        dateColumnIndex: 1,
        assetColumnIndex: 2,
        parentCategoryColumnIndex: 3,
        childCategoryColumnIndex: 4,
        typeColumnIndex: 5,
        remarkColumnIndex: 6,
        tagColumnIndex: 7,
      ),
      sourceType: ImportSourceType.csv,
    );

    expect(records, hasLength(1));
    expect(records.first.amount, 12.5);
    expect(records.first.isValid, isTrue);
    expect(records.first.source, 'WeChat');
    expect(records.first.type, 'expense');
    expect(records.first.rawText, '早餐映射修复');
    expect(records.first.parentCategoryName, '餐饮');
    expect(records.first.childCategoryName, '早餐');
    expect(records.first.tagNames, ['工作日', '早餐']);
  });

  test('parseWithMapping keeps transfer target account and service charge', () {
    const payload =
        '金额,交易时间,转出账户,转入账户,手续费,备注\n'
        '88.80,2026-03-15 09:00,微信,招商银行,1.50,转账到储蓄卡';

    final records = service.parseWithMapping(
      payload,
      mapping: const ImportCsvColumnMapping(
        amountColumnIndex: 0,
        dateColumnIndex: 1,
        assetColumnIndex: 2,
        toAssetColumnIndex: 3,
        serviceChargeColumnIndex: 4,
        remarkColumnIndex: 5,
      ),
      sourceType: ImportSourceType.csv,
    );

    expect(records, hasLength(1));
    expect(records.first.type, 'transfer');
    expect(records.first.accountName, '微信');
    expect(records.first.toAccountName, '招商银行');
    expect(records.first.serviceCharge, 1.5);
  });
}

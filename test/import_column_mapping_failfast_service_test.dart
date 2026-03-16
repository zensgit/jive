import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/service/import_column_mapping_failfast_service.dart';

void main() {
  final service = ImportColumnMappingFailfastService();

  test('evaluate returns ready for distinct required mappings', () {
    final result = service.evaluate(
      const ImportColumnMappingFailfastInput(
        sourceScope: 'custom_csv',
        headers: ['账本', '账户', '一级分类', '日期', '金额', '备注', '收支类型'],
        accountBookColumnIndex: 0,
        assetColumnIndex: 1,
        parentCategoryColumnIndex: 2,
        childCategoryColumnIndex: null,
        dateColumnIndex: 3,
        amountColumnIndex: 4,
        remarkColumnIndex: 5,
        typeColumnIndex: 6,
      ),
    );

    expect(result.status, ImportColumnMappingFailfastStatus.ready);
    expect(result.mode, ImportColumnMappingFailfastMode.direct);
  });

  test('evaluate returns block when category mapping is absent', () {
    final result = service.evaluate(
      const ImportColumnMappingFailfastInput(
        sourceScope: 'custom_csv',
        headers: ['账本', '账户', '日期', '金额', '备注', '收支类型'],
        accountBookColumnIndex: 0,
        assetColumnIndex: 1,
        parentCategoryColumnIndex: null,
        childCategoryColumnIndex: null,
        dateColumnIndex: 3,
        amountColumnIndex: 4,
        remarkColumnIndex: 5,
        typeColumnIndex: 6,
      ),
    );

    expect(result.status, ImportColumnMappingFailfastStatus.block);
    expect(result.reason, contains('分类列未映射'));
  });

  test('evaluate returns block when duplicate column is reused', () {
    final result = service.evaluate(
      const ImportColumnMappingFailfastInput(
        sourceScope: 'custom_csv',
        headers: ['账本', '账户', '一级分类', '日期', '金额', '备注', '收支类型'],
        accountBookColumnIndex: 0,
        assetColumnIndex: 1,
        parentCategoryColumnIndex: 2,
        childCategoryColumnIndex: null,
        dateColumnIndex: 3,
        amountColumnIndex: 3,
        remarkColumnIndex: 5,
        typeColumnIndex: 6,
      ),
    );

    expect(result.status, ImportColumnMappingFailfastStatus.block);
    expect(result.reason, contains('重复列映射'));
  });

  test('evaluate returns review when optional mapping is incomplete', () {
    final result = service.evaluate(
      const ImportColumnMappingFailfastInput(
        sourceScope: 'custom_csv',
        headers: ['账户', '一级分类', '日期', '金额', '备注'],
        accountBookColumnIndex: null,
        assetColumnIndex: 1,
        parentCategoryColumnIndex: 2,
        childCategoryColumnIndex: null,
        dateColumnIndex: 3,
        amountColumnIndex: 4,
        remarkColumnIndex: 5,
        typeColumnIndex: null,
      ),
    );

    expect(result.status, ImportColumnMappingFailfastStatus.review);
    expect(result.reason, contains('映射不完整'));
  });

  test('evaluate allows import-center scope to skip category requirement', () {
    final result = service.evaluate(
      const ImportColumnMappingFailfastInput(
        sourceScope: 'import_center_csv_preview',
        headers: ['交易时间', '金额', '渠道', '收支类型', '备注'],
        requireCategoryMapping: false,
        requireAccountBookMappingForReady: false,
        accountBookColumnIndex: null,
        assetColumnIndex: 2,
        parentCategoryColumnIndex: null,
        childCategoryColumnIndex: null,
        dateColumnIndex: 0,
        amountColumnIndex: 1,
        remarkColumnIndex: 4,
        typeColumnIndex: 3,
      ),
    );

    expect(result.status, ImportColumnMappingFailfastStatus.ready);
    expect(result.reason, contains('列映射满足'));
  });

  test('exports json markdown csv payloads', () {
    final result = service.evaluate(
      const ImportColumnMappingFailfastInput(
        sourceScope: 'custom_csv',
        headers: ['账本', '账户', '一级分类', '日期', '金额', '备注', '收支类型'],
        accountBookColumnIndex: 0,
        assetColumnIndex: 1,
        parentCategoryColumnIndex: 2,
        childCategoryColumnIndex: null,
        dateColumnIndex: 3,
        amountColumnIndex: 4,
        remarkColumnIndex: 5,
        typeColumnIndex: 6,
      ),
    );

    expect(result.exportJson(), contains('"status": "ready"'));
    expect(result.exportMarkdown(), contains('# 导入列映射 Fail-Fast 报告'));
    expect(result.exportCsv(), contains('field,value'));
    expect(result.exportCsv(), contains('status,ready'));

    final reportDir = Directory(
      '${Directory.current.path}/build/reports/import-column-mapping',
    )..createSync(recursive: true);
    final jsonFile = File(
      '${reportDir.path}/import-column-mapping-failfast.json',
    );
    jsonFile.writeAsStringSync(result.exportJson());
    final markdownFile = File(
      '${reportDir.path}/import-column-mapping-failfast.md',
    );
    markdownFile.writeAsStringSync(result.exportMarkdown());
    final csvFile = File(
      '${reportDir.path}/import-column-mapping-failfast.csv',
    );
    csvFile.writeAsStringSync(result.exportCsv());

    expect(jsonFile.existsSync(), isTrue);
    expect(markdownFile.existsSync(), isTrue);
    expect(csvFile.existsSync(), isTrue);
  });

  test(
    'evaluate returns review when headers contain blank dirty and duplicate candidates',
    () {
      final result = service.evaluate(
        const ImportColumnMappingFailfastInput(
          sourceScope: 'custom_csv',
          headers: [' 账本 ', '', '日期', '交易-时间', '金额', '交易金额', '备注'],
          accountBookColumnIndex: 0,
          assetColumnIndex: 4,
          parentCategoryColumnIndex: 2,
          childCategoryColumnIndex: null,
          dateColumnIndex: 3,
          amountColumnIndex: 5,
          remarkColumnIndex: 6,
          typeColumnIndex: null,
        ),
      );

      expect(result.status, ImportColumnMappingFailfastStatus.review);
      expect(result.mode, ImportColumnMappingFailfastMode.manualReview);
      expect(result.reason, contains('空列头'));
      expect(result.reason, contains('脏列头'));
      expect(result.reason, contains('重复候选列头'));
    },
  );
}

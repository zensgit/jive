import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/service/csv_export_service.dart';

void main() {
  test('CSV account display label includes custom account group path', () {
    final account = JiveAccount()
      ..name = '活期'
      ..type = 'asset'
      ..groupName = '中国银行'
      ..currency = 'CNY';

    expect(CsvExportService.accountDisplayLabel(account), '中国银行 / 活期 / CNY');
  });

  test('CSV account display label keeps broad legacy groups compact', () {
    final account = JiveAccount()
      ..name = '微信零钱'
      ..type = 'asset'
      ..groupName = '资金账户'
      ..currency = 'CNY';

    expect(CsvExportService.accountDisplayLabel(account), '微信零钱');
  });

  test('CSV transfer account display label includes both grouped paths', () {
    final source = JiveAccount()
      ..name = '活期'
      ..type = 'asset'
      ..groupName = '中国银行'
      ..currency = 'CNY';
    final target = JiveAccount()
      ..name = '定期'
      ..type = 'asset'
      ..groupName = '中国银行'
      ..currency = 'USD';

    expect(
      CsvExportService.transferAccountDisplayLabel(source, target),
      '中国银行 / 活期 / CNY -> 中国银行 / 定期 / USD',
    );
  });

  test(
    'CSV transfer account display label preserves missing side fallback',
    () {
      final target = JiveAccount()
        ..name = '定期'
        ..type = 'asset'
        ..groupName = '中国银行'
        ..currency = 'USD';

      expect(
        CsvExportService.transferAccountDisplayLabel(null, target),
        '中国银行 / 定期 / USD',
      );
      expect(CsvExportService.transferAccountDisplayLabel(null, null), '');
    },
  );
}

import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/service/data_backup_service.dart';

void main() {
  test('report account display name includes custom account group path', () {
    final account = JiveAccount()
      ..name = '活期'
      ..type = 'asset'
      ..groupName = '中国银行'
      ..currency = 'CNY';

    expect(
      JiveDataBackupService.reportAccountDisplayName(account),
      '中国银行 / 活期 / CNY',
    );
  });

  test('report account display name keeps legacy broad groups compact', () {
    final account = JiveAccount()
      ..name = '微信零钱'
      ..type = 'asset'
      ..groupName = '资金账户'
      ..currency = 'CNY';

    expect(JiveDataBackupService.reportAccountDisplayName(account), '微信零钱');
  });

  test('report account display name is empty for missing account', () {
    expect(JiveDataBackupService.reportAccountDisplayName(null), '');
  });
}

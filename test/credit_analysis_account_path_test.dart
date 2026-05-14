import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/service/credit_analysis_service.dart';

void main() {
  test('credit analysis account label includes custom account group path', () {
    final account = JiveAccount()
      ..name = '信用卡'
      ..type = 'liability'
      ..subType = 'credit'
      ..groupName = '招商银行'
      ..currency = 'CNY';

    expect(
      CreditAnalysisService.accountDisplayLabel(account),
      '招商银行 / 信用卡 / credit CNY',
    );
  });

  test('credit analysis account label keeps broad legacy groups compact', () {
    final account = JiveAccount()
      ..name = '默认信用卡'
      ..type = 'liability'
      ..subType = 'credit'
      ..groupName = '信用卡账户'
      ..currency = 'CNY';

    expect(CreditAnalysisService.accountDisplayLabel(account), '默认信用卡');
  });

  test('credit analysis account label falls back for missing account', () {
    expect(CreditAnalysisService.accountDisplayLabel(null), '未知');
  });
}

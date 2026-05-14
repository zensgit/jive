import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/account_model.dart';
import 'package:jive/core/service/capital_flow_service.dart';

void main() {
  test('capital flow account label includes custom account group path', () {
    final account = JiveAccount()
      ..name = '活期'
      ..type = 'asset'
      ..groupName = '中国银行'
      ..currency = 'CNY';

    expect(capitalFlowAccountDisplayName(account), '中国银行 / 活期 / CNY');
  });

  test('capital flow account label keeps broad legacy groups compact', () {
    final account = JiveAccount()
      ..name = '微信零钱'
      ..type = 'asset'
      ..groupName = '资金账户'
      ..currency = 'CNY';

    expect(capitalFlowAccountDisplayName(account), '微信零钱');
  });

  test('capital flow account label falls back for missing account', () {
    expect(capitalFlowAccountDisplayName(null), '未知账户');
  });
}

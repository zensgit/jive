import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jive/feature/export/export_center_screen.dart';
import 'package:jive/feature/settings/privacy_policy_screen.dart';

void main() {
  testWidgets(
    'privacy policy copy is conservative about transport and deletion',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: PrivacyPolicyScreen()));

      expect(
        find.textContaining('用户自定义 WebDAV 或其他远程目标的传输安全取决于其自身协议与配置'),
        findsOneWidget,
      );
      expect(find.textContaining('账户删除和云端数据清理能力可能受当前服务配置限制'), findsOneWidget);
    },
  );

  testWidgets('export center copy downgrades cloud storage claims', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: ExportCenterScreen()));

    expect(find.textContaining('实际安全性取决于备份密码强度和目标存储环境'), findsOneWidget);
  });
}

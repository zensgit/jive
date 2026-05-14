import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/core/database/book_model.dart';
import 'package:jive/core/service/object_share_policy_service.dart';
import 'package:jive/feature/transactions/widgets/transaction_share_hint_banner.dart';

void main() {
  testWidgets('shows shared scene transaction visibility copy', (tester) async {
    final policy = const ObjectSharePolicyService().transactionPolicy(
      book: _book(isShared: true, memberCount: 2),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TransactionShareHintBanner(policy: policy)),
      ),
    );

    expect(find.text('继承场景共享'), findsOneWidget);
    expect(find.text('此交易位于共享场景，保存或修改后共享成员可见。'), findsOneWidget);
    expect(find.byIcon(Icons.groups_2_outlined), findsOneWidget);
  });

  testWidgets('hides banner for private books', (tester) async {
    final policy = const ObjectSharePolicyService().transactionPolicy(
      book: _book(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TransactionShareHintBanner(policy: policy)),
      ),
    );

    expect(find.text('继承场景共享'), findsNothing);
    expect(find.textContaining('共享成员可见'), findsNothing);
  });
}

JiveBook _book({bool isShared = false, int memberCount = 1}) {
  return JiveBook()
    ..id = 7
    ..key = isShared ? 'book_family' : 'book_private'
    ..name = isShared ? '家庭' : '日常'
    ..currency = 'CNY'
    ..order = 0
    ..isDefault = !isShared
    ..isArchived = false
    ..isShared = isShared
    ..memberCount = memberCount
    ..createdAt = DateTime(2026, 5, 12)
    ..updatedAt = DateTime(2026, 5, 12);
}

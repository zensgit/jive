import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/service/category_service.dart';

void main() {
  testWidgets('CategoryService renders quick action icon protocols', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Row(
            children: [
              CategoryService.buildIcon('movie', size: 24),
              CategoryService.buildIcon('text:咖', size: 24),
            ],
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.movie), findsOneWidget);
    expect(find.text('咖'), findsOneWidget);
  });
}

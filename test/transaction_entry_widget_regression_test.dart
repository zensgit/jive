import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jive/feature/transactions/add_transaction_screen.dart'
    show TransactionType;
import 'package:jive/feature/transactions/widgets/compact_amount_bar.dart';
import 'package:jive/feature/transactions/widgets/transaction_calculator_key.dart';

import 'test_helpers.dart';

void main() {
  setUpAll(setupGoogleFontsForTests);

  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('compact amount bar expands notes inline without taking focus', (
    tester,
  ) async {
    var toggleCount = 0;
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);

    Widget buildBar({required bool expanded}) {
      return wrap(
        CompactAmountBar(
          amountStr: '12+3',
          currency: 'CNY',
          txType: TransactionType.expense,
          selectedTime: DateTime(2026, 4, 20, 8, 30),
          noteController: controller,
          noteFocusNode: focusNode,
          isNoteExpanded: expanded,
          onToggleNoteExpanded: () => toggleCount += 1,
          onTapTime: () {},
          expressionResult: 15,
          accountName: '现金',
        ),
      );
    }

    await tester.pumpWidget(buildBar(expanded: false));

    var noteField = tester.widget<TextField>(find.byType(TextField));
    expect(noteField.minLines, 1);
    expect(noteField.maxLines, 1);
    expect(noteField.keyboardType, TextInputType.text);
    expect(noteField.textInputAction, TextInputAction.done);
    expect(find.byTooltip('展开备注'), findsOneWidget);

    await tester.tap(find.byTooltip('展开备注'));
    await tester.pump();

    expect(toggleCount, 1);
    expect(focusNode.hasFocus, isFalse);

    await tester.pumpWidget(buildBar(expanded: true));

    noteField = tester.widget<TextField>(find.byType(TextField));
    expect(noteField.minLines, 2);
    expect(noteField.maxLines, 3);
    expect(noteField.keyboardType, TextInputType.multiline);
    expect(noteField.textInputAction, TextInputAction.newline);
    expect(find.byTooltip('收起备注'), findsOneWidget);
  });

  testWidgets('operator keys expose long press switch state', (tester) async {
    final pressedKeys = <String>[];
    var toggled = 0;

    Widget buildKey({
      required String keyValue,
      String? plusLabel,
      String? minusLabel,
    }) {
      return wrap(
        SizedBox(
          width: 120,
          height: 90,
          child: TransactionCalculatorKey(
            keyValue: keyValue,
            txType: TransactionType.expense,
            onKeyPress: pressedKeys.add,
            plusLabel: plusLabel,
            minusLabel: minusLabel,
            onOperatorToggle: () => toggled += 1,
          ),
        ),
      );
    }

    await tester.pumpWidget(buildKey(keyValue: '+'));

    expect(find.text('+'), findsOneWidget);
    expect(find.text('长按×'), findsOneWidget);

    await tester.tap(find.text('+'));
    await tester.longPress(find.text('+'));

    expect(pressedKeys, ['+']);
    expect(toggled, 1);

    await tester.pumpWidget(buildKey(keyValue: '+', plusLabel: '×'));

    expect(find.text('×'), findsOneWidget);
    expect(find.text('当前×'), findsOneWidget);
    expect(find.text('长按×'), findsNothing);

    await tester.pumpWidget(buildKey(keyValue: '-', minusLabel: '÷'));

    expect(find.text('÷'), findsOneWidget);
    expect(find.text('当前÷'), findsOneWidget);
    expect(find.text('长按÷'), findsNothing);
  });
}

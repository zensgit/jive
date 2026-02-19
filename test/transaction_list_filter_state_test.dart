import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jive/core/model/transaction_list_filter_state.dart';

void main() {
  test('normalizedTag trims whitespace and empty becomes null', () {
    const empty = TransactionListFilterState(tag: '   ');
    expect(empty.normalizedTag, isNull);

    const filled = TransactionListFilterState(tag: '  早餐  ');
    expect(filled.normalizedTag, '早餐');
  });

  test('hasAnyFilter reflects all filter dimensions', () {
    const none = TransactionListFilterState();
    expect(none.hasAnyFilter, isFalse);

    const byCategory = TransactionListFilterState(categoryKey: 'food');
    expect(byCategory.hasAnyFilter, isTrue);

    const byAccount = TransactionListFilterState(accountId: 7);
    expect(byAccount.hasAnyFilter, isTrue);

    const byTag = TransactionListFilterState(tag: 'tag');
    expect(byTag.hasAnyFilter, isTrue);

    final byRange = TransactionListFilterState(
      dateRange: DateTimeRange(
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 2),
      ),
    );
    expect(byRange.hasAnyFilter, isTrue);

    const byBudget = TransactionListFilterState(
      budgetFilter: BudgetInclusionFilter.excludedOnly,
    );
    expect(byBudget.hasAnyFilter, isTrue);
  });

  test('copyWith supports clear flags', () {
    final initial = TransactionListFilterState(
      categoryKey: 'food',
      accountId: 3,
      tag: '早餐',
      dateRange: DateTimeRange(
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 2),
      ),
      budgetFilter: BudgetInclusionFilter.includedOnly,
    );

    final next = initial.copyWith(
      clearCategoryKey: true,
      clearAccountId: true,
      clearTag: true,
      clearDateRange: true,
      budgetFilter: BudgetInclusionFilter.all,
    );
    expect(next.categoryKey, isNull);
    expect(next.accountId, isNull);
    expect(next.tag, isNull);
    expect(next.dateRange, isNull);
    expect(next.budgetFilter, BudgetInclusionFilter.all);
  });

  test('toJson/fromJson keeps values and tolerates string numbers', () {
    final state = TransactionListFilterState(
      categoryKey: 'food',
      accountId: 99,
      tag: ' 早餐 ',
      dateRange: DateTimeRange(
        start: DateTime(2026, 2, 10),
        end: DateTime(2026, 2, 12),
      ),
      budgetFilter: BudgetInclusionFilter.excludedOnly,
    );

    final json = state.toJson();
    expect(json['tag'], '早餐');
    expect(json['budgetFilter'], 'excludedOnly');

    final restored = TransactionListFilterState.fromJson({
      ...json,
      'accountId': '99',
      'rangeStartMs': '${json['rangeStartMs']}',
      'rangeEndMs': '${json['rangeEndMs']}',
    });

    expect(restored.categoryKey, 'food');
    expect(restored.accountId, 99);
    expect(restored.tag, '早餐');
    expect(restored.dateRange, isNotNull);
    expect(restored.dateRange!.start, DateTime(2026, 2, 10));
    expect(restored.dateRange!.end, DateTime(2026, 2, 12));
    expect(restored.budgetFilter, BudgetInclusionFilter.excludedOnly);
  });

  test('fromJson falls back to default budget filter on invalid value', () {
    final state = TransactionListFilterState.fromJson({
      'budgetFilter': 'invalid_mode',
    });
    expect(state.budgetFilter, BudgetInclusionFilter.all);
  });
}

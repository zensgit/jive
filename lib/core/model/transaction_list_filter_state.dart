import 'package:flutter/material.dart';

enum BudgetInclusionFilter { all, excludedOnly, includedOnly }

class TransactionListFilterState {
  final String? categoryKey;
  final int? accountId;
  final String? tag;
  final DateTimeRange? dateRange;
  final BudgetInclusionFilter budgetFilter;

  const TransactionListFilterState({
    this.categoryKey,
    this.accountId,
    this.tag,
    this.dateRange,
    this.budgetFilter = BudgetInclusionFilter.all,
  });

  String? get normalizedTag {
    final value = tag?.trim() ?? '';
    return value.isEmpty ? null : value;
  }

  bool get hasAnyFilter =>
      categoryKey != null ||
      accountId != null ||
      normalizedTag != null ||
      dateRange != null ||
      budgetFilter != BudgetInclusionFilter.all;

  TransactionListFilterState copyWith({
    String? categoryKey,
    bool clearCategoryKey = false,
    int? accountId,
    bool clearAccountId = false,
    String? tag,
    bool clearTag = false,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    BudgetInclusionFilter? budgetFilter,
  }) {
    return TransactionListFilterState(
      categoryKey: clearCategoryKey ? null : (categoryKey ?? this.categoryKey),
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      tag: clearTag ? null : (tag ?? this.tag),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      budgetFilter: budgetFilter ?? this.budgetFilter,
    );
  }

  TransactionListFilterState cleared() {
    return const TransactionListFilterState();
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryKey': categoryKey,
      'accountId': accountId,
      'tag': normalizedTag,
      'rangeStartMs': dateRange?.start.millisecondsSinceEpoch,
      'rangeEndMs': dateRange?.end.millisecondsSinceEpoch,
      'budgetFilter': budgetFilter.name,
    };
  }

  static TransactionListFilterState fromJson(Map<String, dynamic> json) {
    final budgetRaw = '${json['budgetFilter'] ?? ''}';
    var budget = BudgetInclusionFilter.all;
    for (final value in BudgetInclusionFilter.values) {
      if (value.name == budgetRaw) {
        budget = value;
        break;
      }
    }

    DateTimeRange? range;
    final startMs = _tryParseInt(json['rangeStartMs']);
    final endMs = _tryParseInt(json['rangeEndMs']);
    if (startMs != null && endMs != null) {
      range = DateTimeRange(
        start: DateTime.fromMillisecondsSinceEpoch(startMs),
        end: DateTime.fromMillisecondsSinceEpoch(endMs),
      );
    }

    final accountId = _tryParseInt(json['accountId']);
    final category = '${json['categoryKey'] ?? ''}'.trim();
    final tag = '${json['tag'] ?? ''}'.trim();
    return TransactionListFilterState(
      categoryKey: category.isEmpty ? null : category,
      accountId: accountId,
      tag: tag.isEmpty ? null : tag,
      dateRange: range,
      budgetFilter: budget,
    );
  }

  static int? _tryParseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse('$value');
  }
}

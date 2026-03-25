import 'package:jive/core/database/transaction_model.dart';

import 'transaction_list_filter_state.dart';

enum TransactionSortField { date, amount, category, account, tag }

enum TransactionSortDirection { asc, desc }

class TransactionQuerySpec {
  final String? keyword;
  final TransactionListFilterState filterState;
  final String? fixedCategoryKey;
  final String? fixedSubCategoryKey;
  final bool includeSubCategories;
  final TransactionSortField sortField;
  final TransactionSortDirection sortDirection;
  final bool groupByDate;
  final int? bookId; // 多账本过滤

  const TransactionQuerySpec({
    this.keyword,
    this.filterState = const TransactionListFilterState(),
    this.fixedCategoryKey,
    this.fixedSubCategoryKey,
    this.includeSubCategories = true,
    this.sortField = TransactionSortField.date,
    this.sortDirection = TransactionSortDirection.desc,
    this.groupByDate = true,
    this.bookId,
  });

  String? get normalizedKeyword {
    final value = keyword?.trim() ?? '';
    return value.isEmpty ? null : value;
  }
}

class TransactionQueryCursor {
  final DateTime timestamp;
  final int id;

  const TransactionQueryCursor({required this.timestamp, required this.id});

  factory TransactionQueryCursor.fromTransaction(JiveTransaction tx) {
    return TransactionQueryCursor(timestamp: tx.timestamp, id: tx.id);
  }
}

class TransactionQueryResultPage {
  final List<JiveTransaction> items;
  final TransactionQueryCursor? nextCursor;
  final bool hasMore;

  const TransactionQueryResultPage({
    required this.items,
    required this.nextCursor,
    required this.hasMore,
  });
}

class TransactionQueryDateMeta {
  final DateTime? minDate;
  final DateTime? maxDate;
  final Set<int> years;

  const TransactionQueryDateMeta({
    required this.minDate,
    required this.maxDate,
    required this.years,
  });
}

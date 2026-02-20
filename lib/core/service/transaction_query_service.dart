import 'dart:math';

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../database/account_model.dart';
import '../database/category_model.dart';
import '../database/tag_model.dart';
import '../database/transaction_model.dart';
import '../model/transaction_list_filter_state.dart';
import '../model/transaction_query_spec.dart';

class TransactionQueryService {
  final Isar _isar;

  const TransactionQueryService(this._isar);

  Future<TransactionQueryResultPage> query(
    TransactionQuerySpec spec, {
    TransactionQueryCursor? cursor,
    int pageSize = 100,
    required Map<String, JiveCategory> categoryByKey,
    required Map<int, JiveAccount> accountById,
    required Map<String, JiveTag> tagByKey,
  }) async {
    final items = <JiveTransaction>[];
    final fetchSize = max(pageSize * 2, 160);
    var currentCursor = cursor;
    var loops = 0;

    while (items.length < pageSize && loops < 80) {
      loops += 1;
      final batch = await _fetchChunk(cursor: currentCursor, limit: fetchSize);
      if (batch.isEmpty) {
        return TransactionQueryResultPage(
          items: items,
          nextCursor: null,
          hasMore: false,
        );
      }
      currentCursor = TransactionQueryCursor.fromTransaction(batch.last);

      for (final tx in batch) {
        if (!_matchesFilters(
          tx,
          spec: spec,
          categoryByKey: categoryByKey,
          accountById: accountById,
          tagByKey: tagByKey,
        )) {
          continue;
        }
        items.add(tx);
        if (items.length >= pageSize) break;
      }

      if (items.length >= pageSize) {
        final next = TransactionQueryCursor.fromTransaction(items.last);
        return TransactionQueryResultPage(
          items: items,
          nextCursor: next,
          hasMore: true,
        );
      }
    }

    return TransactionQueryResultPage(
      items: items,
      nextCursor: null,
      hasMore: false,
    );
  }

  Future<TransactionQueryDateMeta> loadDateMeta(
    TransactionQuerySpec spec,
  ) async {
    final txs = await _isar.jiveTransactions.where().findAll();
    DateTime? minDate;
    DateTime? maxDate;
    for (final tx in txs) {
      if (!_matchesBaseScope(tx, spec)) continue;
      final ts = tx.timestamp;
      minDate = minDate == null || ts.isBefore(minDate) ? ts : minDate;
      maxDate = maxDate == null || ts.isAfter(maxDate) ? ts : maxDate;
    }

    if (maxDate == null) {
      return const TransactionQueryDateMeta(
        minDate: null,
        maxDate: null,
        years: <int>{},
      );
    }

    final minDay = DateTime(minDate!.year, minDate.month, minDate.day);
    final maxDay = DateTime(maxDate.year, maxDate.month, maxDate.day);
    final years = <int>{};
    for (var year = minDay.year; year <= maxDay.year; year++) {
      years.add(year);
    }
    return TransactionQueryDateMeta(
      minDate: minDay,
      maxDate: maxDay,
      years: years,
    );
  }

  Future<List<JiveTransaction>> _fetchChunk({
    required TransactionQueryCursor? cursor,
    required int limit,
  }) async {
    List<JiveTransaction> batch;
    if (cursor == null) {
      batch = await _isar.jiveTransactions
          .where()
          .sortByTimestampDesc()
          .limit(limit)
          .findAll();
    } else {
      batch = await _isar.jiveTransactions
          .where()
          .timestampLessThan(cursor.timestamp, include: true)
          .sortByTimestampDesc()
          .limit(limit)
          .findAll();
      batch = batch.where((tx) => _isAfterCursor(tx, cursor)).toList();
    }

    batch.sort((a, b) {
      final byTime = b.timestamp.compareTo(a.timestamp);
      if (byTime != 0) return byTime;
      return b.id.compareTo(a.id);
    });
    return batch;
  }

  bool _isAfterCursor(JiveTransaction tx, TransactionQueryCursor cursor) {
    if (tx.timestamp.isBefore(cursor.timestamp)) return true;
    if (tx.timestamp.isAfter(cursor.timestamp)) return false;
    return tx.id < cursor.id;
  }

  bool _matchesFilters(
    JiveTransaction tx, {
    required TransactionQuerySpec spec,
    required Map<String, JiveCategory> categoryByKey,
    required Map<int, JiveAccount> accountById,
    required Map<String, JiveTag> tagByKey,
  }) {
    if (!_matchesBaseScope(tx, spec)) return false;

    if (!_matchesDateRange(tx, spec.filterState.dateRange)) return false;

    final accountId = spec.filterState.accountId;
    if (accountId != null &&
        tx.accountId != accountId &&
        tx.toAccountId != accountId) {
      return false;
    }

    if (!_matchesBudgetFilter(
      tx,
      spec.filterState.budgetFilter,
      categoryByKey,
    )) {
      return false;
    }

    final tagKeyword = spec.filterState.normalizedTag?.toLowerCase();
    if (tagKeyword != null && !_noteHasTag(tx.note, tagKeyword)) {
      return false;
    }

    final keyword = spec.normalizedKeyword?.toLowerCase();
    if (keyword == null) return true;
    return _matchesKeyword(
      tx,
      keyword: keyword,
      accountById: accountById,
      categoryByKey: categoryByKey,
      tagByKey: tagByKey,
    );
  }

  bool _matchesBaseScope(JiveTransaction tx, TransactionQuerySpec spec) {
    if (spec.fixedSubCategoryKey != null &&
        spec.fixedSubCategoryKey!.isNotEmpty) {
      if (tx.subCategoryKey != spec.fixedSubCategoryKey) return false;
    } else if (spec.fixedCategoryKey != null &&
        spec.fixedCategoryKey!.isNotEmpty) {
      if (tx.categoryKey != spec.fixedCategoryKey) return false;
      if (!spec.includeSubCategories) {
        final sub = tx.subCategoryKey?.trim() ?? '';
        if (sub.isNotEmpty) return false;
      }
    }

    final filterCategory = spec.filterState.categoryKey;
    if (filterCategory != null) {
      final matches =
          tx.categoryKey == filterCategory ||
          tx.subCategoryKey == filterCategory;
      if (!matches) return false;
    }
    return true;
  }

  bool _matchesDateRange(JiveTransaction tx, DateTimeRange? range) {
    if (range == null) return true;
    final start = DateTime(
      range.start.year,
      range.start.month,
      range.start.day,
    );
    final end = DateTime(
      range.end.year,
      range.end.month,
      range.end.day,
      23,
      59,
      59,
      999,
    );
    return !tx.timestamp.isBefore(start) && !tx.timestamp.isAfter(end);
  }

  bool _matchesBudgetFilter(
    JiveTransaction tx,
    BudgetInclusionFilter mode,
    Map<String, JiveCategory> categoryByKey,
  ) {
    if (mode == BudgetInclusionFilter.all) return true;
    if ((tx.type ?? 'expense') != 'expense') return false;

    final categoryExcluded =
        tx.categoryKey != null &&
        (categoryByKey[tx.categoryKey!]?.excludeFromBudget == true);
    final subCategoryExcluded =
        tx.subCategoryKey != null &&
        (categoryByKey[tx.subCategoryKey!]?.excludeFromBudget == true);
    final excluded =
        tx.excludeFromBudget || categoryExcluded || subCategoryExcluded;

    if (mode == BudgetInclusionFilter.excludedOnly) return excluded;
    return !excluded;
  }

  bool _matchesKeyword(
    JiveTransaction tx, {
    required String keyword,
    required Map<int, JiveAccount> accountById,
    required Map<String, JiveCategory> categoryByKey,
    required Map<String, JiveTag> tagByKey,
  }) {
    final searchText = _entrySearchText(
      tx,
      accountById: accountById,
      categoryByKey: categoryByKey,
      tagByKey: tagByKey,
    );
    if (searchText.contains(keyword)) return true;

    final amountQuery = double.tryParse(keyword);
    if (amountQuery != null) {
      final amountText = tx.amount.toStringAsFixed(2);
      if (amountText.contains(keyword)) return true;
    }
    return false;
  }

  String _entrySearchText(
    JiveTransaction tx, {
    required Map<int, JiveAccount> accountById,
    required Map<String, JiveCategory> categoryByKey,
    required Map<String, JiveTag> tagByKey,
  }) {
    final accountName = accountById[tx.accountId]?.name ?? '';
    final toAccountName = accountById[tx.toAccountId]?.name ?? '';
    final categoryName =
        tx.subCategory ??
        tx.category ??
        (tx.subCategoryKey != null
            ? categoryByKey[tx.subCategoryKey!]?.name
            : categoryByKey[tx.categoryKey ?? '']?.name) ??
        '';
    final tags = tx.tagKeys
        .map((key) => tagByKey[key]?.name ?? '')
        .where((value) => value.isNotEmpty)
        .join(' ');
    return [
      tx.source,
      tx.category ?? '',
      tx.subCategory ?? '',
      categoryName,
      tx.note ?? '',
      tx.rawText ?? '',
      accountName,
      toAccountName,
      tags,
    ].join(' ').toLowerCase();
  }

  bool _noteHasTag(String? note, String tagQuery) {
    final value = note?.toLowerCase() ?? '';
    if (value.isEmpty) return false;
    return value.contains(tagQuery);
  }
}

import 'package:flutter/material.dart';
import 'package:isar/isar.dart';

import '../database/smart_list_model.dart';
import '../model/transaction_list_filter_state.dart';

/// SmartList 服务 — 管理保存的筛选视图。
class SmartListService {
  final Isar _isar;

  SmartListService(this._isar);

  /// 创建新视图
  Future<JiveSmartList> create({
    required String name,
    String? iconName,
    String? colorHex,
    String? categoryKeys,
    String? tagKeys,
    int? accountId,
    int? bookId,
    String? transactionType,
    double? minAmount,
    double? maxAmount,
    String? dateRangeType,
    DateTime? customStartDate,
    DateTime? customEndDate,
    String? keyword,
  }) async {
    final count = await _isar.jiveSmartLists.count();
    final smartList = JiveSmartList()
      ..name = name
      ..iconName = iconName
      ..colorHex = colorHex
      ..categoryKeys = categoryKeys
      ..tagKeys = tagKeys
      ..accountId = accountId
      ..bookId = bookId
      ..transactionType = transactionType
      ..minAmount = minAmount
      ..maxAmount = maxAmount
      ..dateRangeType = dateRangeType
      ..customStartDate = customStartDate
      ..customEndDate = customEndDate
      ..keyword = keyword
      ..sortOrder = count
      ..isPinned = false
      ..createdAt = DateTime.now();

    await _isar.writeTxn(() async {
      await _isar.jiveSmartLists.put(smartList);
    });
    return smartList;
  }

  /// 更新视图
  Future<void> update(JiveSmartList smartList) async {
    await _isar.writeTxn(() async {
      await _isar.jiveSmartLists.put(smartList);
    });
  }

  /// 删除视图
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.jiveSmartLists.delete(id);
    });
  }

  /// 获取全部视图，置顶优先，再按 sortOrder 排序。
  Future<List<JiveSmartList>> getAll() async {
    final list = await _isar.jiveSmartLists.where().findAll();
    list.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return list;
  }

  /// 获取所有置顶视图。
  Future<List<JiveSmartList>> getPinned() async {
    final list = await _isar.jiveSmartLists.where().findAll();
    return list.where((e) => e.isPinned).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// 根据 JiveSmartList 构建 TransactionListFilterState。
  TransactionListFilterState buildFilterState(JiveSmartList smartList) {
    DateTimeRange? dateRange;
    final now = DateTime.now();

    switch (smartList.dateRangeType) {
      case 'last7d':
        dateRange = DateTimeRange(
          start: now.subtract(const Duration(days: 7)),
          end: now,
        );
      case 'last30d':
        dateRange = DateTimeRange(
          start: now.subtract(const Duration(days: 30)),
          end: now,
        );
      case 'thisMonth':
        dateRange = DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0, 23, 59, 59),
        );
      case 'custom':
        if (smartList.customStartDate != null &&
            smartList.customEndDate != null) {
          dateRange = DateTimeRange(
            start: smartList.customStartDate!,
            end: smartList.customEndDate!,
          );
        }
      default:
        break;
    }

    // 取第一个 categoryKey 作为主分类筛选
    final firstCategory = _firstValue(smartList.categoryKeys);
    final firstTag = _firstValue(smartList.tagKeys);

    return TransactionListFilterState(
      categoryKey: firstCategory,
      accountId: smartList.accountId,
      tag: firstTag,
      dateRange: dateRange,
    );
  }

  /// 从 TransactionListFilterState 反向构建 SmartList 字段值。
  JiveSmartList fromFilterState({
    required String name,
    required TransactionListFilterState filterState,
    String? keyword,
    int? bookId,
    String? transactionType,
    double? minAmount,
    double? maxAmount,
  }) {
    String? dateRangeType;
    DateTime? customStart;
    DateTime? customEnd;

    if (filterState.dateRange != null) {
      dateRangeType = 'custom';
      customStart = filterState.dateRange!.start;
      customEnd = filterState.dateRange!.end;
    }

    return JiveSmartList()
      ..name = name
      ..categoryKeys = filterState.categoryKey
      ..tagKeys = filterState.normalizedTag
      ..accountId = filterState.accountId
      ..bookId = bookId
      ..transactionType = transactionType
      ..minAmount = minAmount
      ..maxAmount = maxAmount
      ..dateRangeType = dateRangeType
      ..customStartDate = customStart
      ..customEndDate = customEnd
      ..keyword = keyword
      ..createdAt = DateTime.now();
  }

  /// 生成筛选条件的人类可读摘要。
  String describeSummary(JiveSmartList sl) {
    final parts = <String>[];
    if (sl.categoryKeys != null && sl.categoryKeys!.isNotEmpty) {
      parts.add('分类: ${sl.categoryKeys}');
    }
    if (sl.tagKeys != null && sl.tagKeys!.isNotEmpty) {
      parts.add('标签: ${sl.tagKeys}');
    }
    if (sl.transactionType != null) {
      parts.add(_typeLabel(sl.transactionType!));
    }
    if (sl.minAmount != null || sl.maxAmount != null) {
      final low = sl.minAmount?.toStringAsFixed(0) ?? '';
      final high = sl.maxAmount?.toStringAsFixed(0) ?? '';
      parts.add('$low-$high');
    }
    if (sl.dateRangeType != null) {
      parts.add(_dateLabel(sl.dateRangeType!));
    }
    if (sl.keyword != null && sl.keyword!.isNotEmpty) {
      parts.add('"${sl.keyword}"');
    }
    return parts.isEmpty ? '全部' : parts.join(' | ');
  }

  // ── helpers ──

  static String? _firstValue(String? csv) {
    if (csv == null || csv.isEmpty) return null;
    final parts = csv.split(',');
    final first = parts.first.trim();
    return first.isEmpty ? null : first;
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'expense':
        return '支出';
      case 'income':
        return '收入';
      case 'transfer':
        return '转账';
      default:
        return type;
    }
  }

  static String _dateLabel(String type) {
    switch (type) {
      case 'last7d':
        return '近7天';
      case 'last30d':
        return '近30天';
      case 'thisMonth':
        return '本月';
      case 'custom':
        return '自定义日期';
      default:
        return type;
    }
  }
}

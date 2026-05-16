import '../database/quick_action_model.dart';

/// Pure filtering helpers for the quick action management surface.
///
/// The store owns persistence and ordering. This service only narrows an
/// already ordered list, so search never mutates the user's One Touch order.
class QuickActionFilterService {
  const QuickActionFilterService._();

  static List<JiveQuickAction> filterRecords(
    Iterable<JiveQuickAction> records,
    String query,
  ) {
    final tokens = _tokens(query);
    final list = records.toList(growable: false);
    if (tokens.isEmpty) return list;

    return list
        .where((record) => _matches(record, tokens))
        .toList(growable: false);
  }

  static bool _matches(JiveQuickAction record, List<String> tokens) {
    final haystack = _searchableText(record);
    return tokens.every(haystack.contains);
  }

  static String _searchableText(JiveQuickAction record) {
    final values = <String>[
      record.stableId,
      record.source,
      if (record.source == 'template') '模板 template',
      record.name,
      record.transactionType,
      _typeLabel(record.transactionType),
      record.mode,
      _modeLabel(record.mode),
      if (record.iconName != null) record.iconName!,
      if (record.categoryKey != null) record.categoryKey!,
      if (record.subCategoryKey != null) record.subCategoryKey!,
      if (record.categoryName != null) record.categoryName!,
      if (record.subCategoryName != null) record.subCategoryName!,
      ...record.tagKeys,
      ..._amountTokens(record.defaultAmount),
      if (record.defaultNote != null) record.defaultNote!,
      record.showOnHome ? '首页显示 显示 home visible' : '已隐藏 隐藏 hidden',
      if (record.isPinned) '置顶 pinned',
    ];
    return values.join(' ').toLowerCase();
  }

  static List<String> _tokens(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  static Iterable<String> _amountTokens(double? amount) sync* {
    if (amount == null) return;
    yield amount.toString();
    yield amount.toStringAsFixed(2);
    yield '¥${amount.toStringAsFixed(2)}';
    if (amount == amount.roundToDouble()) {
      yield amount.toInt().toString();
      yield '¥${amount.toInt()}';
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'income':
        return '收入 income';
      case 'transfer':
        return '转账 transfer';
      case 'expense':
        return '支出 expense';
      default:
        return type;
    }
  }

  static String _modeLabel(String mode) {
    switch (mode) {
      case 'direct':
        return '直接保存 一键入账 onetouch direct';
      case 'confirm':
        return '轻确认 确认 confirm';
      case 'edit':
        return '进编辑器 编辑器 完整编辑 edit';
      default:
        return mode;
    }
  }
}
